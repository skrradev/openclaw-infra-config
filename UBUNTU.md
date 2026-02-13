# Ubuntu Setup

## 1. Install Ansible

To install Ansible on Ubuntu, run the following commands:

```bash

sudo apt update


sudo apt install software-properties-common -y


sudo add-apt-repository --yes --update ppa:ansible/ansible


sudo apt install ansible -y
```

## Verify Installation

Check the installed version:

```bash
ansible --version
```

## 2. Clone OpenClaw Ansible

Clone the repository to your local machine:

```bash
git clone https://github.com/skrradev/openclaw-ansible
```

Navigate into the directory:

```bash
cd openclaw-ansible
```

## 3. Run the Playbook

Finally, execute the Ansible playbook to configure the system. You will be prompted for your sudo password:

```bash
ansible-playbook playbook-linux.yml --ask-become-pass
```

> [!NOTE]
> The `--ask-become-pass` (or `-K`) flag ensures that Ansible asks for your privilege escalation password so it can run commands with `sudo` during the configuration process.

## 4. Post-Install

After installation completes, switch to the `openclaw` user:

```bash
sudo su - openclaw
```

Then run the quick-start onboarding wizard:

```bash
openclaw onboard --install-daemon
```

This will:
*   Guide you through the setup wizard
*   Configure your messaging provider (WhatsApp/Telegram/Signal)
*   Install and start the daemon service

## Alternative Manual Setup

If you prefer to configure components manually:

```bash
# Configure manually
openclaw configure

# Login to provider
openclaw providers login

# Test gateway
openclaw gateway

# Install as daemon
openclaw daemon install
openclaw daemon start

# Check status
openclaw status
openclaw logs
```
