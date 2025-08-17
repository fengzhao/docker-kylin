
#!/bin/bash

# This script cleans up old Docker images.

set -e

echo "Cleaning up old Docker images..."

# Remove dangling images (images not associated with any container)
docker image prune -f

# Remove images older than 7 days that are not tagged with 'latest'
docker images --filter "before=7d" --filter "dangling=false" --format "{{.ID}} {{.Tag}}" | while read IMAGE_ID IMAGE_TAG; do
    if [[ "$IMAGE_TAG" != *"latest"* ]]; then
        echo "Removing image: $IMAGE_ID ($IMAGE_TAG)"
        docker rmi "$IMAGE_ID" || true
    fi
done

echo "Docker image cleanup complete."
