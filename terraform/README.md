# HotelBooking Infrastructure (Terraform + Docker)

This project uses [Terraform](https://www.terraform.io/) for infrastructure as code, and [Docker](https://www.docker.com/) to provide a consistent environment for running Terraform commands.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your machine
- AWS credentials configured in `~/.aws/credentials` (for AWS resource management)

## Setup

### 1. Build the Docker Image

From the project root (where [Dockerfile](cci:7://file:///Users/rbraving/my-projects/HotelBooking/Dockerfile:0:0-0:0) is located):

```sh
podman build -t terraform-stripe-sync-srvice:latest .
```
    
### 2. Make the Terraform Helper Script Executable

```sh
chmod +x terraform.sh
``` 

## Creating the S3 Bucket and DynamoDB Table for Terraform State

Before you can use Terraform with remote state and state locking, you must create the S3 bucket and DynamoDB table in your AWS account.

### 1. Create the S3 Bucket

Replace the region and bucket name as needed:

```sh
aws s3api create-bucket \
  --bucket stripe-sync-service-terraform-state \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2 \
  --profile my-personal
```

### 2. Create the DynamoDB Table for State Locking
```
aws dynamodb create-table \
  --table-name stripe-sync-service-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2 \
  --profile my-personal
```
- The S3 bucket will store your Terraform state file.
- The DynamoDB table will be used for state locking to prevent concurrent operations.

Note:
You only need to run these commands once per AWS account/project.

## Usage
All Terraform commands should be run via the helper script to ensure a consistent environment.

From the project root, run:


```sh
./terraform.sh init          # Initialize Terraform
./terraform.sh plan          # Show execution plan
./terraform.sh apply         # Apply changes
./terraform.sh apply -var-file=secrets.tfvars   # Apply changes with secrets
./terraform.sh destroy       # Destroy resources
./terraform.sh destroy -var-file=secrets.tfvars   # Destroy resources with secrets

```

- The script mounts your terraform/ directory and your AWS credentials into the Docker container.
- You can pass any Terraform command/argument to the script.

## Viewing Sensitive Outputs

To display the Cognito App Client secret (after running `apply`):

```sh
terraform output app_client_secret
```

## Push Docker Image to ECR using Podman and my-personal profile
Once you have created the ECR resource by terraform, you need to push the docker image into the ECR. We have two methods for this:

### Method 1: Use push-to-ecr.sh
This is the easiest way. Run the following command:
```sh
./push-to-ecr.sh
```
Don't forget to make it executable first:
```sh
chmod +x push-to-ecr.sh
```


### Method 2: Push image using Terminal
### Step 1: Authenticate Podman with ECR
Run the following command to log in to ECR:
```sh
aws ecr get-login-password --profile my-personal | podman login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
```

### Step 2: Build your image with Podman
From your project root:

```sh
podman build --arch amd64 -t stripe-sync-service .
```

### Step 3: Tag your image
ECR requires full registry URL format:
```sh
podman tag stripe-sync-service:latest 038933440787.dkr.ecr.us-west-2.amazonaws.com/stripe-sync-service:latest
```

### Step 4: Push your image to ECR
```sh
podman push 038933440787.dkr.ecr.us-west-2.amazonaws.com/stripe-sync-service:latest
```

## Store Environment Variables in SSM Parameter Store

To store environment variables in SSM Parameter Store, run the following command:

```sh
aws ssm put-parameter \
  --name "STRIPE_API_KEY" \
  --value "sk_test_F8nt3R5eMaNTYHlJd3E4CtDr" \
  --type "SecureString" \
  --overwrite \
  --profile my-personal \
  --region us-west-2
```

```sh
aws ssm put-parameter \
  --name "STRIPE_WEBHOOK_SECRET" \
  --value "whsec_ff919e703c3189ee165fff06628f5f56c24d8420e7c3c08d6f0eb4e818cc7ff0" \
  --type "SecureString" \
  --overwrite \
  --profile my-personal \
  --region us-west-2
```

## Running Alembic Migrations on ECS

To run Alembic migrations on ECS, run the following command:

```sh
aws ecs run-task \
  --cluster stripe-sync-cluster \
  --task-definition stripe-sync-task \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxx,subnet-yyyy],securityGroups=[sg-zzzz],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"stripe-sync","command":["alembic","upgrade","head"]}]}' \
  --profile my-personal
```

## Retrieve Stripe Webhook Secret from Stripe Webhook Endpoint

Once you know the ALB DNS name, you need to register it with Stripe. 
Then, You can retrieve the Stripe webhook secret from the Stripe console.
Then, you need to store it back in SSM Parameter Store.
Then, on ECS service, you need to update the deployment with the new Stripe webhook secret. 
We wouldn't have to do this if we would have a fixed domain name.
