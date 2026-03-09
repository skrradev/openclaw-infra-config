# OpenClaw Backup and Restore

## Creating a Backup

```bash
openclaw backup create                        # Full backup
openclaw backup create --only-config          # Config files only
openclaw backup create --no-include-workspace # Skip workspace dirs
openclaw backup create --dry-run              # Preview what gets included
```

### What gets backed up

| Category | Contents |
|----------|----------|
| **Config** | `openclaw.json`, agent configs |
| **Credentials** | `~/.openclaw/credentials/` |
| **State** | `~/.openclaw/state/` (sessions, cron state) |
| **Workspaces** | All agent workspace directories (`SOUL.md`, `AGENTS.md`, etc.) |

### Archive format

- Output: `.tar.gz` file with a `manifest.json` embedded inside
- The manifest records every file path, size, and checksum
- Saved to `~/.openclaw/backups/` by default
- Filename: `openclaw-backup-YYYY-MM-DDTHH-MM-SS.tar.gz`
- Atomic writes — archive is written to a temp file first, then hard-link published to the final path (prevents corrupt partial archives if the process dies mid-write)

## Verifying a Backup

```bash
openclaw backup verify <path-to-archive>
```

This checks:

1. Archive schema validity
2. Manifest-to-archive file consistency (all listed files exist)
3. Path traversal protection (no `../` escapes)

## Manual Restore

There is no built-in `openclaw backup restore` command yet — only `create` and `verify`. Restoring is manual.

### 1. Stop the gateway

```bash
# Linux
systemctl --user stop openclaw-gateway

# macOS
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### 2. Extract the archive

```bash
# List contents without extracting
tar tzf openclaw-backup-*.tar.gz

# Extract to a temp directory to inspect
mkdir /tmp/openclaw-restore
tar xzf openclaw-backup-*.tar.gz -C /tmp/openclaw-restore
```

### 3. Copy back what you need

```bash
# Full restore — overwrites everything
cp -a /tmp/openclaw-restore/config/* ~/.openclaw/
cp -a /tmp/openclaw-restore/credentials/* ~/.openclaw/credentials/
cp -a /tmp/openclaw-restore/state/* ~/.openclaw/state/

# Or just config (most common)
cp /tmp/openclaw-restore/config/openclaw.json ~/.openclaw/openclaw.json
```

### 4. Restart

```bash
# Linux
systemctl --user start openclaw-gateway

# macOS
launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

## Pre-Update Backup

Good practice before any OpenClaw update:

```bash
# As the openclaw user on a server
sudo -u openclaw bash -lc 'openclaw backup create --only-config'
```

If an update goes sideways, restore config and restart.

## Config Auto-Backup

OpenClaw also maintains automatic `.bak` rotation files every time `openclaw.json` is written. This is a separate system from `backup create` — it's automatic and only covers the config file, not credentials or state.
