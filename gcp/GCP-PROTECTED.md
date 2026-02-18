# GCP Protected VM Provisioning Guide

Deploy an Ubuntu 24.04 Compute Engine instance into a VPC with egress-only networking and IAP tunnel access using the Terraform template (`protected/`).

> **For enterprise/production use** with private subnets and Cloud NAT, see [GCP-ENTERPRISE.md](GCP-ENTERPRISE.md).

## Prerequisites

Set your project and region:

```bash
export PROJECT_ID="my-gcp-project"
export REGION="us-central1"
export ZONE="us-central1-a"
```

Enable the IAP API in your project:

```bash
gcloud services enable iap.googleapis.com --project=$PROJECT_ID
```

GCP Cloud Shell has Terraform pre-installed. Otherwise, [install Terraform](https://developer.hashicorp.com/terraform/install).

---

## 1. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config/gcp/protected
```

---

## 2. Configure Variables

Copy and edit the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your project ID:

```hcl
project_id = "my-gcp-project"
region     = "us-central1"
zone       = "us-central1-a"
```

With direct Tailscale peer-to-peer (opens inbound UDP 41641):

```hcl
enable_tailscale_direct = true
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

## 5. Connect via IAP Tunnel

```bash
gcloud compute ssh openclaw-server --zone=us-central1-a --tunnel-through-iap
```

Or use the command from Terraform output:

```bash
eval "$(terraform output -raw iap_ssh_command)"
```

---

## 6. Tear Down

```bash
terraform destroy
```
