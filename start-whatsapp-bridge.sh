#!/usr/bin/env bash
#
# Starts the WhatsApp bridge. On first run it prints a QR code — scan it with
# WhatsApp on your phone (Settings > Linked Devices > Link a Device).
#
# Keep this process running while you use the WhatsApp MCP server. You'll need to
# re-scan roughly every ~20 days when the session expires.
#
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/whatsapp-mcp/whatsapp-bridge"

if [ ! -d "$DIR" ]; then
  echo "whatsapp-mcp not found. Run ./setup.sh first." >&2
  exit 1
fi

cd "$DIR"
exec go run main.go
