#!/bin/bash

# A script to install bat from pre-built binaries into a custom directory
# **without** modifying any shell configuration files.

# Get the directory of the current script regardless of where it's called from
# and no matter if this script was "sourced" or was executed.
# First backup the current SCRIPT_DIR in case some other script called this
# script and uses the same variable name SCRIPT_DIR. The backup will be
# restored in the end of this script. Implemented using a stack.
if [ -n "${SCRIPT_DIR+x}" ]; then
    SCRIPT_DIR_STACK+=("${SCRIPT_DIR}")
fi
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Exit on error, undefined variable, or pipe failure.
set -euo pipefail 

# Set the target installation directory.
INSTALL_DIR="$HOME/workspace/software/bat/bat"
LOADER_DIR="$HOME/.config/bat"

# Detect system architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "❌ Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Construct download URL for latest release
BAT_VERSION="v0.24.0"  # Update this to the latest version as needed
DOWNLOAD_URL="https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat-${BAT_VERSION}-${ARCH}-unknown-linux-musl.tar.gz"

echo "⚙️ Starting installing bat..."

# Check if the installation directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo "❌ Error: Directory '$INSTALL_DIR' already exists."
    echo "Please remove it or choose a different location before running this script."
    exit 1
fi

# Create a temporary directory for downloading
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "⚙️ Downloading bat ${BAT_VERSION} for ${ARCH}..."
cd "$TEMP_DIR"
curl -L -o bat.tar.gz "$DOWNLOAD_URL"

echo "⚙️ Extracting archive..."
tar -xzf bat.tar.gz

# Find the extracted directory (it includes version and architecture in the name)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "bat-*" | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "❌ Error: Failed to find extracted directory."
    exit 1
fi

echo "⚙️ Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/bin"
cp "$EXTRACTED_DIR/bat" "$INSTALL_DIR/bin/"
chmod +x "$INSTALL_DIR/bin/bat"

# Copy man pages and autocomplete files
if [ -d "$EXTRACTED_DIR/autocomplete" ]; then
    cp -r "$EXTRACTED_DIR/autocomplete" "$INSTALL_DIR/"
fi

# Copy loader script to be loaded/sourced in shell
mkdir -p "$LOADER_DIR"
ln -sf "${SCRIPT_DIR}/bat-loader.sh" "$LOADER_DIR/bat-loader.sh"

echo "✅ Successfully installed bat"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi