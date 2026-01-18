#!/bin/bash

# A script to download and install the latest pre-compiled lazygit binary
# into a custom directory without modifying any shell configuration files.

# Get the directory of the current script regardless of where it's called from
# and no matter if this script was "sourced" or was executed.
# First backup the current SCRIPT_DIR in case some other script called this
# script and uses the same variable name SCRIPT_DIR. The backup will be
# restored in the end of this script. Implemented using a stack.
if [ -n "${SCRIPT_DIR+x}" ]; then
    SCRIPT_DIR_STACK+=("${SCRIPT_DIR}")
fi
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Make sure we exit on errors
set -euo pipefail

# --- Helper Function for Logging ---
info() {
    echo "⚙️ $1"
}

success() {
    echo "✅ $1"
}

error() {
    echo "❌ Error: $1" >&2
    exit 1
}

# --- Configuration ---
INSTALL_DIR="$HOME/workspace/software/lazygit/lazygit"
CONFIG_DIR="$HOME/.config/lazygit"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

install_binary() {
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️ Warning: Directory '$INSTALL_DIR' already exists. Skipping binary installation."
        return 0
    fi

    # Pre-flight checks
    command -v curl >/dev/null 2>&1 || error "curl is not installed. Please install it first."
    command -v tar >/dev/null 2>&1 || error "tar is not installed. Please install it first."

    # Get the latest version tag from the GitHub API (e.g., v0.42.0)
    info "Finding the latest lazygit version..."
    LG_TAG=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -oP '"tag_name": "\K(v[0-9\.]+)(?=")')
    LG_VERSION=${LG_TAG#v} # Strip the 'v' prefix for the filename

    [ -z "$LG_VERSION" ] && error "Could not determine the latest lazygit version."
    info "Latest lazygit version is $LG_VERSION."

    # Construct the download URL for Linux x86_64
    LG_URL="https://github.com/jesseduffield/lazygit/releases/download/${LG_TAG}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
    info "Downloading lazygit from $LG_URL"
    curl -Lo lazygit.tar.gz "$LG_URL"

    # Create the installation directory and extract the binary
    info "Installing lazygit to $INSTALL_DIR/bin/"
    mkdir -p "$INSTALL_DIR/bin"

    # Extract *only* the 'lazygit' binary from the archive directly into the target dir
    info "Extracting lazygit binary"
    tar -xzf lazygit.tar.gz -C "$INSTALL_DIR/bin/" lazygit

    # Clean up the downloaded archive
    info "Cleaning up temporary files"
    rm lazygit.tar.gz
}

install_config() {
    if [ -f "$CONFIG_DIR/lazygit-loader.sh" ]; then
        echo "⚠️ Warning: Config already exists. Skipping config installation."
        return 0
    fi

    info "Installing lazygit config files..."
    mkdir -p "$CONFIG_DIR"
    ln -sf "${SCRIPT_DIR}/lazygit-loader.sh" "$CONFIG_DIR/lazygit-loader.sh"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

info "Starting lazygit binary installation..."

install_binary
install_config

success "Successfully installed lazygit"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi