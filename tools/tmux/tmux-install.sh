#!/usr/bin/env bash

# A script to install tmux from pre-built binaries into a custom directory
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

set -euo pipefail

INSTALL_DIR="${HOME}/workspace/software/tmux/tmux/bin"
LOADER_DIR="${HOME}/.config/tmux"

# Check if the installation directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo "❌ Error: Directory '$INSTALL_DIR' already exists."
    echo "Please remove it or choose a different location before running this script."
    exit 1
fi

echo "⚙️ Fetching latest tmux-static release info…"

echo "⚙️ Downloading tmux static binary"

API_URL="https://api.github.com/repos/pythops/tmux-linux-binary/releases/latest"
RELEASE_JSON="$(curl -s "$API_URL")"

DOWNLOAD_URL=$(printf '%s\n' "$RELEASE_JSON" \
  | grep -E '"browser_download_url":' \
  | sed -E 's/^[[:space:]]*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/' \
  | grep -E 'linux.*(x86_64|amd64)' \
  | head -n1)
if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "❌ ERROR: Could not find static tmux binary."
    exit 1
fi
TMPFILE=$(mktemp)
curl -L "$DOWNLOAD_URL" -o "$TMPFILE"

echo "⚙️ Installing tmux to $INSTALL_DIR"
mkdir -p "${INSTALL_DIR}"
install -m 755 "$TMPFILE" "${INSTALL_DIR}/tmux"

echo "⚙️ Copying tmux configuration files"
mkdir -p "${HOME}/.config/tmux"
cp ${SCRIPT_DIR}/tmux.conf "${HOME}/.config/tmux/tmux.conf"
cp ${SCRIPT_DIR}/tmux.conf.common "${HOME}/.config/tmux/tmux.conf.common"
cp ${SCRIPT_DIR}/tmux.conf.home "${HOME}/.config/tmux/tmux.conf.home"

echo "⚙️ Installing TPM (Tmux Plugin Manager) and plugins"
TPM_PLUGIN_MANAGER_DIR=${HOME}/.config/tmux/plugins/tpm
if [ ! -d "${TPM_PLUGIN_MANAGER_DIR}" ]; then
    git clone https://github.com/tmux-plugins/tpm ${TPM_PLUGIN_MANAGER_DIR}
fi
${TPM_PLUGIN_MANAGER_DIR}/bin/install_plugins

echo "⚙️ Setting up tmux loader script"
mkdir -p "$LOADER_DIR"
cp ${SCRIPT_DIR}/tmux-loader.sh "$LOADER_DIR/tmux-loader.sh"

echo "✅ Successfully installed tmux"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi