#!/bin/bash

# The script checks all git worktrees for uncommitted changes. This script
# should be run from a git repository.

# Check if we are inside a git repository
if ! git rev-parse > /dev/null 2>&1; then
  echo "Error: This script must be run inside a git repository."
  exit 1
fi

# A flag to track if any changes are found at all
ANY_CHANGES_FOUND=0

echo "🔎 Checking all worktrees for uncommitted changes..."
echo ""

# Loop through each line of 'git worktree list'
while read -r line; do
  # Extract the path and branch name from the line
  worktree_path=$(echo "$line" | awk '{print $1}')
  branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')

  # Check if the worktree has any changes using the --porcelain flag
  # The '-z' flag checks if the output string is empty
  if [ -z "$(git -C "$worktree_path" status --porcelain)" ]; then
    # If the output is empty, the worktree is clean
    : # Do nothing
  else
    # If the output is not empty, there are changes
    echo "============================================================================="
    echo "⚠️ Changes found in: $(basename "$worktree_path") (branch: $branch)"
    echo "============================================================================="
    # Run the standard 'git status' command inside that worktree's path
    echo "Worktree path: $worktree_path"
    git -C "$worktree_path" status
    echo "" # Add a blank line for readability
    ANY_CHANGES_FOUND=1
  fi
done < <(git worktree list)

echo "============================================================================="
if [ "$ANY_CHANGES_FOUND" -eq 0 ]; then
  echo "✅ All worktrees are clean. No uncommitted changes found."
else 
  echo "❌ Uncommitted changes were found in one or more worktrees."
fi
echo "============================================================================="