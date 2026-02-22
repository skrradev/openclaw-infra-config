# 5-Agent AI Collaborative System with OpenClaw

5 AI agents sharing one gateway, operating across Discord and Telegram.

| Agent | Role | Workspace |
|-------|------|-----------|
| `commander` | Task decomposition, coordination, closing | `~/.openclaw/workspace-commander` |
| `strategist` | Strategic analysis, risk, decision support | `~/.openclaw/workspace-strategist` |
| `engineer` | Code, architecture, debugging, deployment | `~/.openclaw/workspace-engineer` |
| `creator` | Content, writing, communication | `~/.openclaw/workspace-creator` |
| `thinktank` | Quality audit, fact-checking, compliance | `~/.openclaw/workspace-thinktank` |

**Discord** = primary collaboration (group chat, Commander orchestrates, others respond to @mentions)
**Telegram** = direct private access to each specialist via DM

## Prerequisites

- OpenClaw installed and running with a main Telegram bot
- `jq` and `sponge` installed: `sudo apt install jq moreutils`
- Discord Developer Portal access
- Telegram @BotFather access

## 1. Create 5 Telegram Bots

1. Open Telegram, message **@BotFather**
2. Send `/newbot` — repeat 5 times
3. Name them: Commander, Strategist, Engineer, Creator, ThinkTank
4. Usernames must end in `bot` (e.g. `myclaw_commander_bot`)
5. Save all 5 tokens

## 2. Create 5 Discord Bots

For each of the 5 roles:

1. Go to https://discord.com/developers/applications
2. Click **New Application** (e.g. "Commander")
3. Go to **Bot** tab, click **Reset Token**, copy the token
4. **Scroll down to Privileged Gateway Intents, enable "Message Content Intent" (toggle ON), Save**
5. Go to **OAuth2** tab, **URL Generator**
6. Scopes: check `bot`
7. Bot Permissions: check `Send Messages`, `Read Message History`, `Read Messages/View Channels`
8. Copy the generated URL, open in browser, invite bot to your Discord server
9. Repeat for all 5 bots

Save all 5 Discord tokens + your **Guild ID** + **Channel ID**.

> To get Guild ID and Channel ID: Enable Developer Mode in Discord (Settings > Advanced > Developer Mode), then right-click server > Copy Server ID (Guild ID), right-click channel > Copy Channel ID.

## 3. Add Telegram Bot Tokens to Config

```bash
openclaw config set channels.telegram.accounts.default.botToken "MAIN_BOT_TOKEN" && \
openclaw config set channels.telegram.accounts.commander.botToken "TG_COMMANDER_TOKEN" && \
openclaw config set channels.telegram.accounts.strategist.botToken "TG_STRATEGIST_TOKEN" && \
openclaw config set channels.telegram.accounts.engineer.botToken "TG_ENGINEER_TOKEN" && \
openclaw config set channels.telegram.accounts.creator.botToken "TG_CREATOR_TOKEN" && \
openclaw config set channels.telegram.accounts.thinktank.botToken "TG_THINKTANK_TOKEN"
```

## 4. Add Discord Bot Tokens to Config

```bash
openclaw config set channels.discord.enabled true && \
openclaw config set channels.discord.accounts.commander.token "DISCORD_COMMANDER_TOKEN" && \
openclaw config set channels.discord.accounts.strategist.token "DISCORD_STRATEGIST_TOKEN" && \
openclaw config set channels.discord.accounts.engineer.token "DISCORD_ENGINEER_TOKEN" && \
openclaw config set channels.discord.accounts.creator.token "DISCORD_CREATOR_TOKEN" && \
openclaw config set channels.discord.accounts.thinktank.token "DISCORD_THINKTANK_TOKEN"
```

## 5. Enable Discord Plugin

```bash
jq '.plugins.entries.discord = {"enabled": true}' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

## 6. Create 5 Agents

```bash
openclaw agents add commander --workspace ~/.openclaw/workspace-commander && \
openclaw agents add strategist --workspace ~/.openclaw/workspace-strategist && \
openclaw agents add engineer --workspace ~/.openclaw/workspace-engineer && \
openclaw agents add creator --workspace ~/.openclaw/workspace-creator && \
openclaw agents add thinktank --workspace ~/.openclaw/workspace-thinktank
```

## 7. Add Bindings + Session Config

> **You MUST also add an explicit binding for your main bot, otherwise it stops responding.**

Replace `GUILD_ID` and `CHANNEL_ID` with your actual IDs.

```bash
jq '
  .bindings = [
    {"agentId":"main","match":{"channel":"telegram","accountId":"default"}},
    {"agentId":"commander","match":{"channel":"telegram","accountId":"commander"}},
    {"agentId":"strategist","match":{"channel":"telegram","accountId":"strategist"}},
    {"agentId":"engineer","match":{"channel":"telegram","accountId":"engineer"}},
    {"agentId":"creator","match":{"channel":"telegram","accountId":"creator"}},
    {"agentId":"thinktank","match":{"channel":"telegram","accountId":"thinktank"}},
    {"agentId":"commander","match":{"channel":"discord","accountId":"commander"}},
    {"agentId":"strategist","match":{"channel":"discord","accountId":"strategist"}},
    {"agentId":"engineer","match":{"channel":"discord","accountId":"engineer"}},
    {"agentId":"creator","match":{"channel":"discord","accountId":"creator"}},
    {"agentId":"thinktank","match":{"channel":"discord","accountId":"thinktank"}}
  ] |
  .session = {
    "dmScope": "per-account-channel-peer",
    "agentToAgent": {"maxPingPongTurns": 0}
  }
' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

## 8. Configure Discord Guild + requireMention

Commander listens to everything. Others only respond when @mentioned.

```bash
jq '
  .channels.discord.accounts.commander.groupPolicy = "allowlist" |
  .channels.discord.accounts.commander.guilds."GUILD_ID".channels."CHANNEL_ID" = {"allow":true,"requireMention":false} |
  .channels.discord.accounts.strategist.groupPolicy = "allowlist" |
  .channels.discord.accounts.strategist.guilds."GUILD_ID".channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.discord.accounts.engineer.groupPolicy = "allowlist" |
  .channels.discord.accounts.engineer.guilds."GUILD_ID".channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.discord.accounts.creator.groupPolicy = "allowlist" |
  .channels.discord.accounts.creator.guilds."GUILD_ID".channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.discord.accounts.thinktank.groupPolicy = "allowlist" |
  .channels.discord.accounts.thinktank.guilds."GUILD_ID".channels."CHANNEL_ID" = {"allow":true,"requireMention":true}
' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

## 9. Add Mention Patterns per Agent

```bash
jq '
  .agents.list = [
    .agents.list[] |
    if .id == "commander" then . + {"groupChat":{"mentionPatterns":["@Commander","@commander"]}}
    elif .id == "strategist" then . + {"groupChat":{"mentionPatterns":["@Strategist","@strategist"]}}
    elif .id == "engineer" then . + {"groupChat":{"mentionPatterns":["@Engineer","@engineer"]}}
    elif .id == "creator" then . + {"groupChat":{"mentionPatterns":["@Creator","@creator"]}}
    elif .id == "thinktank" then . + {"groupChat":{"mentionPatterns":["@ThinkTank","@thinktank","@Think Tank"]}}
    else . end
  ]
' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

## 10. Write Workspace Files

Each workspace needs these files. Create them in `~/.openclaw/workspace-<agent>/`:

| File | Purpose | Unique per agent? |
|------|---------|-------------------|
| `SOUL.md` | Personality, tone, responsibilities, DM vs group behavior | Yes |
| `IDENTITY.md` | Name, role, scope | Yes |
| `AGENTS.md` | Collaboration manual, workflow | Yes |
| `ROLE-COLLAB-RULES.md` | What this role can/cannot do | Yes |
| `TEAM-RULEBOOK.md` | Universal team rules | No (same for all) |
| `TEAM-DIRECTORY.md` | Role-to-mention mapping | No (same for all) |
| `USER.md` | User preferences | No (same for all) |
| `TOOLS.md` | Environment-specific notes | No (same for all) |
| `MEMORY.md` | Long-term memory (starts empty) | Yes |
| `GROUP_MEMORY.md` | Group-safe memory (starts empty) | Yes |
| `memory/` | Directory for daily logs | Yes |

## 11. Restart and Verify

```bash
openclaw gateway restart
```

```bash
openclaw status --all
```

Should show:
- Telegram accounts: 6/6 (default + 5 agents) — all `OK`
- Discord accounts: 5/5 — all `OK`
- Agents: 6 total (main + 5)

## 12. Test

1. **Telegram DMs** — message each bot with "Who are you?" — each should respond with their role
2. **Discord channel** — type a message — Commander should respond (global listener)
3. **Discord @mention** — type `@Engineer write hello world in Python` — only Engineer responds
4. **Collaboration** — ask a complex question — Commander should decompose and @mention specialists

## Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `Fatal Gateway error: 4014` | Message Content Intent not enabled | Discord Dev Portal > Bot > Privileged Gateway Intents > Enable Message Content Intent |
| `channels unresolved` | Bots not invited to Discord server | Generate OAuth2 invite URL for each bot and invite them |
| `Unknown channel "telegram"` with `--bind` | Bug in OpenClaw CLI | Skip `--bind`, add bindings manually with `jq` |
| Main bot stops responding | No binding for main bot | Always add explicit binding for main/default bot |
| Agent not responding in Telegram | Bootstrap still pending | Restart gateway, send message, wait 10-15 seconds |
| Token added but bot not connecting | Gateway not restarted | `openclaw gateway restart` |

## Security Notes

- `groupPolicy: "allowlist"` on all accounts — bots only respond in explicitly allowed channels/servers
- `dmPolicy: "pairing"` — DMs are open to anyone who messages the bot
- To restrict DMs: `openclaw config set channels.telegram.dmPolicy "allowlist"`
- `session.dmScope: "per-account-channel-peer"` — full session isolation (no context mixing between bots, channels, or users)
- `session.agentToAgent.maxPingPongTurns: 0` — prevents infinite AI-to-AI loops

## Final Config Structure

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "MAIN_BOT_TOKEN",
      "accounts": {
        "default": { "botToken": "MAIN_BOT_TOKEN", "dmPolicy": "pairing", "groupPolicy": "allowlist", "streamMode": "partial" },
        "commander": { "botToken": "TG_COMMANDER_TOKEN" },
        "strategist": { "botToken": "TG_STRATEGIST_TOKEN" },
        "engineer": { "botToken": "TG_ENGINEER_TOKEN" },
        "creator": { "botToken": "TG_CREATOR_TOKEN" },
        "thinktank": { "botToken": "TG_THINKTANK_TOKEN" }
      }
    },
    "discord": {
      "enabled": true,
      "accounts": {
        "commander": { "token": "DISCORD_COMMANDER_TOKEN", "groupPolicy": "allowlist", "guilds": { "GUILD_ID": { "channels": { "CHANNEL_ID": { "allow": true, "requireMention": false } } } } },
        "strategist": { "token": "DISCORD_STRATEGIST_TOKEN", "groupPolicy": "allowlist", "guilds": { "GUILD_ID": { "channels": { "CHANNEL_ID": { "allow": true, "requireMention": true } } } } },
        "engineer": { "token": "DISCORD_ENGINEER_TOKEN", "groupPolicy": "allowlist", "guilds": { "GUILD_ID": { "channels": { "CHANNEL_ID": { "allow": true, "requireMention": true } } } } },
        "creator": { "token": "DISCORD_CREATOR_TOKEN", "groupPolicy": "allowlist", "guilds": { "GUILD_ID": { "channels": { "CHANNEL_ID": { "allow": true, "requireMention": true } } } } },
        "thinktank": { "token": "DISCORD_THINKTANK_TOKEN", "groupPolicy": "allowlist", "guilds": { "GUILD_ID": { "channels": { "CHANNEL_ID": { "allow": true, "requireMention": true } } } } }
      }
    }
  },
  "agents": {
    "list": [
      { "id": "main" },
      { "id": "commander", "workspace": "~/.openclaw/workspace-commander", "groupChat": { "mentionPatterns": ["@Commander", "@commander"] } },
      { "id": "strategist", "workspace": "~/.openclaw/workspace-strategist", "groupChat": { "mentionPatterns": ["@Strategist", "@strategist"] } },
      { "id": "engineer", "workspace": "~/.openclaw/workspace-engineer", "groupChat": { "mentionPatterns": ["@Engineer", "@engineer"] } },
      { "id": "creator", "workspace": "~/.openclaw/workspace-creator", "groupChat": { "mentionPatterns": ["@Creator", "@creator"] } },
      { "id": "thinktank", "workspace": "~/.openclaw/workspace-thinktank", "groupChat": { "mentionPatterns": ["@ThinkTank", "@thinktank", "@Think Tank"] } }
    ]
  },
  "bindings": [
    { "agentId": "main", "match": { "channel": "telegram", "accountId": "default" } },
    { "agentId": "commander", "match": { "channel": "telegram", "accountId": "commander" } },
    { "agentId": "strategist", "match": { "channel": "telegram", "accountId": "strategist" } },
    { "agentId": "engineer", "match": { "channel": "telegram", "accountId": "engineer" } },
    { "agentId": "creator", "match": { "channel": "telegram", "accountId": "creator" } },
    { "agentId": "thinktank", "match": { "channel": "telegram", "accountId": "thinktank" } },
    { "agentId": "commander", "match": { "channel": "discord", "accountId": "commander" } },
    { "agentId": "strategist", "match": { "channel": "discord", "accountId": "strategist" } },
    { "agentId": "engineer", "match": { "channel": "discord", "accountId": "engineer" } },
    { "agentId": "creator", "match": { "channel": "discord", "accountId": "creator" } },
    { "agentId": "thinktank", "match": { "channel": "discord", "accountId": "thinktank" } }
  ],
  "session": {
    "dmScope": "per-account-channel-peer",
    "agentToAgent": { "maxPingPongTurns": 0 }
  },
  "plugins": {
    "entries": {
      "discord": { "enabled": true }
    }
  }
}
```

---

# Slack Multi-Agent Setup

## Per Bot App (repeat for each agent)

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click **Create New App** > **From scratch**
3. App Name: e.g. "Commander"
4. Pick your workspace > **Create App**

### 2. Enable Socket Mode + Get App Token

1. Left sidebar > **Socket Mode** > toggle **ON**
2. Create App-Level Token:
   - Name: `socket`
   - Scope: `connections:write`
   - Click **Generate**
3. Copy the `xapp-...` token — this is your `appToken`

### 3. Add Bot Token Scopes

Left sidebar > **OAuth & Permissions** > scroll to **Bot Token Scopes** > add ALL:

- `chat:write`
- `channels:read`
- `channels:history`
- `groups:read`
- `groups:history`
- `im:read`
- `im:history`
- `im:write`
- `users:read`

### 4. Enable Event Subscriptions

1. Left sidebar > **Event Subscriptions** > toggle **ON**
2. Under **Subscribe to bot events**, add:
   - `message.channels`
   - `message.groups`
   - `message.im`
3. Click **Save Changes**

### 5. Enable DMs (App Home)

1. Left sidebar > **App Home**
2. Scroll to **Show Tabs**
3. Check **"Allow users to send Slash commands and messages from the messages tab"**
4. Save

### 6. Install App to Workspace

1. Left sidebar > **OAuth & Permissions**
2. Click **Install to Workspace** (or **Reinstall** if updating scopes)
3. Authorize
4. Copy the `xoxb-...` token — this is your `botToken`

### 7. Invite Bot to Channel

In Slack channel type: `/invite @BotName`

## OpenClaw Slack Config

### 8. Enable Slack Plugin

```bash
jq '.plugins.entries.slack = {"enabled": true}' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

### 9. Add Bot Tokens

```bash
openclaw config set channels.slack.enabled true && \
openclaw config set channels.slack.accounts.commander.botToken "xoxb-COMMANDER" && \
openclaw config set channels.slack.accounts.commander.appToken "xapp-COMMANDER" && \
openclaw config set channels.slack.accounts.strategist.botToken "xoxb-STRATEGIST" && \
openclaw config set channels.slack.accounts.strategist.appToken "xapp-STRATEGIST" && \
openclaw config set channels.slack.accounts.engineer.botToken "xoxb-ENGINEER" && \
openclaw config set channels.slack.accounts.engineer.appToken "xapp-ENGINEER" && \
openclaw config set channels.slack.accounts.creator.botToken "xoxb-CREATOR" && \
openclaw config set channels.slack.accounts.creator.appToken "xapp-CREATOR" && \
openclaw config set channels.slack.accounts.thinktank.botToken "xoxb-THINKTANK" && \
openclaw config set channels.slack.accounts.thinktank.appToken "xapp-THINKTANK"
```

### 10. Disable Streaming (required)

Native streaming causes `missing_recipient_team_id` error.

```bash
jq '
  .channels.slack.accounts.commander.streaming = false |
  .channels.slack.accounts.strategist.streaming = false |
  .channels.slack.accounts.engineer.streaming = false |
  .channels.slack.accounts.creator.streaming = false |
  .channels.slack.accounts.thinktank.streaming = false
' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

### 11. Set Channel Allowlist + requireMention

Get your Slack Channel ID: right-click channel > **View channel details** > scroll to bottom > copy Channel ID.

Commander listens to everything. Others only respond when @mentioned.

> **IMPORTANT:** `requireMention` must be on the **channel config**, not the account level. Setting it only on the account does NOT work.

```bash
jq '
  .channels.slack.accounts.commander.groupPolicy = "allowlist" |
  .channels.slack.accounts.commander.channels."CHANNEL_ID" = {"allow":true,"requireMention":false} |
  .channels.slack.accounts.strategist.groupPolicy = "allowlist" |
  .channels.slack.accounts.strategist.channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.slack.accounts.engineer.groupPolicy = "allowlist" |
  .channels.slack.accounts.engineer.channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.slack.accounts.creator.groupPolicy = "allowlist" |
  .channels.slack.accounts.creator.channels."CHANNEL_ID" = {"allow":true,"requireMention":true} |
  .channels.slack.accounts.thinktank.groupPolicy = "allowlist" |
  .channels.slack.accounts.thinktank.channels."CHANNEL_ID" = {"allow":true,"requireMention":true}
' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

### 12. Add Bindings

```bash
jq '.bindings += [
  {"agentId":"commander","match":{"channel":"slack","accountId":"commander"}},
  {"agentId":"strategist","match":{"channel":"slack","accountId":"strategist"}},
  {"agentId":"engineer","match":{"channel":"slack","accountId":"engineer"}},
  {"agentId":"creator","match":{"channel":"slack","accountId":"creator"}},
  {"agentId":"thinktank","match":{"channel":"slack","accountId":"thinktank"}}
]' ~/.openclaw/openclaw.json | sponge ~/.openclaw/openclaw.json
```

### 13. Restart and Verify

```bash
openclaw gateway restart
```

```bash
openclaw status --all
```

Should show: `Slack ON OK tokens ok accounts 5/5`

## Slack Behavior

- **Channel messages**: Commander responds to everything (global listener), others only when @mentioned
- **Replies are in threads**: Slack default — keeps channel clean
- **DMs**: Each bot can be DMed directly for private 1-on-1 conversations

## Slack Common Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `missing_scope` error in logs | Bot missing OAuth scopes | Add all 9 scopes in step 3, then **Reinstall** app |
| `no-mention` skipping even with `requireMention: false` | `requireMention` set on account level only | Must set on **channel config** level (step 11) |
| Bot receives messages but doesn't respond | Streaming error `missing_recipient_team_id` | Set `streaming: false` per account (step 10) |
| "Sending messages to this app has been turned off" in DMs | DMs not enabled in app settings | App Home > enable "Allow users to send messages" (step 5) |
| No message events received at all | Event Subscriptions not configured | Enable events + subscribe to `message.channels`, `message.groups`, `message.im` (step 4) |
| Channel messages ignored even with allowlist | Channel ID not added to account config | Add channel with `allow: true` to account channels (step 11) |
| Scopes added but still failing | App not reinstalled after scope changes | Must click **Reinstall to Workspace** after any scope change |

## Slack Developer Portal Checklist

For each bot app, make sure ALL of these are done:

- [ ] Socket Mode: ON
- [ ] App-Level Token created with `connections:write`
- [ ] All 9 Bot Token Scopes added
- [ ] Event Subscriptions: ON
- [ ] Bot events: `message.channels`, `message.groups`, `message.im`
- [ ] App Home: "Allow users to send Slash commands and messages" checked
- [ ] App installed/reinstalled to workspace
- [ ] Bot invited to channel with `/invite @BotName`
