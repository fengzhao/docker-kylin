
#!/bin/bash

# This script builds a Docker image from a custom Debian-based Linux distro ISO.

set -e

# Check if the script is being run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
    exit 1
fi

# Find all ISO files
ISO_FILES=$(find iso -name "*.iso" -type f)

# Check if any ISO files were found
if [ -z "$ISO_FILES" ]; then
    echo "Error: No ISO files found in the iso directory."
    exit 1
fi

# Create a file to store the image tags
IMAGE_TAGS_FILE="image_tags.txt"
> "$IMAGE_TAGS_FILE"

# Loop through each ISO file
for ISO_FILE in $ISO_FILES; do
    echo "Processing ISO file: $ISO_FILE"

    # Extract branch and architecture from the ISO filename
    FILENAME=$(basename -- "$ISO_FILE")
    BRANCH=$(echo "$FILENAME" | grep -o -E '(server|desktop)' | head -n 1)
    ARCH=$(echo "$FILENAME" | grep -o -E '(amd64|arm64)' | head -n 1)

    # Check if branch and architecture were found
    if [ -z "$BRANCH" ] || [ -z "$ARCH" ]; then
        echo "Warning: Could not determine branch and architecture from the ISO filename: $FILENAME. Skipping this file."
        continue
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
    IMAGE_PREFIX=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    IMAGE_TAG="${IMAGE_PREFIX}:${BRANCH}-${ARCH}"
    echo "Building the Docker image with tag: $IMAGE_TAG"
    docker build -t "$IMAGE_TAG" "$ROOTFS_DIR" || { echo "Error: Failed to build the Docker image."; exit 1; }

    # Save the image tag to the file
    echo "$IMAGE_TAG" >> "$IMAGE_TAGS_FILE"

    echo "Docker image built successfully!"

done
