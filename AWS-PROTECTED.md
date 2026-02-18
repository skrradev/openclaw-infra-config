# AWS Protected EC2 Provisioning Guide

Deploy an Ubuntu 24.04 EC2 instance into a dedicated VPC with egress-only networking and restrictive NACLs.

> **For enterprise/production use** with private subnets and NAT Gateway, see [AWS-ENTERPRISE.md](AWS-ENTERPRISE.md).

## Prerequisites

Set your target region:

```bash
export AWS_REGION="eu-central-1"
```

Ensure an EC2 key pair exists in your region. The EC2 template defaults to `ec2-key`. Create one if it doesn't exist:

```bash
aws ec2 create-key-pair --key-name ec2-key --region $AWS_REGION \
  --query 'KeyMaterial' --output text > ec2-key.pem
chmod 400 ec2-key.pem
```

To use a different key name, pass `KeyName=your-key` when deploying the EC2 stack in step 3.

---

## 1. Clone Infrastructure Repo

```bash
git clone https://github.com/skrradev/openclaw-infra-config.git
cd openclaw-infra-config
```

---

## 2. Deploy VPC Stack

```bash
aws cloudformation deploy \
  --template-file vpc.yml \
  --stack-name fastclaws-vpc \
  --region $AWS_REGION
```

With direct Tailscale peer-to-peer (opens inbound UDP 41641):

```bash
aws cloudformation deploy \
  --template-file vpc.yml \
  --stack-name fastclaws-vpc \
  --region $AWS_REGION \
  --parameter-overrides EnableTailscaleDirect=true
```

---

## 3. Deploy EC2 Stack

```bash
VPC_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-vpc --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
SUBNET_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-vpc --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue' --output text)
SG_ID=$(aws cloudformation describe-stacks --stack-name fastclaws-vpc --region $AWS_REGION \
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
  --stack-name my-server \
  --region $AWS_REGION \
  --query 'Stacks[0].Outputs' \
  --output table
```

---

## 5. Connect via SSM

```bash
INSTANCE_ID=$(aws cloudformation describe-stacks --stack-name my-server --region $AWS_REGION \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' --output text)

aws ssm start-session --target $INSTANCE_ID --region $AWS_REGION
```

---

## 6. Tear Down

```bash
aws cloudformation delete-stack --stack-name my-server --region $AWS_REGION
aws cloudformation wait stack-delete-complete --stack-name my-server --region $AWS_REGION
aws cloudformation delete-stack --stack-name fastclaws-vpc --region $AWS_REGION
```
