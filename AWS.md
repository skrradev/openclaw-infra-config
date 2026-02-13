# AWS EC2 Provisioning Guide

This guide provides a step-by-step process for launching and connecting to an Ubuntu EC2 instance using the AWS CLI.

## Prerequisites

Set your target region:

```bash
# Define your target AWS region
export AWS_REGION="eu-central-1"
```

---

## 1. Manage Key Pairs

Check your existing key pairs:

```bash
# List names of all key pairs in the current region
aws ec2 describe-key-pairs --region $AWS_REGION --query 'KeyPairs[*].KeyName' --output table
```

Create a new SSH key pair:

```bash
# Create a new key pair and save the private key to a .pem file
aws ec2 create-key-pair \
  --key-name ec2-key \
  --key-type ed25519 \
  --region $AWS_REGION \
  --query 'KeyMaterial' \
  --output text > ec2-key.pem

# Set secure permissions (required for SSH)
chmod 400 ec2-key.pem
```

---

## 2. Identify Latest AMI

Find the latest Amazon Linux 2023 AMI ID:

```bash
# Query the official Amazon owners for the newest AL2023 image
AMI_ID=$(aws ec2 describe-images \
  --region $AWS_REGION \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

echo "Selected AMI ID: $AMI_ID"
```

---

## 3. Configure Security Group

Create a security group for SSH access:

```bash
# Create the security group
SG_ID=$(aws ec2 create-security-group \
  --group-name ec2-sg \
  --description "SSH access group" \
  --region $AWS_REGION \
  --query 'GroupId' \
  --output text)

# Authorize ingress traffic for SSH (Port 22)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION
```

---

## 4. Launch EC2 Instance

Provision the instance using the variables obtained above:

```bash
# Run the instance with a t3.medium type and 8GB EBS volume
INSTANCE_ID=$(aws ec2 run-instances \
  --region $AWS_REGION \
  --image-id $AMI_ID \
  --instance-type t3.medium \
  --key-name ec2-key \
  --security-group-ids $SG_ID \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-server}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched Instance ID: $INSTANCE_ID"
```

---

## 5. Connect via SSH

Wait for the instance to be ready and get its public IP:

```bash
# Wait until the instance reaches the 'running' state
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $AWS_REGION

# Retrieve the public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
  --region $AWS_REGION \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# Connect to the instance
ssh -i ec2-key.pem ec2-user@$PUBLIC_IP
```