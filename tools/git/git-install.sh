#!/usr/bin/env bash

# A script to install a standalone Git binary into a custom directory
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

INSTALL_DIR="$HOME/workspace/software/git/git"
CONFIG_DIR="$HOME/.config/git"

# Exit on error, undefined variable, pipe failure.
set -euo pipefail

# Argument 2 expected to be profile.
# Default is "default"
PROFILE="${2:-default}"

echo "⚙️ Starting Git installation..."

mkdir -p "${CONFIG_DIR}"

# Link git configuration files
ln -sf "${SCRIPT_DIR}/git-loader.sh" "${CONFIG_DIR}/git-loader.sh"
ln -sf "${SCRIPT_DIR}/git-completion.bash" "${CONFIG_DIR}/git-completion.bash"
ln -sf "${SCRIPT_DIR}/git-message" "${CONFIG_DIR}/git-message"
ln -sf "${SCRIPT_DIR}/git-config" "${CONFIG_DIR}/config"
ln -sf "${SCRIPT_DIR}/git-config-local-${PROFILE}" "${CONFIG_DIR}/config-local"

ln -sf "$HOME/.config/git/config" "$HOME/.gitconfig" # TODO: In new versions if git - no need for ~/.gitconfig. Git should pick up ~/.config/git/config automatically

# Restore (pop) the previous SCRIPT_DIR from the stack
if [ -n "${SCRIPT_DIR_STACK+x}" ] && [ ${#SCRIPT_DIR_STACK[@]} -gt 0 ]; then
    SCRIPT_DIR="${SCRIPT_DIR_STACK[-1]}"
    unset 'SCRIPT_DIR_STACK[-1]'
else
    unset SCRIPT_DIR
fi

echo "✅ Successfully installed git"

exit 0 # TODO: Need to make this script work and download a standalone git binary!

# tar required
if ! command -v tar >/dev/null 2>&1; then
    echo "❌ Error: 'tar' is required but not installed."
    exit 1
fi

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ]; then
    echo "❌ Error: Directory '$INSTALL_DIR' already exists."
    echo "Remove it or choose a different location."
    exit 1
fi

echo "⚙️ Fetching latest Git binary release info..."
BASE_URL="https://mirrors.edge.kernel.org/pub/software/scm/git"

# find latest git-*-x86_64.tar.xz
HTML=$(curl -fsSL "$BASE_URL/")

# Extract filenames matching git-*-x86_64.tar.xz
LATEST_TARBALL=$(printf "%s" "$HTML" \
    | grep -oE 'git-[0-9]+\.[0-9]+\.[0-9]+\.tar\.xz' \
    | sort -V \
    | tail -n 1)

if [ -z "$LATEST_TARBALL" ]; then
    echo "❌ Could not determine latest Git release."
    exit 1
fi

TARBALL_URL="$BASE_URL/$LATEST_TARBALL"

echo "⚙️ Latest Git release: $LATEST_TARBALL"

TMP_DIR=$(mktemp -d)
TARBALL_PATH="$TMP_DIR/$LATEST_TARBALL"

echo "⚙️ Downloading Git from: $TARBALL_URL"

curl -fsSL -o "$TARBALL_PATH" "$TARBALL_URL"

echo "⚙️ Extracting git to '$INSTALL_DIR'..."
mkdir -p "$INSTALL_DIR"
tar -xf "$TARBALL_PATH" --strip-components=1 -C "$INSTALL_DIR"
rm -rf "$TMP_DIR"

echo "⚙️ Building Git from source..."
cd "$INSTALL_DIR"

# Use a prefix so it installs into INSTALL_DIR
make configure
./configure --prefix="$INSTALL_DIR"
make -j$(nproc) all
make install

