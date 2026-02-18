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

## 1. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config/gcp/simple
```

---

## 2. Configure Variables

Copy and edit the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your project ID and SSH public key:

```hcl
project_id     = "my-gcp-project"
region         = "us-central1"
zone           = "us-central1-a"
ssh_public_key = "ssh-ed25519 AAAAC3... user@host"
```

To restrict SSH access to your IP:

```hcl
ssh_cidr = "203.0.113.0/32"
```

---

## 3. Deploy

```bash
terraform init
terraform apply
```

---

## 4. Get Outputs

```bash
terraform output
```

---

## 5. Connect via SSH

```bash
ssh ubuntu@$(terraform output -raw public_ip)
```

---

## 6. Tear Down

```bash
terraform destroy
```
