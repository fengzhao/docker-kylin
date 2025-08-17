
#!/bin/bash

# This script builds a Docker image from a custom Debian-based Linux distro ISO.

set -e

# Set the ISO file path.
ISO_FILE="iso/custom-distro.iso"

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

# Check if the ISO file exists.
if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    exit 1
fi

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
echo "Building the Docker image..."
docker build -t custom-distro:latest "$ROOTFS_DIR" || { echo "Error: Failed to build the Docker image."; exit 1; }

echo "Docker image built successfully!"
