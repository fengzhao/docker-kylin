#!/bin/bash

# This script downloads ISOs from a list of URLs.

set -e

# Create the iso directory if it doesn't exist
mkdir -p iso

# Read the URLs from the iso_urls.txt file and download them
URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

FILENAME=$(basename -- "$URL")
BRANCH=$(echo "$FILENAME" | grep -o -E '(Desktop|Server)' | head -n 1 | tr '[:upper:]' '[:lower:]')
ARCH=$(echo "$FILENAME" | grep -o -E '(X86_64|ARM64|LoongArch64|SW64|x86_64|arm64|mips64el)' | head -n 1 | tr '[:upper:]' '[:lower:]')
VERSION=$(echo "$FILENAME" | grep -o -E 'V[0-9]+-SP[0-9]+-[0-9]+' | head -n 1 | tr '[:upper:]' '[:lower:]')
RELEASE_DATE=$(echo "$FILENAME" | grep -o -E '20[0-9]{6}' | head -n 1)
KERNEL_TYPE=$(echo "$FILENAME" | grep -o -E '(HWE-PP|HWE)' | head -n 1 | tr '[:upper:]' '[:lower:]')
DESKTOP_ENV=$(echo "$FILENAME" | grep -o -E '(Wayland|KDE|GNOME|UKUI|Deepin)' | head -n 1 | tr '[:upper:]' '[:lower:]')
UPDATE_TYPE=$(echo "$FILENAME" | grep -o -E '(update[0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')
HARDWARE_TYPE=$(echo "$FILENAME" | grep -o -E '(HW-[a-zA-Z0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')
RELEASE_CHANNEL=$(echo "$FILENAME" | grep -o -E '(Retail)' | head -n 1 | tr '[:upper:]' '[:lower:]')
BUILD_TYPE=$(echo "$FILENAME" | grep -o -E '(Release)' | head -n 1 | tr '[:upper:]' '[:lower:]')
CPU_TYPE=$(echo "$FILENAME" | grep -o -E '(兆芯|海光|Intel|AMD|英特尔12代及以上CPU|飞腾|鲲鹏|龙芯3A5000|3A6000|龙芯3A4000|麒麟9000C|麒麟9006C|海思麒麟990)' | head -n 1 | tr '[:upper:]' '[:lower:]')
RELEASE_SUFFIX=$(echo "$FILENAME" | grep -o -E '(Retail|HW-[a-zA-Z0-9]+)' | head -n 1 | tr '[:upper:]' '[:lower:]')

if [ -z "$BRANCH" ] || [ -z "$ARCH" ] || [ -z "$VERSION" ]; then
    echo "Warning: Could not determine branch, architecture, or version from the URL: $URL. Skipping this file."
    exit 1
fi

# If RELEASE_DATE is empty, set it to 'unknown'
if [ -z "$RELEASE_DATE" ]; then
    RELEASE_DATE="unknown"
fi

# If KERNEL_TYPE is empty, set it to 'standard'
if [ -z "$KERNEL_TYPE" ]; then
    KERNEL_TYPE="standard"
fi

# If DESKTOP_ENV is empty, set it to 'default'
if [ -z "$DESKTOP_ENV" ]; then
    DESKTOP_ENV="default"
fi

# If UPDATE_TYPE is empty, set it to 'none'
if [ -z "$UPDATE_TYPE" ]; then
    UPDATE_TYPE="none"
fi

# If HARDWARE_TYPE is empty, set it to 'generic'
if [ -z "$HARDWARE_TYPE" ]; then
    HARDWARE_TYPE="generic"
fi

# If RELEASE_CHANNEL is empty, set it to 'official'
if [ -z "$RELEASE_CHANNEL" ]; then
    RELEASE_CHANNEL="official"
fi

# If BUILD_TYPE is empty, set it to 'release'
if [ -z "$BUILD_TYPE" ]; then
    BUILD_TYPE="release"
fi

# If CPU_TYPE is empty, set it to 'unknown_cpu'
if [ -z "$CPU_TYPE" ]; then
    CPU_TYPE="unknown_cpu"
fi

# If RELEASE_SUFFIX is empty, set it to 'base'
if [ -z "$RELEASE_SUFFIX" ]; then
    RELEASE_SUFFIX="base"
fi

# Create the directory structure
DOWNLOAD_DIR="iso/$BRANCH/$ARCH/$VERSION/$RELEASE_DATE/$KERNEL_TYPE/$DESKTOP_ENV/$UPDATE_TYPE/$HARDWARE_TYPE/$RELEASE_CHANNEL/$BUILD_TYPE/$CPU_TYPE/$RELEASE_SUFFIX"
mkdir -p "$DOWNLOAD_DIR"

# Download the ISO
echo "Downloading $FILENAME to $DOWNLOAD_DIR"
wget -c -O "$DOWNLOAD_DIR/$FILENAME" "$URL"

# Output the path to the downloaded ISO
echo "$DOWNLOAD_DIR/$FILENAME"