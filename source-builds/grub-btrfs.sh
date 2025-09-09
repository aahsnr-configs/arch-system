#!/bin/bash

# This script installs grub-btrfs from its official GitHub repository.
# It's designed to be robust, handle errors gracefully, and clean up after itself.
# It checks for necessary dependencies and provides clear instructions.

# --- Configuration ---
REPO_URL="https://github.com/Antynea/grub-btrfs.git"
TEMP_DIR="" # This will be set by mktemp -d

# --- Functions ---

# Function to display error messages and exit
error_exit() {
  echo "ERROR: $1" >&2
  cleanup # Attempt to clean up before exiting
  exit 1
}

# Function to check for required dependencies
check_dependencies() {
  echo "Checking for required dependencies..."

  # Check for git
  if ! command -v git &>/dev/null; then
    error_exit "Git is not installed. Please install it using 'sudo dnf install git' (Fedora) or 'sudo apt install git' (Debian/Ubuntu)."
  fi

  # Check for sudo
  if ! command -v sudo &>/dev/null; then
    error_exit "Sudo is not installed. This script requires sudo to run the grub-btrfs installation script."
  fi

  echo "All required dependencies are present."
}

# Function to clean up temporary files
cleanup() {
  if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    echo "Cleaning up temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
  fi
}

# Main installation function
install_grub_btrfs() {
  echo "Starting grub-btrfs installation from source..."
  echo "Repository: $REPO_URL"

  # Create a temporary directory for cloning
  TEMP_DIR=$(mktemp -d -t grub-btrfs-XXXXXX) || error_exit "Failed to create temporary directory."
  echo "Temporary download directory: $TEMP_DIR"

  # Set a trap to ensure cleanup happens even if the script is interrupted
  trap cleanup EXIT INT TERM

  # Clone the repository
  echo "Cloning grub-btrfs repository into $TEMP_DIR..."
  if ! git clone "$REPO_URL" "$TEMP_DIR"; then
    error_exit "Failed to clone the repository. Check your internet connection or the repository URL."
  fi

  # Change to the cloned directory
  if ! cd "$TEMP_DIR"; then
    error_exit "Failed to change to the temporary directory: $TEMP_DIR"
  fi

  # Run the installation script provided by grub-btrfs
  echo "Executing the grub-btrfs installation script..."
  echo "You may be prompted for your sudo password."
  if ! sudo ./install.sh; then
    error_exit "The grub-btrfs installation script failed. Please review the output above for errors."
  fi

  echo "grub-btrfs installation script completed successfully."
}

# --- Main Execution ---

# Exit immediately if a command exits with a non-zero status.
set -e

# Call functions in order
check_dependencies
install_grub_btrfs

echo ""
echo "--- Installation Summary ---"
echo "grub-btrfs has been installed from source."
echo "IMPORTANT: You now need to update your GRUB configuration to detect Btrfs snapshots."
echo "For most systems (including Fedora), run one of the following commands:"
echo "  sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
echo "  (or for older setups/other distros: sudo grub-mkconfig -o /boot/grub/grub.cfg)"
echo ""
echo "If you encounter issues, refer to the grub-btrfs documentation on GitHub:"
echo "  $REPO_URL"

# Cleanup is handled by the trap on exit, but explicitly call it for clarity if script finishes normally
cleanup
