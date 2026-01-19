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

# Argument 1 expected to be profile.
# Argument 2 expected to be environment.
# Default is "default" for both
PROFILE="${1:-default}"
ENV="${2:-default}"

INSTALL_DIR="${HOME}/workspace/software/tmux/tmux/bin"
CONFIG_DIR="${HOME}/.config/tmux"
TPM_PLUGIN_MANAGER_DIR="${HOME}/.config/tmux/plugins/tpm"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

install_binary() {
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️ Warning: Directory '$INSTALL_DIR' already exists. Skipping binary installation."
        return 0
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
        return 1
    fi
    TMPFILE=$(mktemp)
    curl -L "$DOWNLOAD_URL" -o "$TMPFILE"

    echo "⚙️ Installing tmux to $INSTALL_DIR"
    mkdir -p "${INSTALL_DIR}"
    install -m 755 "$TMPFILE" "${INSTALL_DIR}/tmux"
}

install_config() {
    if [ -f "${CONFIG_DIR}/tmux.conf" ]; then
        echo "⚠️ Warning: Config already exists. Skipping config installation."
        return 0
    fi

    echo "⚙️ Copying tmux configuration files"
    mkdir -p "${CONFIG_DIR}"
    ln -sf "${SCRIPT_DIR}/tmux-conf" "${CONFIG_DIR}/tmux.conf"
    ln -sf ${SCRIPT_DIR}/tmux-conf-*  "$CONFIG_DIR/"
    ln -sf "${SCRIPT_DIR}/tmux-conf-${PROFILE}-${ENV}" "${CONFIG_DIR}/tmux.conf.local"
}

install_tpm() {
    if [ -d "${TPM_PLUGIN_MANAGER_DIR}" ]; then
        echo "⚠️ Warning: TPM already exists. Skipping TPM installation."
        return 0
    fi

    echo "⚙️ Installing TPM (Tmux Plugin Manager) and plugins"
    git clone https://github.com/tmux-plugins/tpm ${TPM_PLUGIN_MANAGER_DIR}
    ${TPM_PLUGIN_MANAGER_DIR}/bin/install_plugins
}

install_loader() {
    if [ -f "$CONFIG_DIR/tmux-loader.sh" ]; then
        echo "⚠️ Warning: Loader already exists. Skipping loader installation."
        return 0
    fi

    echo "⚙️ Setting up tmux loader script"
    mkdir -p "$CONFIG_DIR"
    ln -sf "${SCRIPT_DIR}/tmux-loader.sh" "$CONFIG_DIR/tmux-loader.sh"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

echo "⚙️ Starting tmux installation..."
echo "   Using profile-env: ${PROFILE}-${ENV}"

install_binary
install_config
install_tpm
install_loader

echo "✅ Successfully installed tmux"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi