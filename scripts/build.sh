#!/bin/bash

# This script builds a Docker image from a custom Debian-based Linux distro ISO.

set -e

# Global variables
MOUNT_POINT="/mnt/iso"
ROOTFS_DIR="/tmp/rootfs"
IMAGE_TAGS_FILE="image_tags.txt"

# Expected values for validation
declare -a EXPECTED_BRANCHES=("desktop" "server")
declare -a EXPECTED_ARCHS=("x86_64" "arm64" "loongarch64" "mips64el" "sw64")
declare -a EXPECTED_KERNEL_TYPES=("standard" "hwe" "hwe-pp")
declare -a EXPECTED_DESKTOP_ENVS=("default" "wayland" "kde" "gnome" "ukui" "deepin")
declare -a EXPECTED_UPDATE_TYPES=("none" "update1")
declare -a EXPECTED_HARDWARE_TYPES=("generic" "hw-pangux" "hw-kirin9006c" "hw-kirin990")
declare -a EXPECTED_RELEASE_CHANNELS=("official" "retail")
declare -a EXPECTED_BUILD_TYPES=("release")
declare -a EXPECTED_CPU_TYPES=("unknown_cpu" "兆芯" "海光" "intel" "amd" "英特尔12代及以上cpu" "飞腾" "鲲鹏" "龙芯3a5000" "3a6000" "龙芯3a4000" "麒麟9000c" "麒麟9006c" "海思麒麟990")
declare -a EXPECTED_RELEASE_SUFFIXES=("base" "retail" "hw-pangux" "hw-kirin9006c" "hw-kirin990")

# Function to check for sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to validate extracted information
validate_info() {
    local field_name="$1"
    local value="$2"
    local -n expected_values_ref="$3"

    local found=false
    for expected_value in "${expected_values_ref[@]}"; do
        if [ "$value" == "$expected_value" ]; then
            found=true
            break
        fi
    done

    if [ "$found" == "false" ]; then
        echo "Warning: Unexpected value for $field_name: '$value'. Expected one of: ${expected_values_ref[*]}"
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
    desktop_env=$(echo "$filename" | grep -o -E '(Wayland|KDE|GNOME|UKUI|Deepin)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    update_type=$(echo "$filename" | grep -o -E '(update[0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    release_channel=$(echo "$filename" | grep -o -E '(Retail)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    build_type=$(echo "$filename" | grep -o -E '(Release)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    cpu_type=$(echo "$filename" | grep -o -E '(兆芯|海光|Intel|AMD|英特尔12代及以上CPU|飞腾|鲲鹏|龙芯3A5000|3A6000|龙芯3A4000|麒麟9000C|麒麟9006C|海思麒麟990)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    release_suffix=$(echo "$filename" | grep -o -E '(Retail|HW-[a-zA-Z0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')

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

    if [ -z "$build_type" ]; then
        build_type="release"
    fi

    if [ -z "$cpu_type" ]; then
        cpu_type="unknown_cpu"
    fi

    if [ -z "$release_suffix" ]; then
        release_suffix="base"
    fi
    echo "$branch $arch $version $release_date $kernel_type $desktop_env $update_type $hardware_type $release_channel $build_type $cpu_type $release_suffix"
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
    local build_type="${10}"
    local cpu_type="${11}"
    local release_suffix="${12}"
    local image_prefix=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    local image_tag="${image_prefix}:${branch}-${arch}-${version}-${release_date}-${kernel_type}-${desktop_env}-${update_type}-${hardware_type}-${release_channel}-${build_type}-${cpu_type}-${release_suffix}"

    echo "Building the Docker image with tag: $image_tag"
    docker build -t "$image_tag" "$ROOTFS_DIR" || { echo "Error: Failed to build the Docker image."; exit 1; }
    echo "$image_tag" >> "$IMAGE_TAGS_FILE"
}

# Function to summarize build information
summarize_build_info() {
    local iso_file="$1"
    local branch="$2"
    local arch="$3"
    local version="$4"
    local release_date="$5"
    local kernel_type="$6"
    local desktop_env="$7"
    local update_type="$8"
    local hardware_type="$9"
    local release_channel="${10}"
    local build_type="${11}"
    local cpu_type="${12}"
    local release_suffix="${13}"
    local image_prefix=${DOCKER_IMAGE_PREFIX:-triatk/kylin}
    local image_tag="${image_prefix}:${branch}-${arch}-${version}-${release_date}-${kernel_type}-${desktop_env}-${update_type}-${hardware_type}-${release_channel}-${build_type}-${cpu_type}-${release_suffix}"

    echo "\n--- Build Summary ---"
    echo "ISO File: $iso_file"
    echo "Branch: $branch"
    echo "Architecture: $arch"
    echo "Version: $version"
    echo "Release Date: $release_date"
    echo "Kernel Type: $kernel_type"
    echo "Desktop Environment: $desktop_env"
    echo "Update Type: $update_type"
    echo "Hardware Type: $hardware_type"
    echo "Release Channel: $release_channel"
    echo "Build Type: $build_type"
    echo "CPU Type: $cpu_type"
    echo "Release Suffix: $release_suffix"
    echo "Docker Image Tag: $image_tag"
    echo "---------------------"
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
    BUILD_TYPE=$(echo "$INFO" | awk '{print $10}')
    CPU_TYPE=$(echo "$INFO" | awk '{print $11}')
    RELEASE_SUFFIX=$(echo "$INFO" | awk '{print $12}')

    validate_info "Branch" "$BRANCH" "EXPECTED_BRANCHES"
    validate_info "Architecture" "$ARCH" "EXPECTED_ARCHS"
    # VERSION validation is more complex, might need a separate regex check
    validate_info "Kernel Type" "$KERNEL_TYPE" "EXPECTED_KERNEL_TYPES"
    validate_info "Desktop Environment" "$DESKTOP_ENV" "EXPECTED_DESKTOP_ENVS"
    validate_info "Update Type" "$UPDATE_TYPE" "EXPECTED_UPDATE_TYPES"
    validate_info "Hardware Type" "$HARDWARE_TYPE" "EXPECTED_HARDWARE_TYPES"
    validate_info "Release Channel" "$RELEASE_CHANNEL" "EXPECTED_RELEASE_CHANNELS"
    validate_info "Build Type" "$BUILD_TYPE" "EXPECTED_BUILD_TYPES"
    validate_info "CPU Type" "$CPU_TYPE" "EXPECTED_CPU_TYPES"
    validate_info "Release Suffix" "$RELEASE_SUFFIX" "EXPECTED_RELEASE_SUFFIXES"

    mount_iso "$ISO_FILE"
    copy_rootfs
    unmount_iso
    build_image "$BRANCH" "$ARCH" "$VERSION" "$RELEASE_DATE" "$KERNEL_TYPE" "$DESKTOP_ENV" "$UPDATE_TYPE" "$HARDWARE_TYPE" "$RELEASE_CHANNEL" "$BUILD_TYPE" "$CPU_TYPE" "$RELEASE_SUFFIX"

    summarize_build_info "$ISO_FILE" "$BRANCH" "$ARCH" "$VERSION" "$RELEASE_DATE" "$KERNEL_TYPE" "$DESKTOP_ENV" "$UPDATE_TYPE" "$HARDWARE_TYPE" "$RELEASE_CHANNEL" "$BUILD_TYPE" "$CPU_TYPE" "$RELEASE_SUFFIX"

    echo "Docker image built successfully!"
done