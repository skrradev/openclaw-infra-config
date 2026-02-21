# macOS Setup

## 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Verify installation:

```bash
brew --version
```

## 2. Install Node.js

```bash
brew install node@22
```

Add to PATH (if not automatic):

```bash
echo 'export PATH="/opt/homebrew/opt/node@22/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify:

```bash
node --version
npm --version
```

## 3. Install Docker

```bash
brew install --cask docker
```

Open Docker Desktop to complete setup:

```bash
open /Applications/Docker.app
```

Verify:

```bash
docker --version
```

## 4. Install Google Chrome

```bash
brew install --cask google-chrome
```

Or download from [google.com/chrome](https://www.google.com/chrome/).

## 5. Install Tailscale

```bash
brew install --cask tailscale
```

Open Tailscale and sign in:

```bash
open /Applications/Tailscale.app
```

Or install via the Mac App Store: [Tailscale on App Store](https://apps.apple.com/app/tailscale/id1475387142)

Verify:

```bash
tailscale status
```

## 6. Install OpenClaw

Latest version:

```bash
npm install -g openclaw
```

Specific version:

```bash
npm install -g openclaw@2026.2.17
```

Verify:

```bash
openclaw --version
```

Update to latest:

```bash
npm update -g openclaw
```
