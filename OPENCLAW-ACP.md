# OpenClaw ACP (Agent Client Protocol) Setup

ACP lets OpenClaw agents dispatch tasks to Claude and other AI backends. ACPX is the runtime bridge between OpenClaw and ACP-compatible models.

## Prerequisites

- Node.js installed and in PATH (`node`, `npm`)
- OpenClaw installed and running

## 1. Install and Enable ACPX Plugin

```bash
openclaw plugins install @openclaw/acpx
openclaw config set plugins.entries.acpx.enabled true
```

## 2. Enable ACP and Configure Backend

```bash
openclaw config set acp.enabled true && \
openclaw config set acp.dispatch.enabled true && \
openclaw config set acp.backend acpx && \
openclaw config set acp.allowedAgents '["pi","claude","codex","opencode","gemini","kimi"]' && \
openclaw config set acp.defaultAgent claude
```

```json
{
  "acp": {
    "enabled": true,
    "dispatch": { "enabled": true },
    "backend": "acpx",
    "allowedAgents": ["pi", "claude", "codex", "opencode", "gemini", "kimi"],
    "defaultAgent": "claude"
  }
}
```

| Config | Description |
|--------|-------------|
| `acp.enabled` | Master switch for ACP |
| `acp.dispatch.enabled` | Allow dispatching tasks to ACP agents |
| `acp.backend` | Which plugin handles ACP calls (`acpx`) |
| `acp.allowedAgents` | List of agent backends your OpenClaw can dispatch to |
| `acp.defaultAgent` | Default agent when none is specified |

Supported agents: `pi`, `claude` (Claude Code), `codex`, `opencode`, `gemini`, `kimi`.

## 3. Set Non-Interactive Permissions

Telegram and CLI don't show approval prompts, so write/exec tasks fail silently. Set permissions so ACP sessions can run without confirmation:

```bash
openclaw config set plugins.entries.acpx.config.permissionMode approve-all
```

`nonInteractivePermissions` defaults to `fail` already, so you only need to set `permissionMode`.

```json
{
  "plugins": {
    "entries": {
      "acpx": {
        "enabled": true,
        "config": {
          "permissionMode": "approve-all"
        }
      }
    }
  }
}
```

| Config | Value | Description |
|--------|-------|-------------|
| `permissionMode` | `approve-all` | Auto-approve both reads and writes (default `approve-reads` blocks writes) |
| `nonInteractivePermissions` | `fail` | Fail clearly instead of hanging (this is already the default) |

> **Note:** `permissionMode` is plugin-level (global), not per-folder. To scope Claude to a specific directory, set the `cwd` in your prompts.

## 4. Tools Config

Three settings must be present in `~/.openclaw/openclaw.json`:

| Config | Value | Description |
|--------|-------|-------------|
| `tools.profile` | `full` | Enables all tools (exec, read, write). Default in 3.2+ is `messaging` which disables everything except sending messages |
| `tools.sessions.visibility` | `all` | Allows cross-session output visibility — agents can read ACP child session responses |
| `tools.agentToAgent.enabled` | `true` | Enables agent-to-agent history sharing |

```bash
openclaw config set tools.profile full && \
openclaw config set tools.sessions.visibility all && \
openclaw config set tools.agentToAgent.enabled true
```

Optional — allow exec to run without confirmation:

```bash
openclaw config set tools.exec.security full && \
openclaw config set tools.exec.ask off
```

```json
{
  "tools": {
    "profile": "full",
    "sessions": { "visibility": "all" },
    "agentToAgent": { "enabled": true },
    "exec": { "security": "full", "ask": "off" }
  }
}
```

> **Note:** `profile` and `exec` are two separate systems. `profile` controls whether tools exist. `exec.security` controls whether commands need approval before running. Fixing `exec` without fixing `profile` first does nothing.

## 5. Restart and Verify

```bash
openclaw gateway restart
```

In chat, run the ACP doctor to verify everything is wired up:

```
/acp doctor
```

A healthy setup shows `healthy: yes` and `runtimeDoctor: ok` in the doctor output.

## 6. ACP Bindings

Bindings route messages from a specific channel/topic to a persistent ACP agent session. Without a binding, ACP is only available via `/acp` commands. With a binding, every message in that channel or topic automatically goes to the configured ACP agent.

Each binding has:

| Field | Description |
|-------|-------------|
| `type` | Must be `"acp"` |
| `agentId` | Which ACP agent handles messages (e.g. `claude`, `codex`, `gemini`) |
| `match` | Identifies the target conversation (channel, account, peer) |
| `acp.cwd` | Working directory for the ACP session (optional) |
| `acp.mode` | `"persistent"` (default) or `"oneshot"` (optional) |
| `acp.label` | Session label for identification (optional) |

### Match patterns

**Telegram forum topic:**

```
match.channel = "telegram"
match.accountId = "default"
match.peer.kind = "group"
match.peer.id = "<chatId>:topic:<topicId>"
```

**Discord channel or thread:**

```
match.channel = "discord"
match.peer.id = "<channelOrThreadId>"
```

### Example: Bind a Telegram topic to Claude

```bash
# Create binding at index 0
openclaw config set 'bindings[0].type' 'acp'
openclaw config set 'bindings[0].agentId' 'claude'

# Match a Telegram forum topic
openclaw config set 'bindings[0].match.channel' 'telegram'
openclaw config set 'bindings[0].match.accountId' 'default'
openclaw config set 'bindings[0].match.peer.kind' 'group'
openclaw config set 'bindings[0].match.peer.id' '-1003857598570:topic:71'

# Set working directory for this ACP session
openclaw config set 'bindings[0].acp.cwd' '/Users/fastclaws/projects/my-app'

# Validate and restart
openclaw config validate
openclaw gateway restart
```

> **Note:** If you already have other bindings, use `bindings[1]`, `bindings[2]`, etc. to avoid overwriting existing ones.

```json
{
  "bindings": [
    {
      "type": "acp",
      "agentId": "claude",
      "match": {
        "channel": "telegram",
        "accountId": "default",
        "peer": {
          "kind": "group",
          "id": "-1003857598570:topic:71"
        }
      },
      "acp": {
        "cwd": "/Users/fastclaws/projects/my-app"
      }
    }
  ]
}
```

### Override precedence

When multiple configuration levels exist:

1. `bindings[].acp.*` settings (highest priority)
2. `agents.list[].runtime.acp.*` defaults
3. Global ACP defaults (lowest priority)

### Behavior

- Messages in the bound channel/topic route directly to the ACP session
- `/new` and `/reset` commands reset the same ACP session in place (don't create new sessions)
- Sessions remain active until unfocused, closed, archived, or expired by idle/max-age timeout

## Troubleshooting

### Symptom: Agent looks dead but isn't crashed

**Cause:** `tools.profile` is `messaging` (OpenClaw 3.2+ default). Agent has no tools — it literally can't do anything.

**Fix:**

```bash
openclaw config set tools.profile full
openclaw gateway restart
```

### Symptom: ACPX backend calls failing

**Cause:** Node binary missing or ACPX not installed.

**Fix:**

```bash
# 1. Ensure Node is installed
node --version || brew install node

# 2. Reinstall ACPX plugin
openclaw plugins install @openclaw/acpx

# 3. Restart gateway
openclaw gateway restart
```

### Symptom: Can't read ACP child session responses

**Cause:** Cross-session visibility is blocked.

**Fix:**

```bash
openclaw config set tools.sessions.visibility all && \
openclaw config set tools.agentToAgent.enabled true
openclaw gateway restart
```

### Symptom: Write/exec tasks fail silently

**Cause:** `permissionMode` is `approve-reads` (default). Writes need approval but Telegram/CLI can't show prompts.

**Fix:**

```bash
openclaw config set plugins.entries.acpx.config.permissionMode approve-all && \
openclaw config set plugins.entries.acpx.config.nonInteractivePermissions fail
openclaw gateway restart
```

## Repair Checklist

If ACP stops working, go through this list:

1. **Node in PATH?** — `node --version`
2. **ACPX plugin installed?** — `openclaw plugins list`
3. **ACP enabled?** — `openclaw config get acp` (enabled: true, dispatch.enabled: true, backend: acpx)
4. **Tools config correct?** — `openclaw config get tools` (profile: full, sessions.visibility: all, agentToAgent.enabled: true)
5. **Permission mode?** — `openclaw config get plugins.entries.acpx` (permissionMode: approve-all)
6. **Gateway running?** — `openclaw gateway status`
7. **Restart** — `openclaw gateway restart`
8. **Smoke test** — `/acp doctor` in chat, expect `healthy: yes`

## Full Config Reference

```json
{
  "acp": {
    "enabled": true,
    "dispatch": { "enabled": true },
    "backend": "acpx",
    "allowedAgents": ["pi", "claude", "codex", "opencode", "gemini", "kimi"],
    "defaultAgent": "claude"
  },
  "plugins": {
    "entries": {
      "acpx": {
        "enabled": true,
        "config": {
          "permissionMode": "approve-all",
          "nonInteractivePermissions": "fail"
        }
      }
    }
  },
  "tools": {
    "profile": "full",
    "sessions": { "visibility": "all" },
    "agentToAgent": { "enabled": true },
    "exec": { "security": "full", "ask": "off" }
  }
}
```

> **Upgrading from an older version?** Existing configs aren't overwritten — this mainly affects fresh installs where `openclaw configure` sets `tools.profile` to `messaging`.
