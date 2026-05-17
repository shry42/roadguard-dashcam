#!/usr/bin/env bash
# Stable public URL for RoadGuard (pick one option).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SERVER="$ROOT/server"

echo "=============================================="
echo " RoadGuard — stable streaming URL (one-time)"
echo "=============================================="
echo ""
echo "OPTION A — Recommended (no domain, fixed URL)"
echo "  Deploy server to Render (free):"
echo "    1. Push this repo to GitHub"
echo "    2. https://dashboard.render.com → New → Blueprint"
echo "    3. Select repo → deploy render.yaml"
echo "    4. Your URL: https://roadguard-signaling.onrender.com"
echo "       (or the name you choose in Render)"
echo "    5. App Settings → Signaling URL:"
echo "       wss://roadguard-signaling.onrender.com"
echo "    6. Website: same https://... URL (admin page + API)"
echo ""
echo "  Note: free tier sleeps after ~15 min idle;"
echo "  first viewer may wait ~30s to wake the server."
echo ""
echo "OPTION B — Your own domain (Mac must stay on)"
echo "  Named Cloudflare Tunnel → e.g. dashcam.yourdomain.com"
echo "  Run: $SERVER/scripts/setup-cloudflare-named-tunnel.sh"
echo ""
echo "OPTION C — Temporary (changes every restart)"
echo "  cloudflared tunnel --url http://localhost:8080"
echo "  (trycloudflare.com — NOT stable)"
echo ""
read -r -p "Start local server now for testing? [y/N] " ans
if [[ "${ans,,}" == "y" ]]; then
  cd "$SERVER"
  npm install -q
  echo "Starting http://localhost:8080 ..."
  exec npm start
fi
