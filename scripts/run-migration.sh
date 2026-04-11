#!/bin/sh

# 1. Validate arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <project-name> <source-version>"
    exit 1
fi

PROJECT_NAME="$1"
SOURCE_VERSION="$2"

echo "Starting CodeBuild project: $PROJECT_NAME"
echo "Source Version: $SOURCE_VERSION"

# 2. Trigger the Build
# We use backticks or $( ) which are POSIX standard
BUILD_ID=$(aws codebuild start-build \
    --project-name "$PROJECT_NAME" \
    --source-version "$SOURCE_VERSION" \
    --query 'build.id' \
    --output text)

if [ -z "$BUILD_ID" ]; then
    echo "Error: Failed to start CodeBuild project."
    exit 1
fi

echo "Build ID: $BUILD_ID"
echo "Monitoring migration status..."

# 3. Poll for results
# Using a simple counter for a 10-minute timeout
MAX_RETRIES=60
COUNT=0

while [ "$COUNT" -lt "$MAX_RETRIES" ]; do
    # Fetch status
    STATUS=$(aws codebuild batch-get-builds --ids "$BUILD_ID" --query 'builds[0].buildStatus' --output text)
    
    echo "Current Status: $STATUS"

    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Migration completed successfully!"
        exit 0
    fi

    # Standard POSIX case matching for failure states
    case "$STATUS" in 
        FAILED|STOPPED|FAULT|TIMED_OUT)
            echo "Migration failed with status: $STATUS"
            exit 1
            ;;
    esac

    # Wait 30 seconds
    sleep 30
    COUNT=$(expr "$COUNT" + 1)
done

echo "Error: Migration timed out after 10 minutes."
exit 1