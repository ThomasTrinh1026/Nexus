#!/usr/bin/env bash
#
# Nexus MCP setup — installs everything needed to use the WhatsApp + Google Sheets
# MCP servers from Claude Code inside this folder.
#
# Safe to re-run: it skips work that's already done.
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_REPO="$REPO_DIR/whatsapp-mcp"
PATCH="$REPO_DIR/patches/whatsmeow-context-fix.patch"

# Pin to the upstream commit the patch was built against, so `git apply` is always
# clean no matter how far upstream main has moved. (See patches/README.md.)
PINNED_COMMIT="7d6a06dcdce1f01dfb24f60e1030d5efba9f3b88"

say() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# --- 1. uv (runs both MCP servers) ----------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  say "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
UV_BIN="$(command -v uv || echo "$HOME/.local/bin/uv")"
UVX_BIN="$(command -v uvx || echo "$HOME/.local/bin/uvx")"
say "uv:  $UV_BIN"

# --- 2. Go (compiles the WhatsApp bridge) ---------------------------------------
if ! command -v go >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    say "Installing Go + ffmpeg via Homebrew..."
    brew install go ffmpeg
  else
    warn "Go is not installed and Homebrew was not found."
    warn "Install Go 1.24+ from https://go.dev/dl/ , then re-run this script."
    exit 1
  fi
fi
say "Go:  $(go version)"

# --- 3. WhatsApp bridge: clone (pinned) + apply the Go-compat fix ----------------
if [ ! -d "$BRIDGE_REPO/.git" ]; then
  say "Cloning whatsapp-mcp (pinned to $PINNED_COMMIT)..."
  git clone https://github.com/lharries/whatsapp-mcp.git "$BRIDGE_REPO"
  git -C "$BRIDGE_REPO" checkout --quiet "$PINNED_COMMIT"

  say "Applying whatsmeow/Go compatibility patch (upstream PR #193)..."
  git -C "$BRIDGE_REPO" apply "$PATCH"
else
  say "whatsapp-mcp already present — leaving it as-is (delete the folder to re-clone)."
fi

# --- 4. Update whatsmeow to latest + pre-build so errors surface now -------------
# WhatsApp periodically raises its minimum client version and rejects older
# whatsmeow builds with "Client outdated (405)" at connect time. Pulling @latest
# at setup keeps the reported client version current. (This supersedes the
# baseline version the PR #193 patch wrote into go.mod.)
say "Updating whatsmeow to the latest version (avoids WhatsApp 'Client outdated' 405)..."
( cd "$BRIDGE_REPO/whatsapp-bridge" \
    && go get go.mau.fi/whatsmeow@latest \
    && go mod tidy \
    && go build -o /dev/null ./... )
say "Bridge builds OK against the latest whatsmeow."

# --- 5. Generate .mcp.json for THIS machine -------------------------------------
say "Google Sheets setup (optional — press Enter at both prompts to skip)."
cat <<'EOF'
  Google Sheets needs a "service account" key file. Quick version (full steps in SETUP.md):
    1. https://console.cloud.google.com  ->  enable "Google Sheets API" + "Google Drive API"
    2. IAM & Admin -> Service Accounts -> create one -> Keys -> Add key -> JSON (downloads a file)
    3. In Google Drive, make a folder and Share it with the service account's email
       (the "client_email" in that JSON, ends in ...iam.gserviceaccount.com)
  Skip this if you only want WhatsApp — you can fill it in later by editing .mcp.json.
EOF
read -r -p "  Path to the service-account JSON key: " SA_PATH || true
read -r -p "  Google Drive folder ID (from the folder's URL): " DRIVE_ID || true
SA_PATH="${SA_PATH:-/REPLACE/with/path/to/service-account-key.json}"
DRIVE_ID="${DRIVE_ID:-REPLACE_with_shared_drive_folder_id}"

cat > "$REPO_DIR/.mcp.json" <<EOF
{
  "mcpServers": {
    "google-sheets": {
      "command": "$UVX_BIN",
      "args": ["mcp-google-sheets@latest"],
      "env": {
        "SERVICE_ACCOUNT_PATH": "$SA_PATH",
        "DRIVE_FOLDER_ID": "$DRIVE_ID"
      }
    },
    "whatsapp": {
      "command": "$UV_BIN",
      "args": ["--directory", "$BRIDGE_REPO/whatsapp-mcp-server", "run", "main.py"]
    }
  }
}
EOF
say "Wrote $REPO_DIR/.mcp.json"

cat <<'EOF'

------------------------------------------------------------------
Setup complete. Two things left, both one-time:

  1. WhatsApp — start the bridge and scan the QR with your phone
     (Settings > Linked Devices). Keep it running:

         ./start-whatsapp-bridge.sh

  2. Google Sheets — if you skipped the prompts, edit .mcp.json and
     set SERVICE_ACCOUNT_PATH + DRIVE_FOLDER_ID. See SETUP.md for how
     to create the service account.

Then restart Claude Code (or run /mcp) to load the servers.
------------------------------------------------------------------
EOF

# Offer to launch the bridge right now (only when run interactively).
if [ -t 0 ]; then
  printf '\nStart the WhatsApp bridge now and show the QR code to scan? [y/N] '
  read -r ANS || true
  case "${ANS:-}" in
    [Yy]*)
      say "Starting bridge — scan the QR with WhatsApp > Settings > Linked Devices. Ctrl-C to stop."
      exec "$REPO_DIR/start-whatsapp-bridge.sh"
      ;;
    *)
      echo "OK — run ./start-whatsapp-bridge.sh whenever you're ready."
      ;;
  esac
fi
