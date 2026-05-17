/**
 * RoadGuard — WebRTC signaling + optional server media relay for multi-tab viewers.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const WebSocket = require('ws');

const { RELAY_ID, createMediaRelay } = require('./media-relay');

let wrtc = null;
let mediaRelay = null;
let useRelay = false;

try {
  wrtc = require('@roamhq/wrtc');
  useRelay = process.env.DISABLE_RELAY !== '1';
  if (useRelay) {
    mediaRelay = createMediaRelay(wrtc, getIceServers);
    console.log('Media relay enabled (multi-tab / multi-viewer)');
  }
} catch (e) {
  console.warn('Media relay unavailable (@roamhq/wrtc):', e.message);
  console.warn('Falling back to direct phone ↔ viewer connections');
}

const PORT = process.env.PORT || 8080;
const PUBLIC_WS_URL = process.env.PUBLIC_WS_URL || '';
const MAX_VIEWERS = parseInt(process.env.MAX_VIEWERS || '5', 10);

function resolveWebDir() {
  const candidates = [
    path.join(__dirname, 'web_admin'),
    path.join(__dirname, '..', 'web_admin'),
  ];
  for (const dir of candidates) {
    if (fs.existsSync(path.join(dir, 'index.html'))) return dir;
  }
  return candidates[0];
}

const WEB_DIR = resolveWebDir();
const rooms = new Map();

function getIceServers() {
  const extra = process.env.TURN_URL
    ? [
        {
          urls: process.env.TURN_URL,
          username: process.env.TURN_USER || '',
          credential: process.env.TURN_CRED || '',
        },
      ]
    : [
        { urls: 'stun:stun.relay.metered.ca:443' },
        {
          urls: 'turn:global.relay.metered.ca:80',
          username: 'openrelayproject',
          credential: 'openrelayproject',
        },
        {
          urls: 'turn:global.relay.metered.ca:443',
          username: 'openrelayproject',
          credential: 'openrelayproject',
        },
        {
          urls: 'turn:global.relay.metered.ca:443?transport=tcp',
          username: 'openrelayproject',
          credential: 'openrelayproject',
        },
      ];

  return [{ urls: 'stun:stun.l.google.com:19302' }, ...extra];
}

function getRoom(id) {
  if (!rooms.has(id)) {
    rooms.set(id, { publisher: null, viewers: new Map() });
  }
  return rooms.get(id);
}

function send(ws, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function viewerCount(room) {
  return room.viewers.size;
}

function notifyPublisherCount(room) {
  if (room.publisher) {
    send(room.publisher, { type: 'viewer-count', count: viewerCount(room) });
  }
}

function resolveSignalingUrl(req) {
  if (PUBLIC_WS_URL) return PUBLIC_WS_URL;
  const host = req.headers['x-forwarded-host'] || req.headers.host || `localhost:${PORT}`;
  const proto = req.headers['x-forwarded-proto'] === 'https' ? 'wss' : 'ws';
  return `${proto}://${host}`;
}

function sendJson(res, status, data) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(JSON.stringify(data, null, 2));
}

function handleStreamConfigApi(req, res) {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const roomId = url.searchParams.get('room') || 'dashcam-1';
  const signalingUrl = resolveSignalingUrl(req);
  const httpProto = signalingUrl.startsWith('wss') ? 'https' : 'http';
  const wsHost = signalingUrl.replace(/^wss?:\/\//, '');
  const configUrl = `${httpProto}://${wsHost}/api/stream-config?room=${encodeURIComponent(roomId)}`;

  sendJson(res, 200, {
    protocol: 'webrtc',
    signalingUrl,
    roomId,
    configUrl,
    iceServers: getIceServers(),
    maxViewers: MAX_VIEWERS,
    relayMode: useRelay,
    viewerJoin: { type: 'join', room: roomId, role: 'viewer' },
    publisherJoin: { type: 'join', room: roomId, role: 'publisher' },
    instructions:
      'Browser: WebSocket to signalingUrl, send viewerJoin, handle offer/answer/ice. ' +
      'See web_admin/index.html. Video is WebRTC (not an MP4 URL).',
  });
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }

  if (req.url.startsWith('/api/stream-config')) {
    return handleStreamConfigApi(req, res);
  }

  let filePath = path.join(WEB_DIR, req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  if (!filePath.startsWith(WEB_DIR)) {
    res.writeHead(403);
    return res.end();
  }
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(WEB_DIR, 'index.html');
  }
  const ext = path.extname(filePath);
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css' };
  res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
  fs.createReadStream(filePath).pipe(res);
});

const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
  ws.roomId = null;
  ws.role = null;
  ws.viewerId = null;

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      return send(ws, { type: 'error', message: 'Invalid JSON' });
    }

    if (msg.type === 'join') {
      ws.roomId = msg.room || 'dashcam-1';
      ws.role = msg.role;
      const room = getRoom(ws.roomId);

      if (ws.role === 'publisher') {
        room.publisher = ws;
        send(ws, {
          type: 'joined',
          role: 'publisher',
          room: ws.roomId,
          relayMode: useRelay,
        });
        notifyPublisherCount(room);
        if (!useRelay) {
          room.viewers.forEach((_, viewerId) => {
            send(ws, { type: 'viewer-joined', viewerId });
          });
        }
      } else if (ws.role === 'viewer') {
        if (viewerCount(room) >= MAX_VIEWERS) {
          send(ws, {
            type: 'error',
            message: `Room is full (max ${MAX_VIEWERS} viewers). Try again later.`,
          });
          return;
        }
        const viewerId = crypto.randomUUID();
        ws.viewerId = viewerId;
        room.viewers.set(viewerId, ws);
        send(ws, {
          type: 'joined',
          role: 'viewer',
          room: ws.roomId,
          viewerId,
          relayMode: useRelay,
        });

        if (useRelay && mediaRelay) {
          mediaRelay.onViewerJoined(room, viewerId, ws, send);
          if (room.publisher && mediaRelay.needsPublisherRelay(room)) {
            send(room.publisher, { type: 'viewer-joined', viewerId: RELAY_ID });
          }
        } else if (room.publisher) {
          send(room.publisher, { type: 'viewer-joined', viewerId });
        } else {
          send(ws, {
            type: 'info',
            message: 'Connected. Waiting for dashcam to start streaming…',
          });
        }
        notifyPublisherCount(room);
      }
      return;
    }

    if (!ws.roomId) return;
    const room = getRoom(ws.roomId);

    if (msg.type === 'offer') {
      const viewerId = msg.viewerId;

      if (useRelay && mediaRelay && viewerId === RELAY_ID && ws.role === 'publisher') {
        mediaRelay.handlePublisherOffer(room, msg, ws, send).catch((e) => {
          console.error('Relay publisher offer failed:', e);
        });
        return;
      }

      if (!viewerId) {
        room.viewers.forEach((viewerWs) => send(viewerWs, msg));
        return;
      }
      const viewer = room.viewers.get(viewerId);
      if (viewer) send(viewer, msg);
    } else if (msg.type === 'answer') {
      if (useRelay && mediaRelay && ws.role === 'viewer') {
        mediaRelay.handleViewerAnswer(room, msg, ws).catch((e) => {
          console.error('Relay viewer answer failed:', e);
        });
        return;
      }
      if (room.publisher) {
        send(room.publisher, { ...msg, viewerId: msg.viewerId || ws.viewerId });
      }
    } else if (msg.type === 'ice') {
      if (useRelay && mediaRelay) {
        if (ws.role === 'publisher' && msg.viewerId === RELAY_ID) {
          mediaRelay.handlePublisherIce(room, msg).catch(() => {});
          return;
        }
        if (ws.role === 'viewer') {
          mediaRelay.handleViewerIce(room, msg, ws).catch(() => {});
          return;
        }
      }

      if (ws.role === 'publisher') {
        const viewerId = msg.viewerId;
        if (!viewerId) {
          room.viewers.forEach((viewerWs) => send(viewerWs, msg));
          return;
        }
        const viewer = room.viewers.get(viewerId);
        if (viewer) send(viewer, msg);
      } else if (ws.role === 'viewer' && room.publisher) {
        send(room.publisher, { ...msg, viewerId: ws.viewerId });
      }
    }
  });

  ws.on('close', () => {
    if (!ws.roomId) return;
    const room = getRoom(ws.roomId);
    if (ws.role === 'publisher' && room.publisher === ws) {
      room.publisher = null;
      if (useRelay && mediaRelay) mediaRelay.onPublisherLeft(room);
    }
    if (ws.role === 'viewer' && ws.viewerId) {
      room.viewers.delete(ws.viewerId);
      if (useRelay && mediaRelay) mediaRelay.onViewerLeft(room, ws.viewerId);
      if (room.publisher) {
        if (!useRelay) {
          send(room.publisher, { type: 'viewer-left', viewerId: ws.viewerId });
        }
        notifyPublisherCount(room);
      }
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`RoadGuard server http://0.0.0.0:${PORT}`);
  console.log(`REST API:  http://0.0.0.0:${PORT}/api/stream-config?room=dashcam-1`);
  console.log(`WebSocket: ${PUBLIC_WS_URL || `ws://<public-ip>:${PORT}`}`);
  console.log(`Max viewers per room: ${MAX_VIEWERS}`);
  console.log(`Relay mode: ${useRelay ? 'ON' : 'OFF'}`);
});
