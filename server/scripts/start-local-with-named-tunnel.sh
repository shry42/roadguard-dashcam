#!/usr/bin/env bash
# Run signaling server + named Cloudflare tunnel (after setup-cloudflare-named-tunnel.sh).
set -euo pipefail

TUNNEL_NAME="${TUNNEL_NAME:-roadguard-dashcam}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SERVER="$ROOT/server"

cd "$SERVER"
npm install -q
npm start &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

sleep 2
echo "Starting named tunnel '${TUNNEL_NAME}'..."
exec cloudflared tunnel run "${TUNNEL_NAME}"
