# Ubuntu Setup

## 1. Clone OpenClaw Ansible

```bash
git clone https://github.com/skrradev/openclaw-ansible
cd openclaw-ansible
```

## 2. Install Ansible

```bash
sudo ./install-ansible.sh
```

Verify installation:

```bash
ansible --version
```

## 3. Run the Playbooks

Using `vars.yml` to pass variables:

```bash
ansible-playbook playbook-linux.yml -e @vars.yml
```

### Available Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `openclaw_user` | `openclaw` | System user name |
| `openclaw_home` | `/home/openclaw` (Linux) / `/Users/openclaw` (macOS) | User home directory |
| `openclaw_install_mode` | `release` | `release` or `development` |
| `openclaw_version` | `latest` | OpenClaw npm version for release mode |
| `openclaw_ssh_keys` | `[]` | List of SSH public keys |
| `admin_user` | `""` | Admin username — with `admin_ssh_keys`: creates user (bare metal); without: assumes existing (cloud) |
| `admin_ssh_keys` | `[]` | SSH public keys for `admin_user` (triggers user creation when non-empty) |
| `openclaw_repo_url` | `https://github.com/openclaw/openclaw.git` | Git repository (dev mode) |
| `openclaw_repo_branch` | `main` | Git branch (dev mode) |
| `openclaw_browser_enabled` | `true` (Linux) | Install Playwright Chromium for browser automation |
| `allow_ssh_cidrs` | `[]` | List of CIDRs allowed for SSH access (e.g. `["10.0.0.0/8"]`) |
| `tailscale_authkey` | `""` | Tailscale auth key for auto-connect |
| `nodejs_version` | `22.x` (Linux) / `22` (macOS) | Node.js version to install |
| `timezone` | `""` (Linux) | Linux timezone (fallback: `UTC`) |

### 3.1a Cloud (AWS/GCP) — existing `ubuntu` user

```bash
# Without Tailscale
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e timezone=Asia/Almaty

# With Tailscale auto-connect (get key: https://login.tailscale.com/admin/settings/keys)
ansible-playbook playbook-linux.yml \
  -e admin_user=ubuntu \
  -e timezone=Asia/Almaty \
  -e tailscale_authkey=<YOUR_KEY>
```

### 3.1b Hetzner, Digital Ocean

Create an SSH key pair beforehand (skip if you already have one):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/admin-key -C "admin"
chmod 400 ~/.ssh/admin-key
```

Use the public key (`~/.ssh/admin-key.pub`) in `admin_ssh_keys` below.

```bash
# Without Tailscale
ansible-playbook playbook-linux.yml \
  -e admin_user=admin \
  -e timezone=Europe/Berlin \
  -e admin_ssh_keys=["ssh-ed25519 AAAA... you@laptop"]

# With Tailscale auto-connect
ansible-playbook playbook-linux.yml \
  -e admin_user=admin \
  -e timezone=Europe/Berlin \
  -e admin_ssh_keys=["ssh-ed25519 AAAA... you@laptop"] \
  -e tailscale_authkey=<YOUR_KEY>
```

### 3.2 Post-Install Hardening

> On Hetzner or DO, when you first run as root, switch to the created admin user before hardening:
> ```bash
> sudo su - ubuntu
> ```

Using `vars.yml`:

```bash
ansible-playbook playbook-linux-ssh-strict.yml -e @vars.yml
```

Or with inline variables:

```bash
# Strict SSH (key-only, no root login) — requires admin_user
ansible-playbook playbook-linux-ssh-strict.yml \
  -e admin_user=ubuntu
```

> **Warning:** Before lockdown, make sure Tailscale is connected (`tailscale up`) — otherwise you may lose access to the server.

```bash
# Lock SSH to Tailscale only (run after `tailscale up`)
ansible-playbook playbook-linux-ssh-lockdown.yml
```

After lockdown, SSH to the server using the Tailscale IP and admin user.

## 4. Post-Install

Clean up the Ansible repo:

```bash
rm -rf openclaw-ansible/
```

Switch to the `openclaw` user:

```bash
sudo su - openclaw
```

Run the quick-start onboarding wizard:

```bash
openclaw onboard --install-daemon
```

This will:
- Guide you through the setup wizard
- Configure your messaging provider (WhatsApp/Telegram/Signal)
- Install and start the daemon service

### Alternative Manual Setup

If you prefer to configure components manually:

```bash
openclaw configure
openclaw providers login
openclaw gateway
openclaw daemon install
openclaw daemon start

# Check status
openclaw status
openclaw logs
```

## 5. Tailscale Serve Mode

Proxy HTTPS through your tailnet:

```bash
# Proxies HTTPS through your tailnet
openclaw config set gateway.tailscale.mode serve

# Gateway only listens on 127.0.0.1; Tailscale serve handles external access
openclaw config set gateway.bind loopback

# Clean up tailscale serve when gateway stops
openclaw config set gateway.tailscale.resetOnExit true

# Allow Tailscale-authenticated connections (no token needed from tailnet peers)
openclaw config set gateway.auth.allowTailscale true

# Allow restart
openclaw config set commands.restart true

# Restart to apply
openclaw gateway restart

```


## 6. Browser Settings

```bash
# Find the Playwright Chromium binary path
find ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome -type f 2>/dev/null

# Point OpenClaw to the Playwright Chromium binary instead of auto-detecting
# (auto-detect would find Snap Chromium, which fails from systemd services)
openclaw config set browser.executablePath $(find ~/.cache/ms-playwright/chromium-*/chrome-linux/chrome -type f | sort -V | tail -1)

# Enable browser automation features (web scraping, screenshots, etc.)
openclaw config set browser.enabled true

# Run Chrome without a visible window (no display needed on headless servers)
# Launches with --headless=new flag
openclaw config set browser.headless true

# Disable Chrome's sandbox (--no-sandbox --disable-setuid-sandbox)
# Required when running as a service user — Chrome's sandbox needs
# setuid helpers that systemd's security hardening (NoNewPrivileges) blocks
openclaw config set browser.noSandbox true
```

## 7. Device Management for Control UI

```bash
# See pending pairing requests
openclaw devices list

# Approve a request
openclaw devices approve <requestId>
```

## 8. Google Setup

### 8.1 Get OAuth2 Credentials

Create OAuth2 credentials from [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. [Create a project](https://console.cloud.google.com/projectcreate)
2. Enable the APIs you need:
   - [Gmail API](https://console.cloud.google.com/apis/api/gmail.googleapis.com)
   - [Google Calendar API](https://console.cloud.google.com/apis/api/calendar-json.googleapis.com)
   - [Google Chat API](https://console.cloud.google.com/apis/api/chat.googleapis.com)
   - [Google Drive API](https://console.cloud.google.com/apis/api/drive.googleapis.com)
   - [Google Classroom API](https://console.cloud.google.com/apis/api/classroom.googleapis.com)
   - [People API (Contacts)](https://console.cloud.google.com/apis/api/people.googleapis.com)
   - [Google Tasks API](https://console.cloud.google.com/apis/api/tasks.googleapis.com)
   - [Google Sheets API](https://console.cloud.google.com/apis/api/sheets.googleapis.com)
   - [Google Forms API](https://console.cloud.google.com/apis/api/forms.googleapis.com)
   - [Apps Script API](https://console.cloud.google.com/apis/api/script.googleapis.com)
   - [Cloud Identity API (Groups)](https://console.cloud.google.com/apis/api/cloudidentity.googleapis.com)
3. [Configure OAuth consent screen](https://console.cloud.google.com/auth/branding)
4. If your app is in "Testing", [add test users](https://console.cloud.google.com/auth/audience)
5. [Create OAuth client](https://console.cloud.google.com/auth/clients) — Application type: "Desktop app"
6. Download the JSON file (usually named `client_secret_....apps.googleusercontent.com.json`)

### 8.2 Store Credentials

```bash
gog auth credentials ~/Downloads/client_secret_....json
```

### 8.3 Add Account

Manual interactive flow (recommended):

```bash
gog auth add you@gmail.com --services user --manual
```

1. The CLI prints an auth URL — open it in a local browser
2. After approval, copy the full loopback redirect URL from the browser address bar
3. Paste that URL back into the terminal when prompted

> **Note:** Add `GOG_KEYRING_PASSWORD` to your `.env` file.
