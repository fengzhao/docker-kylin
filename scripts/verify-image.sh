
#!/bin/bash

# This script verifies a Docker image.

set -e

IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
    echo "Usage: $0 <image_tag>"
    exit 1
fi

echo "Verifying Docker image: $IMAGE_TAG"

# Run a simple command inside the container to verify basic functionality
docker run --rm "$IMAGE_TAG" /bin/sh -c "ls / && cat /etc/os-release"

if [ $? -eq 0 ]; then
    echo "Image verification successful for $IMAGE_TAG"
    exit 0
else
    echo "Image verification failed for $IMAGE_TAG"
    exit 1
fi
