#!/usr/bin/env bash
# Usage: ./git-rebase-onto.sh <new-parent> <old-parent>
# The script assumes that NEW_PARENT and OLD_PARENT are valid git refs 
# (branch, tag, commit hash etc.) and the branch to move is the current
# branch

# Check that OLD_PARENT and NEW_PARENT are valid
if [ ! -z "$NEW_PARENT" ] || [ ! -z "$OLD_PARENT" ]; then
    echo "Error: NEW_PARENT and OLD_PARENT must be set to valid git refs"
    exit 1
fi

# Check that we are in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# Print the message title of the old parent
echo "Rebasing current branch onto $NEW_PARENT from $OLD_PARENT"
echo "ℹ️ Old parent commit message: $(git log -1 --pretty=%B $OLD_PARENT)"
echo "ℹ️ New parent commit message: $(git log -1 --pretty=%B $NEW_PARENT)"

# Rebase current branch
cmd="git rebase --onto $NEW_PARENT $OLD_PARENT"
echo "Executing command: $cmd"
eval "$cmd"