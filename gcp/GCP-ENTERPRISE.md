# GCP Enterprise VM Provisioning Guide

Deploy an Ubuntu 24.04 Compute Engine instance into an enterprise VPC with a **private subnet** (no public IP) and **Cloud NAT** for outbound internet access.

> **Cost note:** Cloud NAT costs ~$32/month (hourly charge + data processing fees). Delete the infrastructure promptly when not in use.

## Prerequisites

Set your project and region:

```bash
export PROJECT_ID="my-gcp-project"
export REGION="europe-west1"
export ZONE="europe-west1-b"
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
cd openclaw-infra-config/gcp/enterprise
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
region     = "europe-west1"
zone       = "europe-west1-b"
```

> **Note:** Instances in the private subnet have no public IP, so Tailscale uses DERP relay servers for connectivity. The `enable_tailscale_direct` parameter from `protected/` is intentionally omitted here — direct peer-to-peer is impossible without a public IP.

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

Compute Engine instances in the private subnet have no public IP. Use IAP tunnel to connect:

```bash
gcloud compute ssh openclaw-server --zone=europe-west1-b --tunnel-through-iap
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
