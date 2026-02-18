# GCP Simple VM Provisioning Guide

Deploy an Ubuntu 24.04 Compute Engine instance with a public IP using the Terraform template (`simple/`).

## Prerequisites

Set your project and region:

```bash
export PROJECT_ID="my-gcp-project"
export REGION="us-central1"
export ZONE="us-central1-a"
```

GCP Cloud Shell has Terraform pre-installed. Otherwise, [install Terraform](https://developer.hashicorp.com/terraform/install).

---

## 1. Create SSH Key

```bash
# Create a new SSH key (skip if you already have one)
ssh-keygen -t ed25519 -f ~/.ssh/gcp-key -C "ubuntu"
chmod 400 ~/.ssh/gcp-key
```

You'll use the public key (`~/.ssh/gcp-key.pub`) in step 3.

---

## 2. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config/gcp/simple
```

---

## 3. Configure Variables

Copy and edit the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your project ID and SSH public key:

```hcl
project_id     = "my-gcp-project"
region         = "us-central1"
zone           = "us-central1-a"
ssh_public_key = "ssh-ed25519 AAAAC3... user@host"  # contents of ~/.ssh/gcp-key.pub
```

To restrict SSH access to your IP:

```hcl
ssh_cidr = "203.0.113.0/32"
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

## 6. Connect via SSH

```bash
ssh -i ~/.ssh/gcp-key ubuntu@$(terraform output -raw public_ip)
```

---

## 7. Tear Down

```bash
terraform destroy
```
