#!/bin/bash

# A script to install eza from pre-built binary into a custom directory
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
INSTALL_DIR="$HOME/workspace/software/eza/eza"
LOADER_DIR="$HOME/.config/eza"


# Detect system architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH="x86_64-unknown-linux-musl"
        ;;
    aarch64|arm64)
        ARCH="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "❌ Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Construct download URL for latest release
DOWNLOAD_URL="https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}.tar.gz"

echo "⚙️ Starting installing eza..."

# Check if the installation directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo "❌ Error: Directory '$INSTALL_DIR' already exists."
    echo "Please remove it or choose a different location before running this script."
    exit 1
fi

# Create a temporary directory for downloading
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "⚙️ Downloading eza for ${ARCH}..."
cd "$TEMP_DIR"
curl -L -o eza.tar.gz "$DOWNLOAD_URL"

echo "⚙️ Extracting archive..."
tar -xzf eza.tar.gz

echo "⚙️ Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/bin"
cp eza "$INSTALL_DIR/bin/"
chmod +x $INSTALL_DIR/bin/eza

# Copy loader script to be loaded/sourced in shell
mkdir -p "$LOADER_DIR"
ln -sf "${SCRIPT_DIR}/eza-loader.sh" "$LOADER_DIR/eza-loader.sh"

echo "✅ Successfully installed eza"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi