#!/bin/bash
#
# v2: Exports stashes and includes the source branch name in the patch header.

set -e

OUTPUT_DIR="./stashes_with_branch"
mkdir -p "$OUTPUT_DIR"
echo "✅ Saving patches with branch info to '$OUTPUT_DIR/'"

if ! git stash list > /dev/null 2>&1; then
    echo "ℹ️ No stashes found. Exiting."
    exit 0
fi

git stash list | while read -r stash_entry; do
    stash_ref=$(echo "$stash_entry" | awk -F: '{print $1}')
    stash_index=$(echo "$stash_ref" | grep -o '[0-9]\+')

    # --- New logic to extract branch and message ---
    branch_and_msg=$(echo "$stash_entry" | cut -d ':' -f 2-)
    if [[ $branch_and_msg == *"On "* ]]; then
        # Stash was on a specific branch, e.g., " On main: ..."
        branch_name=$(echo "$branch_and_msg" | sed -n 's/ On \(.*\): .*/\1/p')
        stash_msg=$(echo "$branch_and_msg" | cut -d ':' -f 2- | sed 's/^ *//')
    else
        # Stash was in a detached HEAD state, e.g., " (no branch): ..."
        branch_name="(no branch)"
        stash_msg=$(echo "$branch_and_msg" | sed 's/^ *//')
    fi
    # --- End new logic ---

    filename="${OUTPUT_DIR}/stash-${stash_index}.patch"
    echo "   -> Creating patch for $stash_ref on branch '$branch_name'"

    # --- Write new headers to the file ---
    echo "Stash-Branch: $branch_name" > "$filename"
    echo "Subject: [STASH] $stash_msg" >> "$filename"
    echo "" >> "$filename"

    git stash show -p "$stash_ref" >> "$filename"
done

echo "🎉 Done! All patches exported with branch information."
