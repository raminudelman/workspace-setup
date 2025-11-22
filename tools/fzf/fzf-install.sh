#!/bin/bash

# A script to install fzf from source into a custom directory
# without modifying any shell configuration files.

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
INSTALL_DIR="$HOME/workspace/software/fzf/fzf"

echo "⚙️ Starting installing fzf..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: git is not installed. Please install git and try again."
    exit 1
fi

# Check if the installation directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo "❌ Error: Directory '$INSTALL_DIR' already exists."
    echo "Please remove it or choose a different location before running this script."
    exit 1
fi

# --- Installation ---
echo "⚙️ Cloning fzf repository into '$INSTALL_DIR'..."
# Clone only the latest version for a faster download.
git clone --depth 1 https://github.com/junegunn/fzf.git "$INSTALL_DIR"

echo "⚙️ Building the fzf binary..."
# The --bin flag only builds the binary without installing any shell integration files.
${INSTALL_DIR}/install --bin --no-bash --no-completion --no-key-bindings

echo "⚙️ Copying configuration files"
mkdir -p "$HOME/.config/fzf"
cp ${SCRIPT_DIR}/fzf.bash "$HOME/.config/fzf/fzf.bash"
cp ${SCRIPT_DIR}/fzf-loader.sh "$HOME/.config/fzf/fzf-loader.sh"

echo "✅ Successfully installed fzf"

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi