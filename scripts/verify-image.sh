
#!/bin/bash

# This script verifies a Docker image.

set -e

IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
    echo "Usage: $0 <image_tag>"
    exit 1
fi

echo "Verifying Docker image: $IMAGE_TAG"

# Extract architecture from the image tag
ARCH=$(echo "$IMAGE_TAG" | awk -F'[-:]' '{print $3}')

# Set platform flag if architecture is arm64
PLATFORM_FLAG=""
if [ "$ARCH" == "arm64" ]; then
    PLATFORM_FLAG="--platform linux/arm64"
fi

# Run a simple command inside the container to verify basic functionality
docker run --rm $PLATFORM_FLAG "$IMAGE_TAG" /bin/sh -c "ls / && cat /etc/os-release"

if [ $? -eq 0 ]; then
    echo "Image verification successful for $IMAGE_TAG"
    exit 0
else
    echo "Image verification failed for $IMAGE_TAG"
    exit 1
fi
