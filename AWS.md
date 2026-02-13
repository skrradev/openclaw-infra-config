# AWS EC2 Provisioning Guide

Deploy an Ubuntu 24.04 EC2 instance using the CloudFormation template (`ec2.yml`).

## Prerequisites

Set your target region:

```bash
export AWS_REGION="eu-central-1"
```

---

## 1. Create Key Pair

```bash
# List existing key pairs
aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[*].KeyName' --output table

# Create a new key pair (skip if ec2-key already exists)
aws ec2 create-key-pair \
  --key-name ec2-key \
  --key-type ed25519 \
  --region $AWS_REGION \
  --query 'KeyMaterial' \
  --output text > ec2-key.pem

chmod 400 ec2-key.pem
```

---

## 2. Download CloudFormation Templates

```bash
curl -H "Authorization: token $PAT_TOKEN" \
  -H "Accept: application/vnd.github.raw" \
  -o vpc.yml \
  https://api.github.com/repos/skrradev/openclaw-infra-config/contents/vpc.yml

curl -H "Authorization: token $PAT_TOKEN" \
  -H "Accept: application/vnd.github.raw" \
  -o ec2.yml \
  https://api.github.com/repos/skrradev/openclaw-infra-config/contents/ec2.yml
```

---

## 3. Deploy VPC Stack

```bash
aws cloudformation deploy \
  --template-file vpc.yml \
  --stack-name fastclaws-vpc \
  --region $AWS_REGION
```

---

## 4. Deploy EC2 Stack

With defaults (ec2-key, t3.medium, 8GB):

```bash
aws cloudformation deploy \
  --template-file ec2.yml \
  --stack-name my-server \
  --region $AWS_REGION
```

With custom parameters:

```bash
aws cloudformation deploy \
  --template-file ec2.yml \
  --stack-name my-server \
  --region $AWS_REGION \
  --parameter-overrides \
    KeyName=my-other-key \
    InstanceType=t3.large \
    VolumeSize=20 \
    InstanceName=dev-server
```

---

## 5. Get Outputs

```bash
# Show instance ID, public IP, and SSH command
aws cloudformation describe-stacks \
  --stack-name my-server \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs' \
  --output table
```

---

## 6. Connect via SSH

```bash
ssh -i ec2-key.pem ubuntu@<PublicIP>
```

---

## 7. Tear Down

```bash
aws cloudformation delete-stack --stack-name my-server --region $AWS_REGION
aws cloudformation delete-stack --stack-name fastclaws-vpc --region $AWS_REGION
```
