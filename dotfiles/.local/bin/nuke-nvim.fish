function main
    # Define the paths to be removed
    set -l nvim_paths \
        "$HOME/.config/nvim" \
        "$HOME/.local/share/nvim" \
        "$HOME/.local/state/nvim" \
        "$HOME/.cache/nvim"

    echo "This script will permanently remove the following Neovim directories:"
    for path in $nvim_paths
        if test -e "$path"
            echo "  - $path"
        end
    end
    echo ""

    # Prompt the user for confirmation using the correct fish syntax
    read -l -P "Are you sure you want to continue? (Y/n): " REPLY
    echo ""

    # Cancel the operation if the user input starts with 'n' or 'N'
    if test -n "$REPLY"; and string match -iq "n*" -- "$REPLY"
        echo "Operation cancelled by user."
        exit 1
    end

    echo "Proceeding with removal..."

    # Loop through and remove each path
    for path in $nvim_paths
        if test -e "$path"
            echo "Removing $path..."
            rm -rf "$path"
        else
            echo "Skipping non-existent path: $path"
        end
    end

    echo ""
    echo "✅ Neovim directories have been nuked."
end

# Run the main function
main
