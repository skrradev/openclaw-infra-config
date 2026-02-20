# OpenClaw Useful Configs

All configs are set with `openclaw config set <key> <value>` and stored in `~/.openclaw/config.json`.

View current config:

```bash
openclaw config list
```

## Gateway

```bash
# Bind gateway to loopback only (use with Tailscale serve)
openclaw config set gateway.bind loopback

# Bind gateway to all interfaces (default)
openclaw config set gateway.bind all

# Allow remote restart via Control UI
openclaw config set commands.restart true
```

```json
{
  "gateway": {
    "bind": "loopback"
  },
  "commands": {
    "restart": true
  }
}
```

## Gateway Auth

```bash
# Allow Tailscale-authenticated connections (no token needed from tailnet peers)
openclaw config set gateway.auth.allowTailscale true
```

```json
{
  "gateway": {
    "auth": {
      "allowTailscale": true
    }
  }
}
```

## Tailscale Serve

```bash
# Proxy HTTPS through your tailnet
openclaw config set gateway.tailscale.mode serve

# Clean up tailscale serve when gateway stops
openclaw config set gateway.tailscale.resetOnExit true
```

```json
{
  "gateway": {
    "tailscale": {
      "mode": "serve",
      "resetOnExit": true
    }
  }
}
```

## Browser

```bash
# Enable browser automation (web scraping, screenshots, etc.)
openclaw config set browser.enabled true

# Run Chrome headless (no display needed on servers)
openclaw config set browser.headless true

# Disable Chrome sandbox (required for systemd service users)
openclaw config set browser.noSandbox true

# Set Playwright Chromium binary path (auto-detect finds Snap Chromium which fails)
openclaw config set browser.executablePath $(find ~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome -type f | sort -V | tail -1)
```

```json
{
  "browser": {
    "enabled": true,
    "headless": true,
    "noSandbox": true,
    "executablePath": "/home/openclaw/.cache/ms-playwright/chromium-1208/chrome-linux/chrome"
  }
}
```

## Daemon

```bash
# Install as systemd service
openclaw daemon install

# Start / stop / restart
openclaw daemon start
openclaw daemon stop
openclaw daemon restart

# Check status
openclaw status

# View logs
openclaw logs
openclaw logs --follow
```

## Useful Commands

```bash
# Run the onboarding wizard
openclaw onboard --install-daemon

# Configure interactively
openclaw configure

# Login to messaging providers
openclaw providers login

# Start gateway manually (foreground)
openclaw gateway

# Restart gateway (applies config changes)
openclaw gateway restart

# List pending device pairing requests
openclaw devices list

# Approve a device
openclaw devices approve <requestId>
```
