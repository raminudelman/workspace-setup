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

# Argument 1 expected to be environment.
# Default is "default"
ENV="${1:-default}"

echo "⚙️ Starting Bash installation..."

# Create necessary directories
mkdir -p "$HOME/.config/bash"

# Copy configuration files
cp ${SCRIPT_DIR}/bash-rc              "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-profile         "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-inputrc*        "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-aliases*.sh     "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-prompt*.sh      "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-functions*.sh   "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-general.sh      "$HOME/.config/bash/"
cp ${SCRIPT_DIR}/bash-local-*.sh      "$HOME/.config/bash/"

ln -fs "$HOME/.config/bash/bash-local-${ENV}.sh" "$HOME/.config/bash/bash-local.sh"

# Copy loader script
cp ${SCRIPT_DIR}/bash-loader.sh "$HOME/.config/bash/bash-loader.sh"

ln -fs "$HOME/.config/bash/bash-rc" "$HOME/.bashrc"
ln -fs "$HOME/.config/bash/bash-profile" "$HOME/.bash_profile"
ln -fs "$HOME/.config/bash/bash-inputrc" "$HOME/.inputrc"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi