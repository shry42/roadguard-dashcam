/**
 * RoadGuard — WebRTC signaling + REST config for website integration.
 * Run: npm install && npm start
 *
 * Internet / different locations:
 *   1. Deploy this server on a VPS or expose with Cloudflare Tunnel (free).
 *   2. Set PUBLIC_WS_URL=wss://your-domain.com (or ws://your-ip:8080)
 *   3. Phone app Settings → same WebSocket URL + room ID
 *   4. Website: GET /api/stream-config?room=dashcam-1
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const WebSocket = require('ws');

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

/** Free TURN relay for NAT traversal (Metered Open Relay). */
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
        send(ws, { type: 'joined', role: 'publisher', room: ws.roomId });
        notifyPublisherCount(room);
        // If viewers are already waiting, tell publisher about each one.
        room.viewers.forEach((viewerWs, viewerId) => {
          send(ws, { type: 'viewer-joined', viewerId });
        });
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
        send(ws, { type: 'joined', role: 'viewer', room: ws.roomId, viewerId });
        if (room.publisher) {
          send(room.publisher, { type: 'viewer-joined', viewerId });
          notifyPublisherCount(room);
        }
      }
      return;
    }

    if (!ws.roomId) return;
    const room = getRoom(ws.roomId);

    if (msg.type === 'offer') {
      const viewerId = msg.viewerId;
      if (!viewerId) {
        // Legacy publisher: one offer → all viewers in the room.
        room.viewers.forEach((viewerWs) => send(viewerWs, msg));
        return;
      }
      const viewer = room.viewers.get(viewerId);
      if (viewer) send(viewer, msg);
    } else if (msg.type === 'answer') {
      if (room.publisher) {
        const payload = { ...msg, viewerId: msg.viewerId || ws.viewerId };
        send(room.publisher, payload);
      }
    } else if (msg.type === 'ice') {
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
    }
    if (ws.role === 'viewer' && ws.viewerId) {
      room.viewers.delete(ws.viewerId);
      if (room.publisher) {
        send(room.publisher, { type: 'viewer-left', viewerId: ws.viewerId });
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
  if (!PUBLIC_WS_URL) {
    console.log('Tip: set PUBLIC_WS_URL=wss://your-domain.com when using HTTPS tunnel');
  }
});
