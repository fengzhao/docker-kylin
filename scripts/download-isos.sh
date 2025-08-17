
#!/bin/bash

# This script downloads ISOs from a list of URLs.

set -e

# Create the iso directory if it doesn't exist
mkdir -p iso

# Read the URLs from the iso_urls.txt file and download them
URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: $0 <URL>" >&2
    exit 1
fi

FILENAME=$(basename -- "$URL")

# Function to extract info using grep -oE and sed
extract_field() {
    local filename="$1"
    local pattern="$2"
    local default_value="$3"
    local extracted_value=$(echo "$filename" | grep -oE "$pattern" | head -n 1)
    # Convert to lowercase and remove any leading/trailing whitespace
    extracted_value=$(echo "$extracted_value" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "${extracted_value:-$default_value}"
}

BRANCH=$(extract_field "$FILENAME" "(Desktop|Server)" "")
BRANCH=$(echo "$BRANCH" | sed 's/kylin-//g') # Remove 'kylin-' prefix if present
ARCH_RAW=$(extract_field "$FILENAME" "(X86_64|ARM64|x86_64|arm64)" "")

# Map ARCH_RAW to amd64 or arm64
ARCH=""
case "$ARCH_RAW" in
    x86_64|X86_64) ARCH="amd64" ;;
    arm64|ARM64) ARCH="arm64" ;;
esac

VERSION=$(extract_field "$FILENAME" "V[0-9]+-SP[0-9]+-[0-9]+" "")
RELEASE_DATE=$(extract_field "$FILENAME" "20[0-9]{6}" "unknown")
KERNEL_TYPE=$(extract_field "$FILENAME" "(HWE-PP|HWE)" "standard")
DESKTOP_ENV=$(extract_field "$FILENAME" "(Wayland|KDE|GNOME|UKUI|Deepin)" "default")
UPDATE_TYPE=$(extract_field "$FILENAME" "(update[0-9]+)" "none")
HARDWARE_TYPE=$(extract_field "$FILENAME" "(HW-[a-zA-Z0-9]+)" "generic")
RELEASE_CHANNEL=$(extract_field "$FILENAME" "(Retail)" "official")
BUILD_TYPE=$(extract_field "$FILENAME" "(Release)" "release")
CPU_TYPE="unknown_cpu" # Removed specific CPU extraction due to complexity and redundancy
RELEASE_SUFFIX=$(extract_field "$FILENAME" "(Retail|HW-[a-zA-Z0-9]+)" "base")

# Check if essential info is missing or if ARCH is not amd64/arm64
if [ -z "$BRANCH" ] || [ -z "$ARCH" ] || [ -z "$VERSION" ] || { [ "$ARCH" != "amd64" ] && [ "$ARCH" != "arm64" ]; }; then
    echo "Warning: Could not determine essential metadata (branch, architecture, or version) or unsupported architecture from the URL: $URL. Skipping this file." >&2
    echo "" # Output empty path to signal failure to workflow
    exit 0 # Exit successfully so workflow can continue
fi

# Create the directory structure
DOWNLOAD_DIR="iso/$BRANCH/$ARCH/$VERSION/$RELEASE_DATE/$KERNEL_TYPE/$DESKTOP_ENV/$UPDATE_TYPE/$HARDWARE_TYPE/$RELEASE_CHANNEL/$BUILD_TYPE/$RELEASE_SUFFIX"
mkdir -p "$DOWNLOAD_DIR"

# Download the ISO
echo "Downloading $FILENAME to $DOWNLOAD_DIR" >&2
wget -q -nv --timeout=1800 -c -O "$DOWNLOAD_DIR/$FILENAME" "$URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download $FILENAME from $URL." >&2
    echo "" # Output empty path to signal failure to workflow
    exit 0 # Exit successfully so workflow can continue
fi

# Output the path to the downloaded ISO
echo "$DOWNLOAD_DIR/$FILENAME"
