#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Input Validation ---
# Check if a stash index was provided as the first argument.
if [ -z "$1" ]; then
  echo "❌ Error: No stash index provided."
  echo ""
  echo "Usage: ./update-stash.sh <stash_index>"
  echo ""
  echo "Example:"
  echo "  1. Find the stash you want to replace with 'git stash list'"
  echo "     stash@{0}: On feature-branch: WIP"
  echo "     stash@{1}: On main: Adding new navigation"
  echo "     stash@{2}: On main: Refactoring login page"
  echo ""
  echo "  2. Run the script with the desired stash index (the number only):"
  echo "     ./update-stash.sh 2"
  exit 1
fi

STASH_INDEX=$1

# Add a check to ensure the input is a valid non-negative integer.
if ! [[ "$STASH_INDEX" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Invalid input. Please provide a number (e.g., 0, 1, 2)."
    exit 1
fi

# Construct the full stash ID that git commands understand.
STASH_ID="stash@{$STASH_INDEX}"

# --- 2. Pre-flight Checks ---
# Check if the provided stash ID actually exists before we start.
# We redirect stderr to /dev/null to suppress git's error message.
if ! git rev-parse "$STASH_ID" > /dev/null 2>&1; then
    echo "❌ Error: Stash with index '$STASH_INDEX' (i.e., $STASH_ID) not found."
    git stash list
    exit 1
fi

# Check if there are any local changes to create the new stash with.
# If the working directory is clean, we should stop.
if git diff-index --quiet HEAD --; then
  echo "❌ Error: Working directory is clean. No new changes to create a stash with."
  exit 1
fi


# --- 3. The Workflow ---
# Get the unique commit hash of the stash we want to replace.
# This is safer than relying on the stash index, which will change.
STASH_HASH=$(git rev-parse "$STASH_ID")

# Get the raw message from the target stash using its hash.
RAW_MESSAGE=$(git log -1 --pretty=%s "$STASH_HASH")

# Clean the message: Strip the "On <branch>:" or "WIP on <branch>:" prefix
# that git adds, preventing title duplication on subsequent runs.
STASH_MESSAGE=$(echo "$RAW_MESSAGE" | sed 's/^\(WIP on\|On\) [^:]*: //')


echo "▶️ Starting stash replacement process for '$STASH_ID'..."
echo "  - Stash title: '$STASH_MESSAGE'"

# Create a new stash with the current working directory state
# and the message from the old stash. THIS IS THE SAFE PART.
echo "  - Creating new stash with current changes..."
git stash push -m "$STASH_MESSAGE"

# Now that the new stash is safely created, drop the old one using its hash.
echo "  - Dropping old stash ($STASH_ID)..."
git stash drop "$STASH_HASH"


# --- 4. Final Output ---
echo "✅ Success! Stash '$STASH_ID' has been replaced with your current changes."
echo "New stash list:"
git stash list

