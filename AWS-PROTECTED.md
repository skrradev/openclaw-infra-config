# AWS Protected EC2 Provisioning Guide

Deploy an Ubuntu 24.04 EC2 instance into a dedicated VPC with egress-only networking and restrictive NACLs.

## Prerequisites

Set your target region:

```bash
export AWS_REGION="eu-central-1"
```

---

## 1. Download CloudFormation Templates

```bash
curl -H "Authorization: token $PAT_TOKEN" \
  -H "Accept: application/vnd.github.raw" \
  -o vpc.yml \
  https://api.github.com/repos/skrradev/openclaw-infra-config/contents/vpc.yml

curl -H "Authorization: token $PAT_TOKEN" \
  -H "Accept: application/vnd.github.raw" \
  -o ec2-protected.yml \
  https://api.github.com/repos/skrradev/openclaw-infra-config/contents/ec2-protected.yml
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
  --stack-name my-server \
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
