# OpenClaw Useful Configs

All configs are set with `openclaw config set <key> <value>` and stored in `~/.openclaw/config.json`.

View current config:

```bash
openclaw config list
```

## Gateway

| Config | Default | Description |
|--------|---------|-------------|
| `gateway.bind` | `all` | Bind address — `loopback` for Tailscale serve, `all` for direct access |
| `commands.restart` | `false` | Allow remote restart via Control UI |

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

## Tailscale

| Config | Default | Description |
|--------|---------|-------------|
| `gateway.auth.allowTailscale` | `false` | Allow Tailscale-authenticated connections without token |
| `gateway.tailscale.mode` | `""` | Set to `serve` to proxy HTTPS through your tailnet |
| `gateway.tailscale.resetOnExit` | `false` | Clean up tailscale serve when gateway stops |

```bash
# Allow Tailscale-authenticated connections (no token needed from tailnet peers)
openclaw config set gateway.auth.allowTailscale true

# Proxy HTTPS through your tailnet
openclaw config set gateway.tailscale.mode serve

# Clean up tailscale serve when gateway stops
openclaw config set gateway.tailscale.resetOnExit true
```

```json
{
  "gateway": {
    "auth": {
      "allowTailscale": true
    },
    "tailscale": {
      "mode": "serve",
      "resetOnExit": true
    }
  }
}
```

## Browser

| Config | Default | Description |
|--------|---------|-------------|
| `browser.enabled` | `true` (Linux) | Enable browser automation (web scraping, screenshots) |
| `browser.headless` | `false` | Run Chrome without a visible window (headless servers) |
| `browser.noSandbox` | `false` | Disable Chrome sandbox (required for systemd service users) |
| `browser.defaultProfile` | `""` | Browser profile — `chrome` or `openclaw` (see below) |
| `browser.executablePath` | auto-detect | Path to Chromium binary (set manually to avoid Snap Chromium) |

**Browser Profiles:**

| Profile | Backend | Use case |
|---------|---------|----------|
| `chrome` | Chrome Extension Relay — controls your real Chrome browser via the OpenClaw extension | Desktop with Chrome extension installed |
| `openclaw` | OpenClaw's own Chromium — a separate Playwright-managed instance | Headless servers (no extension, no display needed) |

On servers, always set `defaultProfile` to `openclaw`.

```bash
# Enable browser automation (web scraping, screenshots, etc.)
openclaw config set browser.enabled true

# Run Chrome headless (no display needed on servers)
openclaw config set browser.headless true

# Disable Chrome sandbox (required for systemd service users)
openclaw config set browser.noSandbox true

# Set browser profile name
openclaw config set browser.defaultProfile openclaw

# Set Playwright Chromium binary path (auto-detect finds Snap Chromium which fails)
openclaw config set browser.executablePath $(find ~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome -type f | sort -V | tail -1)
```

```json
{
  "browser": {
    "enabled": true,
    "headless": true,
    "noSandbox": true,
    "defaultProfile": "openclaw",
    "executablePath": "/home/openclaw/.cache/ms-playwright/chromium-1208/chrome-linux/chrome"
  }
}
```

## Subagent

Safety limits to prevent runaway costs (e.g. AI spawning 100 subagents in a loop).

| Config | Default | Description |
|--------|---------|-------------|
| `maxConcurrent` | `8` | Max 8 subagents running at the same time across all sessions. New spawns wait in queue |
| `maxSpawnDepth` | `1` | Subagents cannot spawn their own subagents. Only the main agent can spawn |
| `maxChildrenPerAgent` | `5` | One main agent session can have max 5 active subagents at once |
| `archiveAfterMinutes` | `60` | Subagent session auto-deleted after 60 minutes of completion |

For most setups the defaults are fine. Set `maxSpawnDepth: 2` if you want the orchestrator pattern (a "manager" subagent that coordinates multiple "worker" subagents).

```bash
openclaw config set subagent.maxConcurrent 8 && \
openclaw config set subagent.maxSpawnDepth 1 && \
openclaw config set subagent.maxChildrenPerAgent 5 && \
openclaw config set subagent.archiveAfterMinutes 60
```

```json
{
  "subagent": {
    "maxConcurrent": 8,
    "maxSpawnDepth": 1,
    "maxChildrenPerAgent": 5,
    "archiveAfterMinutes": 60
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
