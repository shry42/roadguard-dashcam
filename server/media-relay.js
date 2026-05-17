/**
 * Server-side WebRTC relay: phone encodes once → many browser viewers.
 * Requires @roamhq/wrtc (native). Falls back to direct phone↔viewer if unavailable.
 */
const RELAY_ID = '__relay__';

function createMediaRelay(wrtc, getIceServers) {
  function ensureRelay(room) {
    if (!room.mediaRelay) {
      room.mediaRelay = {
        inboundPc: null,
        mediaStream: null,
        viewerSessions: new Map(),
        pendingViewerIds: [],
      };
    }
    return room.mediaRelay;
  }

  function sendIce(ws, viewerId, candidate) {
    if (!candidate) return;
    const payload = {
      type: 'ice',
      candidate: candidate.candidate,
      sdpMid: candidate.sdpMid,
      sdpMLineIndex: candidate.sdpMLineIndex,
    };
    if (viewerId) payload.viewerId = viewerId;
    if (ws && ws.readyState === 1) ws.send(JSON.stringify(payload));
  }

  async function connectWaitingViewers(room, sendFn) {
    const relay = room.mediaRelay;
    if (!relay?.mediaStream) return;
    const ids = relay.pendingViewerIds.splice(0);
    for (const viewerId of ids) {
      const viewerWs = room.viewers.get(viewerId);
      if (viewerWs) {
        await startViewerSession(room, viewerId, viewerWs, sendFn);
      }
    }
  }

  async function startViewerSession(room, viewerId, viewerWs, sendFn) {
    const relay = ensureRelay(room);
    if (!relay.mediaStream) {
      if (!relay.pendingViewerIds.includes(viewerId)) {
        relay.pendingViewerIds.push(viewerId);
      }
      return;
    }
    if (relay.viewerSessions.has(viewerId)) return;

    const pc = new wrtc.RTCPeerConnection({ iceServers: getIceServers() });
    relay.viewerSessions.set(viewerId, { pc, pendingIce: [] });

    for (const track of relay.mediaStream.getTracks()) {
      pc.addTrack(track, relay.mediaStream);
    }

    pc.onicecandidate = (e) => {
      sendIce(viewerWs, viewerId, e.candidate);
    };

    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    sendFn(viewerWs, {
      type: 'offer',
      viewerId,
      sdp: offer.sdp,
      sdpType: offer.type,
    });
    console.log(`Relay: offer → viewer ${viewerId.slice(0, 8)}`);
  }

  return {
    RELAY_ID,

    ensureRelay,

    async handlePublisherOffer(room, msg, publisherWs, sendFn) {
      const relay = ensureRelay(room);
      if (relay.inboundPc) {
        try {
          relay.inboundPc.close();
        } catch (_) {}
      }

      const pc = new wrtc.RTCPeerConnection({ iceServers: getIceServers() });
      relay.inboundPc = pc;

      pc.ontrack = (event) => {
        const stream =
          event.streams && event.streams[0]
            ? event.streams[0]
            : new wrtc.MediaStream([event.track]);
        relay.mediaStream = stream;
        console.log(
          `Relay: inbound tracks video=${stream.getVideoTracks().length} audio=${stream.getAudioTracks().length}`,
        );
        connectWaitingViewers(room, sendFn);
      };

      pc.onicecandidate = (e) => {
        sendIce(publisherWs, RELAY_ID, e.candidate);
      };

      await pc.setRemoteDescription(
        new wrtc.RTCSessionDescription({
          type: msg.sdpType || 'offer',
          sdp: msg.sdp,
        }),
      );
      const answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      sendFn(publisherWs, {
        type: 'answer',
        viewerId: RELAY_ID,
        sdp: answer.sdp,
        sdpType: answer.type,
      });
    },

    async handlePublisherIce(room, msg) {
      const pc = room.mediaRelay?.inboundPc;
      if (!pc || !msg.candidate) return;
      try {
        await pc.addIceCandidate(
          new wrtc.RTCIceCandidate({
            candidate: msg.candidate,
            sdpMid: msg.sdpMid,
            sdpMLineIndex: msg.sdpMLineIndex,
          }),
        );
      } catch (e) {
        console.warn('Relay publisher ICE:', e.message);
      }
    },

    onViewerJoined(room, viewerId, viewerWs, sendFn) {
      const relay = ensureRelay(room);
      if (relay.mediaStream) {
        return startViewerSession(room, viewerId, viewerWs, sendFn);
      }
      if (!relay.pendingViewerIds.includes(viewerId)) {
        relay.pendingViewerIds.push(viewerId);
      }
    },

    needsPublisherRelay(room) {
      const relay = room.mediaRelay;
      return !relay?.mediaStream && !relay?.inboundPc;
    },

    async handleViewerAnswer(room, msg, viewerWs) {
      const viewerId = msg.viewerId || viewerWs.viewerId;
      const session = room.mediaRelay?.viewerSessions.get(viewerId);
      if (!session) return;
      await session.pc.setRemoteDescription(
        new wrtc.RTCSessionDescription({
          type: msg.sdpType || 'answer',
          sdp: msg.sdp,
        }),
      );
      for (const c of session.pendingIce) {
        try {
          await session.pc.addIceCandidate(c);
        } catch (_) {}
      }
      session.pendingIce = [];
    },

    async handleViewerIce(room, msg, viewerWs) {
      const viewerId = viewerWs.viewerId;
      const session = room.mediaRelay?.viewerSessions.get(viewerId);
      if (!session || !msg.candidate) return;
      const cand = new wrtc.RTCIceCandidate({
        candidate: msg.candidate,
        sdpMid: msg.sdpMid,
        sdpMLineIndex: msg.sdpMLineIndex,
      });
      if (!session.pc.remoteDescription) {
        session.pendingIce.push(cand);
        return;
      }
      try {
        await session.pc.addIceCandidate(cand);
      } catch (e) {
        console.warn('Relay viewer ICE:', e.message);
      }
    },

    onViewerLeft(room, viewerId) {
      const relay = room.mediaRelay;
      if (!relay) return;
      const session = relay.viewerSessions.get(viewerId);
      if (session) {
        try {
          session.pc.close();
        } catch (_) {}
        relay.viewerSessions.delete(viewerId);
      }
      const idx = relay.pendingViewerIds.indexOf(viewerId);
      if (idx >= 0) relay.pendingViewerIds.splice(idx, 1);
    },

    onPublisherLeft(room) {
      const relay = room.mediaRelay;
      if (!relay) return;
      if (relay.inboundPc) {
        try {
          relay.inboundPc.close();
        } catch (_) {}
      }
      for (const [, session] of relay.viewerSessions) {
        try {
          session.pc.close();
        } catch (_) {}
      }
      room.mediaRelay = null;
    },
  };
}

module.exports = { RELAY_ID, createMediaRelay };
