
#!/bin/bash

# This script downloads ISOs from a list of URLs.

set -e

# Create the iso directory if it doesn't exist
mkdir -p iso

# Read the URLs from the iso_urls.txt file and download them
while read URL; do
    FILENAME=$(basename -- "$URL")
    BRANCH=$(echo "$FILENAME" | grep -o -E '(Desktop|Server)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    ARCH=$(echo "$FILENAME" | grep -o -E '(X86_64|ARM64|LoongArch64|SW64|x86_64|arm64|mips64el)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    VERSION=$(echo "$FILENAME" | grep -o -E 'V[0-9]+-SP[0-9]+-[0-9]+' | head -n 1 | tr '[:upper:]' '[:lower:]')
    RELEASE_DATE=$(echo "$FILENAME" | grep -o -E '20[0-9]{6}' | head -n 1)
    KERNEL_TYPE=$(echo "$FILENAME" | grep -o -E '(HWE|HWE-PP)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    DESKTOP_ENV=$(echo "$FILENAME" | grep -o -E '(Wayland)' | head -n 1 | tr '[:upper:]' '[:lower:]')

    if [ -z "$BRANCH" ] || [ -z "$ARCH" ] || [ -z "$VERSION" ]; then
        echo "Warning: Could not determine branch, architecture, or version from the URL: $URL. Skipping this file."
        continue
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

    # Create the directory structure
    DOWNLOAD_DIR="iso/$BRANCH/$ARCH/$VERSION/$RELEASE_DATE/$KERNEL_TYPE/$DESKTOP_ENV"
    mkdir -p "$DOWNLOAD_DIR"

    # Download the ISO
    echo "Downloading $FILENAME to $DOWNLOAD_DIR"
    wget -c -O "$DOWNLOAD_DIR/$FILENAME" "$URL"
done < iso_urls.txt
