
#!/bin/bash

# This script downloads ISOs from a list of URLs.

set -e

# Create the iso directory if it doesn't exist
mkdir -p iso

# Read the URLs from the iso_urls.txt file and download them
while read URL; do
    FILENAME=$(basename -- "$URL")
    BRANCH=$(echo "$FILENAME" | grep -o -E '(server|desktop)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    ARCH=$(echo "$FILENAME" | grep -o -E '(x86_64|X86_64|amd64|ARM64|arm64|loongarch64|mips64el|sw64)' | head -n 1 | tr '[:upper:]' '[:lower:]')
    VERSION=$(echo "$FILENAME" | grep -o -E 'V[0-9]+-SP[0-9]+-[0-9]+' | head -n 1 | tr '[:upper:]' '[:lower:]')

    if [ -z "$BRANCH" ] || [ -z "$ARCH" ] || [ -z "$VERSION" ]; then
        echo "Warning: Could not determine branch, architecture, or version from the URL: $URL. Skipping this file."
        continue
    fi

    # Create the directory structure
    DOWNLOAD_DIR="iso/$BRANCH/$ARCH/$VERSION"
    mkdir -p "$DOWNLOAD_DIR"

    # Download the ISO
    echo "Downloading $FILENAME to $DOWNLOAD_DIR"
    wget -c -O "$DOWNLOAD_DIR/$FILENAME" "$URL"
done < iso_urls.txt
