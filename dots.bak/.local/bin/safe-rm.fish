#!/usr/bin/env fish

# The main function of the script.
function main
    # Check if the HOME environment variable is set.
    # This is crucial for determining the trash directory location.
    if not set -q HOME; or test -z "$HOME"
        echo "Error: The HOME environment variable is not set. Cannot determine the trash location." >&2
        exit 1
    end

    # Set the trash directory path. It's defined inside main() to ensure it's always
    # set after the HOME variable check.
    set -l TRASH_DIR "$HOME/.local/share/trash/files"

    # Check if any arguments (files/directories) were provided.
    if test (count $argv) -eq 0
        echo "Error: No files or directories specified." >&2
        echo "Usage: safe-rm <file1> [<file2> ...]" >&2
        exit 1
    end

    # Create a list to hold valid targets for moving to trash.
    set -l targets
    for item in $argv
        # Check if the item exists on the filesystem.
        if not test -e "$item"
            echo "Warning: '$item' not found, skipping." >&2
            continue
        end

        # Ensure the trash directory exists.
        mkdir -p "$TRASH_DIR"

        # Resolve absolute paths and store them in variables before comparison.
        set -l item_path (realpath -- "$item")
        set -l trash_path (realpath -- "$TRASH_DIR")

        if test "$item_path" = "$trash_path"
            echo "Warning: Cannot move the trash directory into itself. Skipping '$item'." >&2
            continue
        end

        # Add the valid item to the list of targets.
        set -a targets "$item"
    end

    # If there are no valid targets, exit the script.
    if test (count $targets) -eq 0
        echo "No valid files or directories to move to trash."
        exit 0
    end

    # Inform the user about the impending action.
    echo "The following items will be moved to the trash:"
    printf "  - %s\n" $targets
    echo "Trash location: $TRASH_DIR"
    echo ""

    # Prompt the user for confirmation.
    read -l -P "Are you sure you want to continue? (Y/n): " REPLY
    echo ""

    # FIX: Treat an empty reply (Enter) as "Yes".
    # The operation is cancelled only if the input explicitly starts with 'n' (case-insensitive).
    if test -n "$REPLY"; and string match -iq "n*" -- "$REPLY"
        echo "Operation cancelled by user."
        exit 1
    end

    # Move the specified items to the trash directory.
    echo "Moving items to trash..."
    for item in $targets
        # Generate a unique name for the trashed item to avoid conflicts.
        set -l trashed_name (basename "$item")-(date +%s)-(head -c 5 /dev/urandom | tr -dc A-Za-z-0-9)
        echo " - '$item' -> '$trashed_name'"
        mv -- "$item" "$TRASH_DIR/$trashed_name"
    end

    echo ""
    echo "✅ Operation complete."
    echo "To restore, check the trash directory: $TRASH_DIR"
end

# Call the main function with the script's arguments.
main $argv
