# AWS Enterprise VPC Provisioning Guide

Deploy an Ubuntu 24.04 EC2 instance into an enterprise VPC with a **private subnet** (no public IPs) and a **NAT Gateway** for outbound internet access.

> **Cost note:** The NAT Gateway costs ~$32/month (hourly charge + data processing fees). Delete the stack promptly when not in use.

## Prerequisites

Set your target region:

```bash
export AWS_REGION="eu-central-1"
```

---

## 1. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config
```

---

## 2. Deploy Enterprise VPC Stack

```bash
aws cloudformation deploy \
  --template-file vpc-enterprise.yml \
  --stack-name fastclaws-enterprise-vpc \
  --region $AWS_REGION
```

> **Note:** Instances in the private subnet have no public IP, so Tailscale uses DERP relay servers for connectivity. The `EnableTailscaleDirect` parameter from `vpc.yml` is intentionally omitted here — direct peer-to-peer is impossible without a public IP.

---

## 3. Deploy EC2 Stack

The same `ec2-protected.yml` template works unchanged — the enterprise VPC outputs use the same keys.

```bash
VPC_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-enterprise-vpc --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
SUBNET_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-enterprise-vpc --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue' --output text)
SG_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-enterprise-vpc --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceSecurityGroupId`].OutputValue' --output text)

aws cloudformation deploy \
  --template-file ec2-protected.yml \
  --stack-name openclaw-server \
  --region $AWS_REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    VpcId=$VPC_ID \
    SubnetId=$SUBNET_ID \
    SecurityGroupId=$SG_ID
```

---

## 4. Get Outputs

```bash
aws cloudformation describe-stacks \
  --stack-name openclaw-server \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs' \
  --output table
```

---

## 5. Connect via SSM

EC2 instances in the private subnet have no public IP. Use SSM Session Manager to connect:

```bash
INSTANCE_ID=$(aws cloudformation describe-stacks --stack-name openclaw-server --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' --output text)

aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION
```

---

## 6. Tear Down

Delete both stacks (EC2 first, then VPC):

```bash
aws cloudformation delete-stack --stack-name openclaw-server --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name openclaw-server --region $AWS_REGION
aws cloudformation delete-stack --stack-name fastclaws-enterprise-vpc --region $AWS_REGION
```
