# Detailed setup

This covers the parts that can't be automated: creating Google credentials and
linking WhatsApp. Run `./setup.sh` first.

## Prerequisites

`setup.sh` installs these automatically on macOS (via the official installer for
`uv` and Homebrew for Go). If you're not on macOS, install them yourself:

| Tool | Why | Install |
|------|-----|---------|
| [uv](https://docs.astral.sh/uv/) | runs both MCP servers | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| [Go](https://go.dev/dl/) 1.24+ | compiles the WhatsApp bridge | https://go.dev/dl/ |
| ffmpeg | (optional) WhatsApp audio messages | `brew install ffmpeg` |

## WhatsApp

1. `./start-whatsapp-bridge.sh`
2. A QR code prints in the terminal. On your phone: **WhatsApp → Settings →
   Linked Devices → Link a Device**, then scan it.
3. Leave the bridge running. It stores its session + a local message DB under
   `whatsapp-mcp/whatsapp-bridge/store/` (gitignored). Re-scan ~every 20 days.

If the bridge fails to build, see [`patches/README.md`](patches/README.md) — the
Go-compatibility fix should already be applied by `setup.sh`.

## Google Sheets (service account — recommended)

A service account is a headless Google identity. You give it access to specific
Drive folders, and the MCP server authenticates as it — no browser login.

1. **Create / pick a Google Cloud project** at
   https://console.cloud.google.com.
2. **Enable APIs:** APIs & Services → Library → enable both
   **Google Sheets API** and **Google Drive API**.
3. **Create the service account:** IAM & Admin → Service Accounts → Create.
   Give it a name; the default role is fine.
4. **Make a key:** open the service account → Keys → Add Key → Create new key →
   **JSON**. A `.json` file downloads. Keep it somewhere safe **outside this
   repo** (or it'll be caught by `.gitignore`, but outside is cleaner).
5. **Share a folder with it:** in Google Drive, create a folder for the sheets
   you want Claude to access, then Share it with the service account's email
   (the `client_email` value inside the JSON, ends in
   `...iam.gserviceaccount.com`). Give it **Editor**.
6. **Get the folder ID:** open the folder; the URL is
   `https://drive.google.com/drive/folders/<THIS_IS_THE_ID>`.
7. **Point the config at them** — either answer the `setup.sh` prompts, or edit
   `.mcp.json`:
   - `SERVICE_ACCOUNT_PATH` → full path to the JSON key
   - `DRIVE_FOLDER_ID` → the folder ID

Only sheets in (or moved into) that shared folder are visible to the server.

### OAuth instead of a service account?

If you'd rather have it act as *your personal* Google account, the server also
supports OAuth (`CREDENTIALS_PATH` + `TOKEN_PATH`). See the
[mcp-google-sheets README](https://github.com/xing5/mcp-google-sheets) for that
flow.

## Loading the servers in Claude Code

After setup, restart Claude Code in this folder, or run `/mcp` to (re)connect.
You'll be prompted to approve `whatsapp` and `google-sheets` the first time.
