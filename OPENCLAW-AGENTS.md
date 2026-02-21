# OpenClaw Agents — Adding a New Agent with Its Own Telegram Bot

Each OpenClaw agent can have its own Telegram bot. Messages sent to Bot A go to Agent A, messages sent to Bot B go to Agent B. They are completely independent — separate conversations, workspaces, and contexts.

## Key Concepts

### accountId

A label you choose (e.g. `research`, `work`, `personal`). It connects three things together:

1. **Config** — `channels.telegram.accounts.<accountId>.botToken`
2. **Binding** — `"match": { "channel": "telegram", "accountId": "<accountId>" }`
3. **Agent** — `"agentId": "<agentName>"` in the binding

### Binding

A routing rule: "when a message arrives from this bot account, send it to this agent."

```json
{
  "agentId": "research",
  "match": {
    "channel": "telegram",
    "accountId": "research"
  }
}
```

### Workspace

Each agent gets its own workspace directory. OpenClaw creates it automatically.

## Prerequisites

- OpenClaw installed and running with at least one Telegram bot (the main/default bot)
- `jq` and `sponge` installed:

```bash
sudo apt install jq moreutils
```

## Step-by-Step

### 1. Create a New Telegram Bot

1. Open Telegram, message **@BotFather**
2. Send `/newbot`
3. Choose a display name (e.g. "My Research Bot")
4. Choose a username (must end in `bot`, e.g. `my_research_bot`)
5. Copy the bot token (format: `1234567890:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)

### 2. Add Bot Token to Config

> **Must be done BEFORE creating the agent (step 3).**

```bash
openclaw config set channels.telegram.accounts.<accountId>.botToken "<TOKEN>"
```

Example:

```bash
openclaw config set channels.telegram.accounts.research.botToken "7695688686:AAEh20dkOs..."
```

### 3. Create the Agent

```bash
openclaw agents add <agentName> --workspace ~/.openclaw/workspace-<agentName>
```

Example:

```bash
openclaw agents add research --workspace ~/.openclaw/workspace-research
```

> **Note:** The `--bind` flag exists (`--bind telegram:<accountId>`) but has a known bug ("Unknown channel" error). Use step 4 instead.

### 4. Add Bindings with jq

> **When adding any new bot account, you MUST also add an explicit binding for your main/default bot. Otherwise the main bot will stop responding.**

First time (going from 1 bot to 2 bots):

```bash
jq '.channels.telegram.accounts.default = {
  "botToken": .channels.telegram.botToken,
  "dmPolicy": "pairing",
  "groupPolicy": "allowlist",
  "streamMode": "partial"
} | .bindings = [
  {"agentId":"main","match":{"channel":"telegram","accountId":"default"}},
  {"agentId":"<agentName>","match":{"channel":"telegram","accountId":"<accountId>"}}
]' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

Adding more bots later (already have 2+ bots):

```bash
jq '.bindings += [{"agentId":"<agentName>","match":{"channel":"telegram","accountId":"<accountId>"}}]' \
  ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

### 5. Restart Gateway

```bash
openclaw gateway restart
```

### 6. Verify

```bash
openclaw status --all
```

All Telegram accounts should show `OK`.

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `Unknown channel "telegram"` with `--bind` | Bug: plugin registry not loaded | Skip `--bind`, add bindings manually with `jq` |
| Main bot stops responding | No binding for main bot | Add `default` account + binding for main bot |
| Token added but bot not connecting | Gateway not restarted | `openclaw gateway restart` |
| `--bind` fails | Token not in config yet | Always add token (step 2) before agent (step 3) |

## Final Config Structure

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "DEFAULT_BOT_TOKEN",
      "accounts": {
        "default": {
          "botToken": "DEFAULT_BOT_TOKEN",
          "dmPolicy": "pairing",
          "groupPolicy": "allowlist",
          "streamMode": "partial"
        },
        "research": {
          "botToken": "RESEARCH_BOT_TOKEN",
          "dmPolicy": "pairing",
          "groupPolicy": "allowlist",
          "streamMode": "partial"
        }
      }
    }
  },
  "agents": {
    "list": [
      { "id": "main" },
      { "id": "research", "workspace": "~/.openclaw/workspace-research" }
    ]
  },
  "bindings": [
    { "agentId": "main", "match": { "channel": "telegram", "accountId": "default" } },
    { "agentId": "research", "match": { "channel": "telegram", "accountId": "research" } }
  ]
}
```

## Quick Reference — 5 Commands

```bash
# 1. Add bot token (get from @BotFather first)
openclaw config set channels.telegram.accounts.NAME.botToken "TOKEN"

# 2. Create agent
openclaw agents add NAME --workspace ~/.openclaw/workspace-NAME

# 3. Add binding (append if bindings already exist)
jq '.bindings += [{"agentId":"NAME","match":{"channel":"telegram","accountId":"NAME"}}]' \
  ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json

# 4. Restart
openclaw gateway restart

# 5. Verify
openclaw status --all
```
