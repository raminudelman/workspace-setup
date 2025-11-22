#!/bin/bash

# --- CONFIGURATION ---
# Replace this with the commit hash RIGHT BEFORE the range you want to stash.
START_COMMIT_HASH="$1"

# --- SCRIPT ---
echo "Starting process. Make sure your working directory is clean."

# Save our starting branch so we can return to it at the end.
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$ORIGINAL_BRANCH" ] || [ "$ORIGINAL_BRANCH" == "HEAD" ]; then
  echo "Error: You are in a detached HEAD state. Please checkout a branch first."
  exit 1
fi

# Get the list of commits in chronological (oldest to newest) order.
COMMIT_LIST=$(git rev-list --reverse ${START_COMMIT_HASH}..HEAD)
if [ -z "$COMMIT_LIST" ]; then
  echo "No commits found in the specified range."
  exit 1
fi

echo "Found commits to stash. Processing..."

# Loop through each commit hash
for commit_hash in $COMMIT_LIST
do
  # Get the commit subject for the stash message
  commit_subject=$(git log -1 --pretty=%s ${commit_hash})
  echo "Processing commit ${commit_hash:0:7}: ${commit_subject}"

  # KEY IMPROVEMENT: Checkout the parent of the commit to get a clean base state.
  git checkout -q ${commit_hash}~1

  # Create a patch from the commit and apply it to the (now correct) working directory
  git show ${commit_hash} | git apply

  # Create a named stash from the applied changes
  git stash save "Stash of commit ${commit_hash:0:7}: ${commit_subject}"
done

# Restore the user's original branch and working state
echo "✅ Process complete. Restoring original branch..."
git checkout -q $ORIGINAL_BRANCH
git stash list
