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

    branch=$(echo "$filename" | grep -o -E '(Desktop|Server)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    arch=$(echo "$filename" | grep -o -E '(X86_64|ARM64|LoongArch64|SW64|x86_64|arm64|mips64el)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    version=$(echo "$filename" | grep -o -E 'V[0-9]+-SP[0-9]+-[0-9]+' | head -n 1 | tr '[:upper:]' '[:lower:]')
    release_date=$(echo "$filename" | grep -o -E '20[0-9]{6}' | head -n 1)

    if [ -z "$branch" ] || [ -z "$arch" ] || [ -z "$version" ]; then
        echo "Warning: Could not determine branch, architecture, or version from the ISO filename: $filename."
        return 1
    fi

    if [ -z "$release_date" ]; then
        release_date="unknown"
    fi
    echo "$branch $arch $version $release_date"
}

# Function to build Docker image
build_image() {
    local branch="$1"
    local arch="$2"
    local version="$3"
    local release_date="$4"
    local image_prefix=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    local image_tag="${image_prefix}:${branch}-${arch}-${version}-${release_date}"

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
    VERSION=$(echo "$INFO" | awk '{print $3}')
    RELEASE_DATE=$(echo "$INFO" | awk '{print $4}')

    mount_iso "$ISO_FILE"
    copy_rootfs
    unmount_iso
    build_image "$BRANCH" "$ARCH" "$VERSION" "$RELEASE_DATE"

    echo "Docker image built successfully!"
done