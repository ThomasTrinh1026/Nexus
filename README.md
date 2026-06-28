# Nexus

A ready-to-use workspace for driving **WhatsApp** and **Google Sheets** from
[Claude Code](https://claude.com/claude-code). Clone it, run one setup script,
and Claude Code running inside this folder can read/send WhatsApp messages and
read/write Google Sheets.

It wires up two MCP servers:

- **WhatsApp** — [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp)
- **Google Sheets** — [xing5/mcp-google-sheets](https://github.com/xing5/mcp-google-sheets)

> The WhatsApp bridge is cloned at setup time and **patched** for current Go
> toolchains (upstream's pinned version fails to build on new Go — see
> [`patches/`](patches/README.md)). That patch is why you should use this setup
> script rather than cloning whatsapp-mcp by hand.

## Quick start

```bash
git clone <this-repo-url> Nexus
cd Nexus
./setup.sh
```

`setup.sh` will:
1. Install `uv` (and Go + ffmpeg via Homebrew on macOS) if missing
2. Clone the WhatsApp bridge into `./whatsapp-mcp/` and apply the Go-compat patch
3. Build the bridge to confirm it compiles
4. Generate a machine-specific `.mcp.json`

Then finish the two one-time, per-person steps below and restart Claude Code
(or run `/mcp`).

## 1. WhatsApp — link your phone

```bash
./start-whatsapp-bridge.sh
```

Scan the QR code with WhatsApp on your phone (**Settings → Linked Devices → Link
a Device**). **Keep this process running** while you use WhatsApp from Claude —
it's the bridge between WhatsApp and the MCP server. You'll re-scan roughly every
~20 days when the session expires.

## 2. Google Sheets — service account

See [SETUP.md](SETUP.md) for the full walkthrough. In short:

1. In Google Cloud Console, enable the **Google Sheets API** and **Google Drive API**.
2. Create a **service account**, download its **JSON key**.
3. Create a Drive folder and **share it with the service account's email**.
4. Put the key path + folder ID into `.mcp.json` (the setup script prompts for these).

## Notes for sharing this repo

- `.mcp.json`, the `whatsapp-mcp/` clone, and any credential files are
  **gitignored** — they're machine-specific or secret. Each person runs
  `./setup.sh` to generate their own.
- Auth is inherently per-person: everyone scans their **own** WhatsApp QR and
  uses their **own** Google service-account key. There's nothing shared to commit.
