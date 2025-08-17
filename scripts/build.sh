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
    kernel_type=$(echo "$filename" | grep -o -E '(HWE|HWE-PP)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    desktop_env=$(echo "$filename" | grep -o -E '(Wayland)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    update_type=$(echo "$filename" | grep -o -E '(update[0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    hardware_type=$(echo "$filename" | grep -o -E '(HW-[a-zA-Z0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    release_channel=$(echo "$filename" | grep -o -E '(Retail)' | head -n 1 | tr '[:upper:]' '[:lower:]')

    if [ -z "$branch" ] || [ -z "$arch" ] || [ -z "$version" ]; then
        echo "Warning: Could not determine branch, architecture, or version from the ISO filename: $filename."
        return 1
    fi

    if [ -z "$release_date" ]; then
        release_date="unknown"
    fi

    if [ -z "$kernel_type" ]; then
        kernel_type="standard"
    fi

    if [ -z "$desktop_env" ]; then
        desktop_env="default"
    fi

    if [ -z "$update_type" ]; then
        update_type="none"
    fi

    if [ -z "$hardware_type" ]; then
        hardware_type="generic"
    fi

    if [ -z "$release_channel" ]; then
        release_channel="official"
    fi
    echo "$branch $arch $version $release_date $kernel_type $desktop_env $update_type $hardware_type $release_channel"
}

# Function to build Docker image
build_image() {
    local branch="$1"
    local arch="$2"
    local version="$3"
    local release_date="$4"
    local kernel_type="$5"
    local desktop_env="$6"
    local update_type="$7"
    local hardware_type="$8"
    local release_channel="$9"
    local image_prefix=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    local image_tag="${image_prefix}:${branch}-${arch}-${version}-${release_date}-${kernel_type}-${desktop_env}-${update_type}-${hardware_type}-${release_channel}"

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
    KERNEL_TYPE=$(echo "$INFO" | awk '{print $5}')
    DESKTOP_ENV=$(echo "$INFO" | awk '{print $6}')
    UPDATE_TYPE=$(echo "$INFO" | awk '{print $7}')
    HARDWARE_TYPE=$(echo "$INFO" | awk '{print $8}')
    RELEASE_CHANNEL=$(echo "$INFO" | awk '{print $9}')

    mount_iso "$ISO_FILE"
    copy_rootfs
    unmount_iso
    build_image "$BRANCH" "$ARCH" "$VERSION" "$RELEASE_DATE" "$KERNEL_TYPE" "$DESKTOP_ENV" "$UPDATE_TYPE" "$HARDWARE_TYPE" "$RELEASE_CHANNEL"

    echo "Docker image built successfully!"
done