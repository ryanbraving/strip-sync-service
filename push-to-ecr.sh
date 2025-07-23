#!/bin/bash

set -e

# === Config ===
AWS_PROFILE="my-personal"
AWS_REGION="us-west-2"
ACCOUNT_ID="038933440787"
REPO_NAME="stripe-sync-service"
IMAGE_TAG="latest"

# === Derived values ===
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}"

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | podman login --username AWS --password-stdin "$ECR_URL"

echo "Building image..."
podman build --arch amd64 -t "$REPO_NAME:$IMAGE_TAG" .

echo "Tagging image as $FULL_IMAGE_NAME..."
podman tag "$REPO_NAME:$IMAGE_TAG" "$FULL_IMAGE_NAME"

echo "Pushing image to ECR..."
podman push "$FULL_IMAGE_NAME"

echo "Done: $FULL_IMAGE_NAME"