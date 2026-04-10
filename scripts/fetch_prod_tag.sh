#!/bin/bash

# Define names based on your Terraform convention
CLUSTER_NAME="${APP_NAME}-cluster"
SERVICE_NAME="${APP_NAME}-service"


echo "Fetching current image tag for $SERVICE_NAME..."

# 1. Ask ECS for the current Task Definition ARN
# The || echo "None" ensures the script keeps running if the service doesn't exist yet
TASK_DEFINITION_ARN=$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --region "$AWS_REGION" \
    --query 'services[0].taskDefinition' \
    --output text 2>/dev/null || echo "None")

# 2. Check the result and extract the tag
if [ "$TASK_DEFINITION_ARN" == "None" ] || [ -z "$TASK_DEFINITION_ARN" ] || [ "$TASK_DEFINITION_ARN" == "null" ]; then
    echo "No active service found. Using fallback tag: latest"
    echo "export PROD_IMAGE_TAG=latest" >> "$BASH_ENV"
else
    # Get the full image string (e.g., 12345.dkr.ecr.us-east-1.amazonaws.com/repo:v1.0.0)
    FULL_IMAGE=$(aws ecs describe-task-definition \
        --task-definition "$TASK_DEFINITION_ARN" \
        --region "$AWS_REGION" \
        --query 'taskDefinition.containerDefinitions[0].image' \
        --output text)
    
    # Extract just the part after the ":"
    TAG=$(echo "$FULL_IMAGE" | cut -d':' -f2)
    
    echo "Found production tag: $TAG"
    echo "export PROD_IMAGE_TAG=$TAG" >> "$BASH_ENV"
fi