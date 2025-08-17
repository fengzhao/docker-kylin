
#!/bin/bash

# This script builds a Docker image from a custom Debian-based Linux distro ISO.

set -e

# Check if the script is being run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
    exit 1
fi

# Find the ISO file
ISO_FILE=$(find iso -name "*.iso" -type f | head -n 1)

# Check if an ISO file was found
if [ -z "$ISO_FILE" ]; then
    echo "Error: No ISO file found in the iso directory."
    exit 1
fi

# Extract branch and architecture from the ISO filename
FILENAME=$(basename -- "$ISO_FILE")
BRANCH=$(echo "$FILENAME" | grep -o -E '(server|desktop)' | head -n 1)
ARCH=$(echo "$FILENAME" | grep -o -E '(amd64|arm64)' | head -n 1)

# Check if branch and architecture were found
if [ -z "$BRANCH" ] || [ -z "$ARCH" ]; then
    echo "Error: Could not determine branch and architecture from the ISO filename."
    exit 1
fi

# Set the mount point for the ISO.
MOUNT_POINT="/mnt/iso"

# Set the directory to extract the root filesystem to.
ROOTFS_DIR="/tmp/rootfs"

# Clean up function
cleanup() {
    echo "Cleaning up..."
    if mountpoint -q -- "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT"
    fi
    rm -rf "$ROOTFS_DIR"
}

# Trap errors and call the cleanup function
trap cleanup EXIT

# Create the mount point and rootfs directory if they don't exist.
mkdir -p "$MOUNT_POINT"
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

# Mount the ISO.
echo "Mounting the ISO..."
sudo mount -o loop "$ISO_FILE" "$MOUNT_POINT" || { echo "Error: Failed to mount the ISO."; exit 1; }

# Copy the root filesystem from the ISO.
# This assumes the root filesystem is on the mounted ISO.
# The exact path may vary depending on the ISO structure.
echo "Copying the root filesystem..."
rsync -a --exclude='.disk' "$MOUNT_POINT/" "$ROOTFS_DIR/" || { echo "Error: Failed to copy the root filesystem."; exit 1; }

# Unmount the ISO.
echo "Unmounting the ISO..."
sudo umount "$MOUNT_POINT" || { echo "Error: Failed to unmount the ISO."; exit 1; }

# Build the Docker image.
IMAGE_TAG="triatk/kylin:${BRANCH}-${ARCH}"
echo "Building the Docker image with tag: $IMAGE_TAG"
echo "$IMAGE_TAG" > image_tag.txt
docker build -t "$IMAGE_TAG" "$ROOTFS_DIR" || { echo "Error: Failed to build the Docker image."; exit 1; }

echo "Docker image built successfully!"
