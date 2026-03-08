# OpenClaw + iMessage via BlueBubbles

BlueBubbles bridges iMessage to OpenClaw. It runs on a Mac (must be signed into an Apple ID with iMessage) and forwards messages to OpenClaw via a local webhook.

## Prerequisites

- Mac (Mini, Studio, etc.) signed into iMessage
- BlueBubbles server installed ([bluebubbles.app/install](https://bluebubbles.app/install) or [GitHub releases](https://github.com/BlueBubblesApp/bluebubbles-server/releases))
- OpenClaw installed and running on the same machine

## Part 1: BlueBubbles on Mac

### 1. Download and Install

1. Download the latest `.dmg` from [BlueBubbles releases](https://github.com/BlueBubblesApp/bluebubbles-server/releases)
2. In Finder, right-click the `.dmg` → **Open** (not double-click)
3. Drag BlueBubbles to Applications
4. Open Applications folder, right-click BlueBubbles → **Open** again
5. Click **Open** on the security warning

### 2. Grant Full Disk Access

`System Settings → Privacy & Security → Full Disk Access → + → select BlueBubbles → toggle ON`

Restart BlueBubbles after granting.

### 3. Configure BlueBubbles

When the setup wizard opens:

- **Firebase/GCP** → skip it
- **Proxy** → choose **LAN/Local** (no Cloudflare needed)
- **Password** → set a strong API password, save it — you'll need it for OpenClaw
- Note your server URL: `http://localhost:1234`

Make sure the server is running — you should see a green status indicator.

### 4. Add the OpenClaw Webhook (Critical)

This is the step most people miss. Without it, OpenClaw can send messages through BlueBubbles but will never receive incoming messages.

In BlueBubbles → **Settings → Webhooks → Add webhook:**

```
http://localhost:18789/bluebubbles-webhook?password=YOUR_BB_PASSWORD
```

- `18789` is the default OpenClaw gateway port
- The `?password=` parameter is required — OpenClaw rejects webhook requests without it
- The password must match what you set in `channels.bluebubbles.password`

Enable all event types (`new-message`, `updated-message`, etc.) and click **Save**.

Restart the BlueBubbles server from within the app.

### 5. Make BlueBubbles Always-On

- BlueBubbles **Settings → General → Start with macOS** → enable
- `System Settings → Energy → Prevent Mac from sleeping` → enable

## Part 2: Configure OpenClaw

Interactive wizard (walks you through it step by step):

```bash
openclaw onboard
```

Select BlueBubbles when prompted.

Or set values directly:

```bash
openclaw config set channels.bluebubbles.enabled true && \
openclaw config set channels.bluebubbles.serverUrl http://localhost:1234 && \
openclaw config set channels.bluebubbles.password YOUR_BB_PASSWORD && \
openclaw config set channels.bluebubbles.webhookPath /bluebubbles-webhook
```

```json
{
  "channels": {
    "bluebubbles": {
      "enabled": true,
      "serverUrl": "http://localhost:1234",
      "password": "YOUR_BB_PASSWORD",
      "webhookPath": "/bluebubbles-webhook"
    }
  }
}
```

Then restart the gateway:

```bash
openclaw gateway restart
```

## Part 3: First Message and Pairing

The first time someone messages you, OpenClaw sends a pairing code (because `dmPolicy` defaults to `pairing`).

1. From your iPhone, iMessage the Apple ID your Mac is signed into
2. OpenClaw sends back a **pairing code**
3. On the Mac, approve it:

```bash
openclaw pairing list bluebubbles
openclaw pairing approve bluebubbles <CODE>
```

> **Note:** Pairing codes expire after 1 hour — approve promptly.

## Part 4: Verify

```bash
# Check BlueBubbles channel is connected
openclaw channels status bluebubbles

# Check for any config issues
openclaw doctor
```

You should see the BlueBubbles channel as connected with the webhook listening.

## Private API (Optional)

Some features require enabling the Private API helper in BlueBubbles settings:

- Reactions
- Typing indicators
- Edit and unsend messages

Basic send/receive works without it.

## Troubleshooting

### No incoming messages?

1. Check that the webhook URL is saved in BlueBubbles (**Settings → Webhooks**) — it must include `?password=your-password`
2. Verify the gateway endpoint exists:

```bash
curl http://localhost:18789/bluebubbles-webhook
```

Should return `405 Method Not Allowed` (endpoint exists but only accepts POST).

3. Check gateway logs:

```bash
openclaw logs --follow | grep bluebubbles
```

### Group messages silently dropped?

If `groupPolicy` is `allowlist` (the default), all group messages are dropped unless senders are in `groupAllowFrom`.

Quick fix:

```bash
openclaw config set channels.bluebubbles.groupPolicy open
```

### Other issues

| Problem | Fix |
|---------|-----|
| BlueBubbles won't open | Right-click → Open, not double-click |
| No messages received | Check Full Disk Access is granted |
| Webhook not firing | Confirm password matches exactly in both BlueBubbles and OpenClaw config |
| Pairing code expired | Message again, a new code is generated |
| Gateway not reachable | Make sure `openclaw gateway` is running |
