
#!/bin/bash

# This script cleans up old Docker images.

set -e

echo "Cleaning up old Docker images..."

# Remove dangling images (images not associated with any container)
docker image prune -f

# Remove images older than 7 days
docker image prune -a -f --filter "until=168h"

echo "Docker image cleanup complete."
