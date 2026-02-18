# GCP Protected VM Provisioning Guide

Deploy an Ubuntu 24.04 Compute Engine instance into a VPC with egress-only networking and IAP tunnel access using the Terraform template (`protected/`).

> **For enterprise/production use** with private subnets and Cloud NAT, see [GCP-ENTERPRISE.md](GCP-ENTERPRISE.md).

## Prerequisites

Set your project and region:

```bash
export PROJECT_ID="openclaw"
export REGION="us-central1"
export ZONE="us-central1-a"
```

Enable required APIs:

```bash
gcloud services enable compute.googleapis.com iap.googleapis.com --project=$PROJECT_ID
```

GCP Cloud Shell has Terraform pre-installed. Otherwise, [install Terraform](https://developer.hashicorp.com/terraform/install).

---

## 1. Create SSH Key

```bash
# Create a new SSH key (skip if you already have one)
ssh-keygen -t ed25519 -f ~/.ssh/gcp-key -C "ubuntu"
chmod 400 ~/.ssh/gcp-key
```

> **Note:** `gcloud compute ssh` auto-manages keys, but having your own key is useful for SSH access over Tailscale.

---

## 2. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config/gcp/protected
```

---

## 3. Configure Variables

Copy and edit the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your project ID:

```hcl
project_id = "openclaw"
region     = "us-central1"
zone       = "us-central1-a"
```

With direct Tailscale peer-to-peer (opens inbound UDP 41641):

```hcl
enable_tailscale_direct = true
```

---

## 4. Deploy

```bash
terraform init
terraform apply
```

---

## 5. Get Outputs

```bash
terraform output
```

---

## 6. Connect via IAP Tunnel

```bash
gcloud compute ssh openclaw-server --zone=us-central1-a --tunnel-through-iap
```

Or use the command from Terraform output:

```bash
eval "$(terraform output -raw iap_ssh_command)"
```

---

## 7. Tear Down

```bash
terraform destroy
```
