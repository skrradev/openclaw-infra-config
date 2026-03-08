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
| `gateway.controlUi.allowedOrigins` | `[]` | Non-localhost origins allowed to connect to Control UI (e.g. `["*"]`) |

> **Breaking change (2026.3.1+):** Since commit `223d7dc23` (Feb 24, 2026), non-localhost origins must be explicitly listed in `gateway.controlUi.allowedOrigins`. Before this, any origin matching the Host header was allowed. Tailscale serve uses a non-localhost origin, so you must set this or the Control UI will be blocked. Versions up to 2026.2.17 are not affected. Wildcard `"*"` support was added Mar 2.

```bash
# Allow Tailscale-authenticated connections (no token needed from tailnet peers)
openclaw config set gateway.auth.allowTailscale true

# Proxy HTTPS through your tailnet
openclaw config set gateway.tailscale.mode serve

# Clean up tailscale serve when gateway stops
openclaw config set gateway.tailscale.resetOnExit true

# Allow Control UI from non-localhost origins (required for Tailscale serve in 2026.3.1+)
openclaw config set gateway.controlUi.allowedOrigins '["*"]'
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
    },
    "controlUi": {
      "allowedOrigins": ["*"]
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

`openclaw onboard --install-daemon` installs and starts the daemon service. Platform differences:

| | macOS | Linux |
|---|---|---|
| Daemon type | launchd (LaunchAgent) | systemd (user service) |
| Service file | `~/Library/LaunchAgents/ai.openclaw.gateway.plist` | `~/.config/systemd/user/openclaw-gateway.service` |
| Auto-start | `RunAtLoad: true` | `WantedBy=default.target` |
| Auto-restart | `KeepAlive: true` | `Restart=always` |

> **macOS note:** LaunchAgents are user-level services — they only run when the user is logged in (unlike Linux systemd with lingering enabled).

> **Token note:** `onboard --install-daemon` generates a new gateway token. If you already have a working token, pass it explicitly to avoid mismatch:
> ```bash
> openclaw onboard --install-daemon --gateway-token YOUR_EXISTING_TOKEN
> ```

```bash
# Install daemon
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

## Control UI (Dashboard)

The Control UI connects to the gateway via WebSocket (`ws://127.0.0.1:18789`) and requires a gateway token.

If you see **"gateway token missing"**, paste your token in the "Gateway Token" field and click Connect.

To get your token:

```bash
# Print dashboard URL with token embedded
openclaw dashboard --no-open

# Or get the token directly from config
openclaw config get gateway.auth.token
```

## Telegram Group Setup

Three things must be configured for the bot to work in Telegram groups.

### 1. Set group policy

```bash
openclaw config set channels.telegram.groupPolicy allowlist
```

| Value | Behavior |
|-------|----------|
| `allowlist` | Only registered groups + user IDs in `groupAllowFrom` can talk **(recommended)** |
| `open` | Everyone can talk to the bot |
| `pairing` | Only users who paired via DM can talk |
| `disabled` | Bot ignores all group messages |

**`allowlist` requires two checks to pass:**

1. **Chat-level** — Is this group registered in the `groups` config?
2. **Sender-level** — Is this person's user ID in `groupAllowFrom`?

If the group isn't registered, the chat-level check fails before it even checks your user ID. You need **both**:

```bash
# Register the group (also disables @mention requirement)
openclaw config set 'channels.telegram.groups.-100XXXXXXXXXX.requireMention' false

# AND add your user ID to groupAllowFrom
openclaw config set channels.telegram.groupAllowFrom '["305695524"]'
```

### 2. Allow yourself to run admin commands

```bash
openclaw config set channels.telegram.allowFrom '["YOUR_TELEGRAM_USER_ID"]'
```

Get your user ID by messaging `@userinfobot` on Telegram. This is a **positive number** (e.g. `305695524`), not a group ID.

Without this, commands like `/activation`, `/status`, `/acp` will return "You are not authorized."

### 3. Disable @mention requirement (optional)

**Option A** — from chat (per-session, doesn't survive restart):

```
/activation always
```

**Option B** — from config (permanent, per-group):

```bash
openclaw config set 'channels.telegram.groups.<GROUP_ID>.requireMention' false
```

### 4. Restart

```bash
openclaw gateway restart
```

### 5. Telegram BotFather setting

In `@BotFather` → your bot → **Bot Settings** → **Group Privacy** → **Turn off** (`/setprivacy` → Disable).

Without this, Telegram itself filters out non-mention messages before they reach OpenClaw.

### Common mistakes

| Mistake | Symptom |
|---------|---------|
| Group ID in `allowFrom` or `groupAllowFrom` | "Invalid allowFrom entry" warning in logs. Use **user IDs** (positive numbers), not group IDs |
| Group not registered in `groups` config | "not-allowed" / "This group is not allowed" — chat-level check fails before sender check |
| Missing `groupAllowFrom` | Messages silently dropped even though group is registered |
| Missing `allowFrom` | "You are not authorized to use this command" for admin commands |
| Didn't restart gateway after config change | Old config still active |
| BotFather Group Privacy is ON | Bot only sees @mentions regardless of config |

### Config reference

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist",
      "allowFrom": ["305695524"],
      "groupAllowFrom": ["305695524"],
      "streaming": "partial",
      "groups": {
        "-1003857598570": {
          "requireMention": false
        }
      }
    }
  }
}
```

## DM Policy (Telegram)

Controls who can message your bot via DM.

| Policy | Description |
|--------|-------------|
| `pairing` | Default. User confirms identity once, then trusted |
| `open` | Anyone can DM, no questions asked |
| `allowlist` | Only specific Telegram user IDs allowed |
| `disabled` | No DMs at all — group channels only |

```bash
# Set DM policy
openclaw config set channels.telegram.dmPolicy pairing

# Set per-account DM policy
openclaw config set channels.telegram.accounts.engineer.dmPolicy allowlist

# Add allowed user IDs
openclaw config set channels.telegram.accounts.engineer.allowFrom '["123456789"]'
```

**pairing** (default, recommended):

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "pairing"
    }
  }
}
```

First time someone DMs your bot, it asks "who are you?" After pairing, bot remembers and responds normally.

**open** — anyone can DM:

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  }
}
```

> **Warning:** anyone uses your API credits.

**allowlist** — only specific users:

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "allowlist",
      "allowFrom": ["123456789", "987654321"]
    }
  }
}
```

Only these Telegram user IDs can DM the bot. Everyone else is ignored.

**disabled** — no DMs:

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "disabled"
    }
  }
}
```

Bot ignores all private messages. Only works in group channels.

**Per-account example** (different policy per bot):

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "pairing",
      "accounts": {
        "commander": {
          "botToken": "TOKEN",
          "dmPolicy": "pairing"
        },
        "engineer": {
          "botToken": "TOKEN",
          "dmPolicy": "allowlist",
          "allowFrom": ["123456789"]
        },
        "thinktank": {
          "botToken": "TOKEN",
          "dmPolicy": "disabled"
        }
      }
    }
  }
}
```

Commander open to pairing, Engineer restricted to one user, ThinkTank group-only.

## Session Scope (dmScope)

Controls how DM sessions are isolated between agents, platforms, and users.

```bash
openclaw config set session.dmScope per-account-channel-peer
```

| Value | Isolation | Example |
|-------|-----------|---------|
| `main` | One session for everything | DM Commander on Discord and Telegram = same session, same context |
| `per-peer` | Per user | Different users get different sessions, but same user across all bots/channels shares one |
| `per-channel-peer` | Per platform + user | Discord vs Telegram = different sessions. But Commander and Engineer on same platform = same session |
| `per-account-channel-peer` | Per bot + platform + user | Commander on Discord, Commander on Telegram, Engineer on Discord = all 3 separate. **Maximum isolation** |

```json
{
  "session": {
    "dmScope": "per-account-channel-peer"
  }
}
```

**Recommended:** `per-account-channel-peer` for multi-agent setups. No context leaks between agents or platforms.
