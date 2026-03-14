#!/bin/bash
set -e  # This tells the script to STOP immediately if any command fails

# 1. Variables (Match these to your terraform variables)
REGION="us-east-1"
APP_NAME="tanstack-starter" # Match var.app_name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${APP_NAME}"

# 2. Authenticate Docker to AWS ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

# 3. Build the Docker Image
echo "🏗️ Building Docker image..."
docker build -t $APP_NAME .

# 4. Tag the image for ECR
echo "🏷️ Tagging image..."
docker tag $APP_NAME:latest $ECR_URL:latest

# 5. Push to AWS
echo "🚀 Pushing to ECR..."
docker push $ECR_URL:latest

echo "✅ Done! Your code is now in AWS."