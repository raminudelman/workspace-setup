#!/bin/bash
#
# v2: Imports stashes from patch files, checking out the correct
# branch for each patch before applying it.

set -e

PATCH_DIR="./stashes_with_branch"

if [ ! -d "$PATCH_DIR" ]; then
    echo "❌ Error: Directory '$PATCH_DIR' not found."
    exit 1
fi

# Abort if the working directory isn't clean
if ! git diff --quiet HEAD || ! git diff --cached --quiet; then
    echo "❌ Error: Your working directory is not clean. Please commit or stash changes."
    exit 1
fi

original_branch=$(git rev-parse --abbrev-ref HEAD)
echo "✅ Starting on branch '$original_branch'. Will return here when finished."

patch_files=$(find "$PATCH_DIR" -type f -name "*.patch" | sort -V)
if [ -z "$patch_files" ]; then
    echo "ℹ️ No patch files found in '$PATCH_DIR'."
    exit 0
fi

# --- Main Loop ---
for patch_file in $patch_files; do
    echo "---"
    # Extract headers from the patch file
    target_branch=$(grep '^Stash-Branch:' "$patch_file" | sed 's/Stash-Branch: //')
    stash_msg=$(grep '^Subject: \[STASH\]' "$patch_file" | sed 's/Subject: \[STASH\] //')

    if [ -z "$target_branch" ]; then
        echo "⚠️ Skipping '$patch_file': Could not find 'Stash-Branch:' header."
        continue
    fi
    echo "Processing '$patch_file' for branch '$target_branch'"

    # Checkout the target branch. Fetch from origin if it doesn't exist locally.
    if ! git checkout "$target_branch" > /dev/null 2>&1; then
        echo "   -> Branch '$target_branch' not found locally. Fetching from origin..."
        if ! git fetch origin "$target_branch" || ! git checkout "$target_branch"; then
            echo "❌ Error: Could not checkout branch '$target_branch' from origin. Skipping."
            continue
        fi
    fi

    # Apply the patch
    if ! git apply --reject "$patch_file"; then
        echo "⚠️ Patch did not apply cleanly on '$target_branch'."
        echo "   Please resolve conflicts, then manually run:"
        echo "   git stash push -m \"$stash_msg\""
        git checkout "$original_branch" # Go back before exiting
        exit 1
    fi

    # Create the stash with the original message
    git stash push -m "$stash_msg"
    echo "👍 Successfully created stash on branch '$target_branch'."
done

# --- Cleanup ---
echo "---"
echo "🎉 Import complete. Returning to starting branch."
git checkout "$original_branch"
