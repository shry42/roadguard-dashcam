#!/usr/bin/env bash
# Stable hostname via Cloudflare Tunnel (requires a domain on Cloudflare).
set -euo pipefail

TUNNEL_NAME="${TUNNEL_NAME:-roadguard-dashcam}"
LOCAL_URL="${LOCAL_URL:-http://localhost:8080}"
CONFIG_DIR="${HOME}/.cloudflared"
CONFIG_FILE="${CONFIG_DIR}/config.yml"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Install cloudflared: brew install cloudflared"
  exit 1
fi

echo "Named Cloudflare Tunnel → stable URL on YOUR domain"
echo "Prerequisites:"
echo "  • Free Cloudflare account: https://dash.cloudflare.com/sign-up"
echo "  • A domain added to Cloudflare (e.g. yourdomain.com)"
echo "  • Local signaling server: cd server && npm start"
echo ""

read -r -p "Hostname (e.g. dashcam.yourdomain.com): " HOSTNAME
if [[ -z "${HOSTNAME}" ]]; then
  echo "Hostname required."
  exit 1
fi

if [[ ! -f "${CONFIG_DIR}/cert.pem" ]]; then
  echo "Opening browser to log in to Cloudflare..."
  cloudflared tunnel login
fi

if ! cloudflared tunnel list 2>/dev/null | grep -q "${TUNNEL_NAME}"; then
  echo "Creating tunnel '${TUNNEL_NAME}'..."
  cloudflared tunnel create "${TUNNEL_NAME}"
fi

TUNNEL_ID="$(cloudflared tunnel list 2>/dev/null | awk -v n="${TUNNEL_NAME}" '$0 ~ n {print $1; exit}')"
if [[ -z "${TUNNEL_ID}" ]]; then
  echo "Could not find tunnel ID. Run: cloudflared tunnel list"
  exit 1
fi

mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_FILE}" <<EOF
tunnel: ${TUNNEL_ID}
credentials-file: ${CONFIG_DIR}/${TUNNEL_ID}.json

ingress:
  - hostname: ${HOSTNAME}
    service: ${LOCAL_URL}
  - service: http_status:404
EOF

echo "Routing DNS ${HOSTNAME} → tunnel..."
cloudflared tunnel route dns "${TUNNEL_NAME}" "${HOSTNAME}" || true

echo ""
echo "=============================================="
echo " Stable URLs (save these in the app):"
echo "   Web viewer:  https://${HOSTNAME}/"
echo "   API:         https://${HOSTNAME}/api/stream-config?room=dashcam-1"
echo "   App (WSS):   wss://${HOSTNAME}"
echo "=============================================="
echo ""
echo "Start tunnel (keep this terminal open):"
echo "  cloudflared tunnel run ${TUNNEL_NAME}"
echo ""
read -r -p "Start tunnel now? [y/N] " ans
if [[ "${ans,,}" == "y" ]]; then
  exec cloudflared tunnel run "${TUNNEL_NAME}"
fi
