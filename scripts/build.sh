#!/bin/bash

# This script builds a Docker image from a custom Debian-based Linux distro ISO.

set -e

# Global variables
MOUNT_POINT="/mnt/iso"
ROOTFS_DIR="/tmp/rootfs"
IMAGE_TAGS_FILE="image_tags.txt"

# Function to check for sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to clean up mount point and rootfs directory
cleanup() {
    echo "Cleaning up..."
    if mountpoint -q -- "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT"
    fi
    rm -rf "$ROOTFS_DIR"
}

# Function to find ISO files
find_isos() {
    local iso_files
    iso_files=$(find iso -name "*.iso" -type f)
    if [ -z "$iso_files" ]; then
        echo "Error: No ISO files found in the iso directory."
        exit 1
    fi
    echo "$iso_files"
}

# Function to extract branch and architecture from filename
extract_info() {
    local filename="$1"
    local branch
    local arch

    branch=$(echo "$filename" | grep -o -E '(server|desktop)' | head -n 1)
    arch=$(echo "$filename" | grep -o -E '(amd64|arm64|loongarch64|mips64el|sw64)' | head -n 1)

    if [ -z "$branch" ] || [ -z "$arch" ]; then
        echo "Warning: Could not determine branch and architecture from the ISO filename: $filename."
        return 1
    fi
    echo "$branch $arch"
}

# Function to mount ISO
mount_iso() {
    local iso_file="$1"
    echo "Mounting the ISO: $iso_file..."
    sudo mount -o loop "$iso_file" "$MOUNT_POINT" || { echo "Error: Failed to mount the ISO."; exit 1; }
}

# Function to copy root filesystem
copy_rootfs() {
    echo "Copying the root filesystem..."
    rsync -a --exclude='.disk' "$MOUNT_POINT/" "$ROOTFS_DIR/" || { echo "Error: Failed to copy the root filesystem."; exit 1; }
}

# Function to unmount ISO
unmount_iso() {
    echo "Unmounting the ISO..."
    sudo umount "$MOUNT_POINT" || { echo "Error: Failed to unmount the ISO."; exit 1; }
}

# Function to build Docker image
build_image() {
    local branch="$1"
    local arch="$2"
    local image_prefix=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    local image_tag="${image_prefix}:${branch}-${arch}"

    echo "Building the Docker image with tag: $image_tag"
    docker build -t "$image_tag" "$ROOTFS_DIR" || { echo "Error: Failed to build the Docker image."; exit 1; }
    echo "$image_tag" >> "$IMAGE_TAGS_FILE"
}

# Main script execution
check_sudo
trap cleanup EXIT

# Clear previous image tags
> "$IMAGE_TAGS_FILE"

# Create necessary directories
mkdir -p "$MOUNT_POINT"
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"

ISO_FILES=$(find_isos)

for ISO_FILE in $ISO_FILES; do
    echo "Processing ISO file: $ISO_FILE"

    FILENAME=$(basename -- "$ISO_FILE")
    INFO=$(extract_info "$FILENAME")

    if [ $? -ne 0 ]; then
        continue
    fi

    BRANCH=$(echo "$INFO" | awk '{print $1}')
    ARCH=$(echo "$INFO" | awk '{print $2}')

    mount_iso "$ISO_FILE"
    copy_rootfs
    unmount_iso
    build_image "$BRANCH" "$ARCH"

    echo "Docker image built successfully!"
done