#!/bin/bash

# A script to download and install the latest delta pager binary without sudo.

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
INSTALL_DIR="$HOME/workspace/software/delta/delta"
BIN_DIR="$INSTALL_DIR/bin"
CONFIG_DIR="$HOME/.config/delta"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

install_binary() {
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️ Warning: Directory '$INSTALL_DIR' already exists. Skipping binary installation."
        return 0
    fi

    # Get the latest version tag from the GitHub API.
    echo "⚙️ Finding the latest version of delta..."
    LATEST_TAG=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

    if [ -z "$LATEST_TAG" ]; then
        echo "❌ Error: Could not fetch the latest version tag. Check your internet connection."
        return 1
    fi

    echo "⚙️ Latest version found: $LATEST_TAG"
    DOWNLOAD_URL="https://github.com/dandavison/delta/releases/download/$LATEST_TAG/delta-$LATEST_TAG-x86_64-unknown-linux-gnu.tar.gz"

    echo "⚙️ Creating installation directory at $BIN_DIR"
    mkdir -p "$BIN_DIR"

    # Download and extract the binary.
    echo "⚙️ Downloading and extracting from $DOWNLOAD_URL"
    # The tarball contains a directory, so we strip the top-level directory.
    curl -L "$DOWNLOAD_URL" | tar -xzf - --strip-components=1 -C "$INSTALL_DIR"

    # Move the binary to the bin directory.
    mv "$INSTALL_DIR/delta" "$BIN_DIR/delta"
}

install_config() {
    if [ -f "${CONFIG_DIR}/delta-loader.sh" ]; then
        echo "⚠️ Warning: Config already exists. Skipping config installation."
        return 0
    fi

    echo "⚙️ Installing delta config files..."
    mkdir -p "${CONFIG_DIR}"
    ln -sf "${SCRIPT_DIR}/delta-loader.sh" "${CONFIG_DIR}/delta-loader.sh"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

echo "⚙️ Starting installing delta..."

install_binary
install_config

echo "✅ Successfully installed delta"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi