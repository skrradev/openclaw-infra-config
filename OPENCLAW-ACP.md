# OpenClaw ACP (Agent Communication Protocol) Setup

ACP lets OpenClaw agents dispatch tasks to Claude and other AI backends. ACPX is the runtime bridge between OpenClaw and ACP-compatible models.

## Prerequisites

- Node.js installed and in PATH (`node`, `npm`)
- OpenClaw installed and running

## Required Config

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

```json
{
  "tools": {
    "profile": "full",
    "sessions": { "visibility": "all" },
    "agentToAgent": { "enabled": true }
  }
}
```

### Optional: Exec Without Confirmation

Telegram and CLI don't show approval prompts, so `exec` commands hang silently. To allow exec to run without confirmation:

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

## ACPX Permission Mode

ACPX defaults to `permissionMode: approve-reads` — reads are auto-approved, writes require confirmation. In Telegram flow, write prompts can't be approved inline, so they fail silently.

Set `approve-all` to auto-approve writes too:

```bash
openclaw config set plugins.entries.acpx.config.permissionMode '"approve-all"'
```

```json
{
  "plugins": {
    "entries": {
      "acpx": {
        "enabled": true,
        "config": {
          "command": "~/.openclaw/acpx-wrapper.sh",
          "expectedVersion": "0.1.15",
          "permissionMode": "approve-all"
        }
      }
    }
  }
}
```

| Mode | Reads | Writes | Use case |
|------|-------|--------|----------|
| `approve-reads` | Auto | Ask | Default — safe but breaks Telegram/CLI |
| `approve-all` | Auto | Auto | Telegram, CLI, headless — no prompts |

```bash
openclaw gateway restart
```

> **Note:** `permissionMode` is plugin-level (global), not per-folder. To scope Claude to a specific directory, set the `cwd` in your prompts (e.g. `/Users/fastclaws/projects/my-app`).

## ACPX Wrapper

OpenClaw uses a wrapper script to invoke ACPX:

```
~/.openclaw/acpx-wrapper.sh
```

```bash
#!/bin/sh
exec /opt/homebrew/opt/node@22/bin/node /opt/homebrew/lib/node_modules/acpx/dist/cli.js "$@"
```

The path to `node` depends on your installation:

| Platform | Node path |
|----------|-----------|
| macOS (Homebrew) | `/opt/homebrew/opt/node@22/bin/node` |
| Linux (nvm) | `~/.nvm/versions/node/v22.*/bin/node` |
| Linux (system) | `/usr/bin/node` |

Make sure the wrapper points to a valid Node binary:

```bash
# Check if wrapper exists and is executable
cat ~/.openclaw/acpx-wrapper.sh
ls -la ~/.openclaw/acpx-wrapper.sh

# Verify Node is accessible from the wrapper path
node --version
```

## ACPX Version

OpenClaw extensions expect a specific pinned ACPX version. Currently: **0.1.15**

ACPX is installed at:

```
/opt/homebrew/lib/node_modules/openclaw/extensions/acpx
```

To check the installed version:

```bash
node /opt/homebrew/lib/node_modules/acpx/dist/cli.js --version
```

To reinstall the pinned version:

```bash
npm install -g acpx@0.1.15
```

## Troubleshooting

### Symptom: Agent looks dead but isn't crashed

**Cause:** `tools.profile` is `messaging` (OpenClaw 3.2+ default). Agent has no tools — it literally can't do anything.

**Fix:**

```bash
openclaw config set tools.profile full
openclaw gateway restart
```

### Symptom: ACPX backend calls failing

**Cause:** Node binary missing or ACPX not installed at expected version.

**Fix:**

```bash
# 1. Ensure Node is installed
node --version || brew install node

# 2. Reinstall ACPX at pinned version
npm install -g acpx@0.1.15

# 3. Verify wrapper script
cat ~/.openclaw/acpx-wrapper.sh

# 4. Restart gateway
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

### Quick Smoke Test

After fixing, verify ACP is working:

```bash
openclaw gateway status
```

Run a test ACP dispatch — a successful run returns `VERIFIED` or `CLAUDE_OK`.

## Repair Checklist

If ACP stops working, go through this list:

1. **Node in PATH?** — `node --version`
2. **ACPX at pinned version?** — `node /opt/homebrew/lib/node_modules/acpx/dist/cli.js --version` (expect `0.1.15`)
3. **Wrapper script valid?** — `cat ~/.openclaw/acpx-wrapper.sh` (points to real Node binary)
4. **Config correct?** — `openclaw config get tools` (profile: full, sessions.visibility: all, agentToAgent.enabled: true)
5. **Gateway running?** — `openclaw gateway status`
6. **Restart** — `openclaw gateway restart`
7. **Smoke test** — run ACP dispatch, expect `VERIFIED`

> **Upgrading from an older version?** Existing configs aren't overwritten — this mainly affects fresh installs where `openclaw configure` sets `tools.profile` to `messaging`.
