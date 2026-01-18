#!/usr/bin/env bash

# Get the directory of the current script regardless of where it's called from
# and no matter if this script was "sourced" or was executed.
# First backup the current SCRIPT_DIR in case some other script called this
# script and uses the same variable name SCRIPT_DIR. The backup will be
# restored in the end of this script. Implemented using a stack.
if [ -n "${SCRIPT_DIR+x}" ]; then
    SCRIPT_DIR_STACK+=("${SCRIPT_DIR}")
fi
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Argument 1 expected to be profile.
# Argument 2 expected to be environment.
# Default is "default" for both
PROFILE="${1:-default}"
ENV="${2:-default}"

echo "⚙️ Starting Bash installation..."
echo "   Using profile-env: ${PROFILE}-${ENV}"

CONFIG_DIR="$HOME/.config/bash"

# Create necessary directories
mkdir -p "$CONFIG_DIR"

# Copy configuration files
ln -sf ${SCRIPT_DIR}/bash-rc              "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-profile         "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-inputrc*        "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-aliases*.sh     "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-prompt*.sh      "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-functions*.sh   "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-general.sh      "$CONFIG_DIR/"
ln -sf ${SCRIPT_DIR}/bash-local-*.sh      "$CONFIG_DIR/"

ln -fs "$HOME/.config/bash/bash-local-${PROFILE}-${ENV}.sh" "$CONFIG_DIR/bash-local.sh"

# Link loader script
ln -sf ${SCRIPT_DIR}/bash-loader.sh "$CONFIG_DIR/bash-loader.sh"

# Link bash configuration files to home directory
ln -fs "$HOME/.config/bash/bash-rc" "$HOME/.bashrc"
ln -fs "$HOME/.config/bash/bash-profile" "$HOME/.bash_profile"
ln -fs "$HOME/.config/bash/bash-inputrc" "$HOME/.inputrc"

echo "✅ Successfully installed bash"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi