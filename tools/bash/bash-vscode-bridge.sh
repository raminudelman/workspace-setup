#!/usr/bin/env bash


################################################################################
###                          VS Code Bridge Setup                            ###
################################################################################

# This setup allows using VS Code server from within bash sessions. So when
# you ssh into a remote machine, you can still use the "code" command to open
# files in your local VS Code instance. For example, running:
#
# ```sh
# code --diff file-1.txt file-2.txt
# ```
#
# Will open the diff view in your local VS Code, even if you are on a remote
# server via SSH.

# 1. Find the hidden communication script (Bypasses the "No installation found" error)
REAL_CODE_SCRIPT=$(find ~/.vscode-server/cli/servers/ -name "code" -type f 2>/dev/null | head -n 1)

# 2. Find the IPC socket
export VSCODE_IPC_HOOK_CLI=$(find /run/user/$(id -u) -name "vscode-ipc-*.sock" -user $USER 2>/dev/null | head -n 1)

# Check if script exists
if [ -z "$REAL_CODE_SCRIPT" ]; then
    echo "❌ ERROR: VS Code remote CLI script not found."
    return 1 2>/dev/null || exit 1
fi

# Check if socket exists
if [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
    echo "❌ ERROR: VS Code IPC Socket not found. Is VS Code open on Windows?"
    return 1 2>/dev/null || exit 1
fi

# Verify the "bin" directory requirement
PARENT_DIR=$(basename $(dirname $(dirname "$REAL_CODE_SCRIPT")))
if [ "$PARENT_DIR" != "bin" ]; then
    echo "⚠️ WARNING: VS Code layout has changed! Expected 'bin', found '$PARENT_DIR'."
    echo "   Path: $REAL_CODE_SCRIPT"
    # We still set the alias, but warn the user
fi

if [ -n "$REAL_CODE_SCRIPT" ] && [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
    # Create the alias using the script, NOT the manager binary
    alias code="$REAL_CODE_SCRIPT"

    # Configure for Claude Code
    export EDITOR="code --wait"
    export CLAUDE_CODE_DIFF_CMD="code --wait --diff"
fi
