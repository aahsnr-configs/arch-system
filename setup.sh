#!/usr/bin/env bash

# =================================================================================== #
# Hyprland Arch Linux Setup Script
#
# This script automates the setup of a complete Hyprland Environment on Arch Linux.
# It is a robust, idempotent, and modular script that reads package lists
# from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
# =================================================================================== #

# --- Script Features ---
#   - Automatic hardware detection for ASUS setups.
#   - Full logging of all operations to a timestamped log file.
#   - Idempotent design: safe to re-run without causing issues.
#   - Upfront dependency checking and installation.
#   - Robust execution of user-specific commands via a privilege de-escalation function.
#   - Fully interactive package management for user confirmation.
#   - Embedded documentation accessible via '--docs' and per-task via '--<task> --docs'.

# --- Script Task Order (Full Installation) ---
#   1.  Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.
#       (Includes automatic setup of the 'yay' AUR helper if not present).
#   2.  Initial Setup: Optimizes pacman.conf, makepkg.conf, and environment variables.
#   3.  Setup Extra Repos (Optional): Adds CachyOS and BlackArch repositories.
#   4.  Install Kernel and Drivers (Optional): Installs the CachyOS kernel and NVIDIA drivers.
#   5.  Setup for ASUS Laptops (Optional): Adds the g14 repo and installs specific tools.
#   6.  Setup Greeter: Configures greetd and tuigreet as the login manager.
#   7.  Setup Nix & Home-Manager (Optional): Installs and configures Nix with flakes.
#   8.  Install Packages: Installs packages from 'packages.txt' using the AUR helper.
#   9.  Manual Installs: Installs third-party software like themes and VPNs.
#   10. Harden System: Implements basic security enhancements and enables services.
#   11. Configure User: Sets up the user's dotfiles, shell, and services.
#   12. Cleanup: Removes orphaned packages and cleans the Nix store.

# --- Script Setup and Error Handling ---
# -e: exit immediately if a command exits with a non-zero status. This prevents
#     errors from cascading and causing unintended side effects.
# -u: treat unset variables as an error when substituting. This helps catch
#     typos and logic errors.
# -o pipefail: the return value of a pipeline is the status of the last command
#              to exit with a non-zero status. Without this, a pipeline like
#              'command_that_fails | command_that_succeeds' would be considered
#              a success.
set -euo pipefail

# --- Cleanup Trap ---
# Ensures temporary files created via 'mktemp' are removed when the script exits
# for any reason (success, error, or interruption).
TEMP_FILES=()
cleanup() {
  set +x # Disable command tracing during cleanup
  if [ ${#TEMP_FILES[@]} -gt 0 ]; then
    rm -rf "${TEMP_FILES[@]}"
  fi
}
trap cleanup EXIT ERR INT TERM

# --- User Interface: Colors and Icons ---
readonly C_HEADER='\033[95m'
readonly C_BLUE='\033[94m'
readonly C_GREEN='\033[92m'
readonly C_YELLOW='\033[93m'
readonly C_RED='\033[91m'
readonly C_BOLD='\033[1m'
readonly C_CYAN='\033[96m'
readonly C_END='\033[0m'

readonly I_STEP="⚙️"
readonly I_INFO="ℹ️"
readonly I_SUCCESS="✅"
readonly I_WARN="⚠️"
readonly I_ERROR="❌"
readonly I_PROMPT="❓"
readonly I_FINISH="🎉"
readonly I_DEBUG="🐞"
readonly I_LOG="📄"

# --- UI Helper Functions ---
print_step() { echo -e "\n${C_HEADER}${C_BOLD}═══ $I_STEP $1 ═══${C_END}"; }
print_info() { echo -e "${C_BLUE}$I_INFO $1${C_END}"; }
print_success() { echo -e "${C_GREEN}$I_SUCCESS $1${C_END}"; }
print_warning() { echo -e "${C_YELLOW}$I_WARN $1${C_END}" >&2; }
print_error() { echo -e "${C_RED}$I_ERROR $1${C_END}" >&2; }
print_debug() {
  if [ "$DEBUG_MODE" = true ]; then
    echo -e "${C_CYAN}$I_DEBUG [DEBUG] $1${C_END}" >&2
  fi
}

# --- Global Configuration ---
TARGET_USER=""
if ! TARGET_USER=$(logname); then
  print_error "Could not determine the current user with 'logname'. Aborting."
  exit 1
fi
readonly TARGET_USER

USER_HOME=""
if ! USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6); then
  print_error "Could not determine home directory for user '$TARGET_USER'. Aborting."
  exit 1
fi
readonly USER_HOME

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
readonly SCRIPT_DIR
readonly PRECONFIG_DIR="$SCRIPT_DIR/preconfig"

LOG_FILE="setup-log-$(date +%F_%H-%M).log"
readonly LOG_FILE

DEBUG_MODE=false

# --- Modular Documentation Functions ---

docs_initial_setup() {
cat <<'EOF'
[ --initial-setup ] - Documentation

Configures core system files for a better user experience and performance.

Actions:
- Modifies '/etc/pacman.conf' to:
  - Enable colored output ('Color').
  - Enable verbose package lists ('VerbosePkgLists').
  - Enable parallel downloads ('ParallelDownloads = 10') for significantly
    faster package installation and updates.
  - Enable the 'ILoveCandy' pacman animation for fun.
- Overwrites '/etc/makepkg.conf' with the contents of 'preconfig/makepkg.conf.txt'.
  This is used to optimize package compilation from the AUR by setting compiler
  flags (e.g., '-march=native') and parallel compilation.
- Copies custom environment variables from 'preconfig/99-custom-env.sh.txt' to
  '/etc/profile.d/99-custom-env.sh', making them available system-wide.

User Interaction:
- After applying changes, it will display the contents of the modified files and
  prompt you for interactive verification before proceeding.
EOF
}

docs_setup_extra_repos() {
cat <<'EOF'
[ --setup-extra-repos ] - Documentation

Adds and configures third-party pacman repositories.

Actions:
- CachyOS: Adds the repository for performance-optimized packages and the
  CachyOS kernel. The CachyOS setup script is interactive and will prompt you
  for decisions regarding trust and key signing.
- BlackArch: Adds the repository for penetration testing and security tools.
- Forces a full system database sync and upgrade ('yay -Syyu') after adding
  the new repositories to ensure the system is up-to-date.

Prerequisites:
- A stable internet connection.
EOF
}

docs_kernel_and_drivers() {
cat <<'EOF'
[ --kernel-and-drivers ] - Documentation

Installs the CachyOS kernel and the corresponding open-source NVIDIA drivers.

Prerequisites:
- The CachyOS repository must be enabled first (via '--setup-extra-repos').
  The script will skip this task if the repo is not found.

Actions:
- Installs the following packages:
  - 'linux-cachyos': The performance-optimized kernel.
  - 'linux-cachyos-headers': Required for building kernel modules (e.g., for VirtualBox).
  - 'linux-cachyos-nvidia-open': The open-source NVIDIA driver modules specifically
    built for this kernel.
  - 'nvidia-utils', 'lib32-nvidia-utils', etc.: The standard NVIDIA driver stack.

Required Follow-up Actions:
- After this task completes, you MUST manually update your bootloader configuration
  to make the new kernel bootable. Examples:
  - For GRUB: 'sudo grub-mkconfig -o /boot/grub/grub.cfg'
  - For systemd-boot: 'sudo bootctl update'
EOF
}

docs_setup_asus() {
cat <<'EOF'
[ --setup-asus ] - Documentation

Performs hardware-specific setup for ASUS laptops.

Prerequisites:
- The script automatically detects ASUS hardware via 'dmidecode'. If your system is
  not identified as "ASUS", this task will be skipped.

Actions:
- Adds the 'g14' repository (https://arch.asus-linux.org), which contains
  specialized tools for ASUS laptops.
- Imports and signs the GPG key required to trust the 'g14' repository.
- Installs packages like 'asusctl', 'supergfxctl', and 'rog-control-center'.
- Enables the systemd services required for these tools ('power-profiles-daemon.service',
  'supergfxd.service', etc.) to manage power profiles, graphics switching (Optimus),
  and keyboard lighting.
EOF
}

docs_setup_greetd() {
cat <<'EOF'
[ --setup-greetd ] - Documentation

Configures a lightweight, terminal-based display manager (login screen).

Actions:
- Installs 'greetd' and the 'tuigreet' greeter.
- Creates the configuration file at '/etc/greetd/config.toml' and sets it to
  launch a Hyprland session by default.
- It will automatically detect if 'sddm' (the default KDE display manager) is
  installed. If found, it disables the SDDM service and removes the package to
  avoid conflicts.
- Enables the 'greetd.service' to launch at boot.
EOF
}

docs_setup_nix() {
cat <<'EOF'
[ --setup-nix ] - Documentation

Installs and configures the Nix package manager with Home-Manager and Flakes.

User Interaction:
- This step is interactive. It uses the official Determinate Systems installer,
  which will prompt you to confirm the installation.

Actions:
- Downloads and runs the Determinate Systems installer for a robust, multi-user Nix
  installation.
- Creates a configuration file at '~/.config/nix/nix.conf' to enable the modern
  'nix-command' and 'flakes' experimental features.
- Initializes and runs Home-Manager, a tool for declaratively managing a user's
  dotfiles and packages within the Nix ecosystem. It performs an initial activation.
EOF
}

docs_install_packages() {
cat <<'EOF'
[ --install-packages ] - Documentation

The main package installation task.

Configuration:
- This task reads package names line-by-line from 'preconfig/packages.txt'.
- Lines starting with '#' and empty lines in the file are ignored.

Actions:
- Uses 'yay' to install all listed packages from both the official Arch
  repositories and the Arch User Repository (AUR).
- You will be prompted by 'yay' to confirm the installation and review any
  PKGBUID diffs for AUR packages.
EOF
}

docs_manual_installations() {
cat <<'EOF'
[ --manual-installs ] - Documentation

Handles software that cannot be installed through a package manager.

Actions:
- The current implementation downloads and runs the official installer for the
  Private Internet Access (PIA) VPN client.
- The installer URL is hardcoded and may become outdated.
- This section can be customized by editing the 'task_manual_installations'
  function to add other similar installers.
EOF
}

docs_harden_system() {
cat <<'EOF'
[ --harden-system ] - Documentation

Applies a variety of security enhancements to the system.

Actions:
- Installs security-focused packages (AppArmor, Audit, UFW, etc.).
- Enables core security services like 'auditd' (for system auditing) and 'apparmor'
  (for mandatory access control).
- Hardens the SSH server configuration in '/etc/ssh/sshd_config.d/' by disabling
  root login, disabling password authentication (forcing key-based auth), and
  changing the default port.
- Configures the UFW firewall to deny incoming traffic by default, allowing
  only the custom SSH port.
- Applies secure kernel runtime parameters via '/etc/sysctl.d/99-custom-hardening.conf'
  to mitigate certain classes of vulnerabilities.
- Hardens '/proc' filesystem access by adding 'hidepid=2' to the '/etc/fstab' entry,
  which prevents users from seeing each other's processes.
EOF
}

docs_configure_user() {
cat <<'EOF'
[ --configure-user ] - Documentation

Performs user-specific setup for the target user's environment.

Actions:
- Sets the default user shell to 'fish' using 'chsh'.
- Configures 'npm' to use a local directory ('~/.npm-global') for global
  package installations, avoiding the need for 'sudo'.
- Enables and starts user-level systemd services required for the Hyprland
  desktop environment to function correctly, such as:
  - 'pipewire' and 'wireplumber' (for audio).
  - 'hypridle' and 'hyprpaper' (for idle management and wallpaper).
EOF
}

docs_cleanup() {
cat <<'EOF'
[ --cleanup ] - Documentation

Performs system maintenance tasks to free up disk space.

Actions:
- Removes orphaned packages using 'yay -Rns $(pacman -Qtdq)'. Orphaned packages
  are dependencies that were installed for another package but are no longer
  required by any installed package on the system.
- If Nix is installed, it runs 'nix-collect-garbage -d' to remove old, unreferenced
  package generations from the Nix store.
EOF
}

# Displays the full, embedded documentation for the entire script.
print_documentation() {
    cat <<'EOF'
================================================================================
Hyprland Arch Linux Setup Script - Full Documentation
================================================================================

This script provides a comprehensive, automated, and idempotent method for
setting up a feature-rich Hyprland desktop environment on a fresh Arch Linux
installation. It is modular, allowing you to run the entire setup at once or
execute specific tasks individually using flags.

EOF
    docs_initial_setup
    docs_setup_extra_repos
    docs_kernel_and_drivers
    docs_setup_asus
    docs_setup_greetd
    docs_setup_nix
    docs_install_packages
    docs_manual_installations
    docs_harden_system
    docs_configure_user
    docs_cleanup
}

# Displays a brief usage summary.
print_usage() {
  echo -e "${C_BOLD}Usage: $0 [OPTIONS...]${C_END}"
  echo "Automates the setup of a complete Hyprland Environment on Arch Linux."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks interactively.${C_END}"
  echo ""
  echo -e "${C_HEADER}Options:${C_END}"
  echo -e "  ${C_GREEN}--initial-setup${C_END}           Perform initial system setup."
  echo -e "  ${C_GREEN}--setup-extra-repos${C_END}       Set up CachyOS and BlackArch repositories."
  echo -e "  ${C_GREEN}--kernel-and-drivers${C_END}      Install CachyOS kernel and NVIDIA drivers."
  echo -e "  ${C_GREEN}--setup-asus${C_END}              Run specific setup for ASUS laptops."
  echo -e "  ${C_GREEN}--setup-greetd${C_END}            Setup greetd and tuigreet as the login manager."
  echo -e "  ${C_GREEN}--setup-nix${C_END}               Install and configure Nix with Home-Manager."
  echo -e "  ${C_GREEN}--install-packages${C_END}        Install packages from 'packages.txt'."
  echo -e "  ${C_GREEN}--manual-installs${C_END}         Perform manual installation of third-party software."
  echo -e "  ${C_GREEN}--harden-system${C_END}           Implement basic security enhancements."
  echo -e "  ${C_GREEN}--configure-user${C_END}          Set up the user's environment."
  echo -e "  ${C_GREEN}--cleanup${C_END}                 Remove orphaned packages from the system."
  echo -e "  ${C_YELLOW}--debug${C_END}                   Enable verbose command tracing for debugging."
  echo -e "  ${C_BLUE}--help${C_END}                    Display this help message and exit."
  echo -e "  ${C_BLUE}--docs${C_END}                    Display the full embedded documentation and exit."
  echo ""
  echo -e "${C_BOLD}To view docs for a specific task, use: $0 --<task-name> --docs${C_END}"
  echo -e "  Example: $0 --setup-nix --docs"

}

# --- Utility Functions ---

# Checks if a command exists in the current PATH.
command_exists() { command -v "$1" &>/dev/null; }

# Checks if a package is installed via pacman.
is_pkg_installed() { pacman -Q "$1" &>/dev/null; }

# De-escalates privileges to run a command as the original user.
# The 'export' commands are crucial for creating a clean, predictable environment for
# the command being run. This ensures that user-specific config files (e.g., in ~/.config)
# are located correctly and that file ownership is preserved.
run_as_user() {
  sudo -u "$TARGET_USER" bash -c "export HOME='$USER_HOME'; export USER='$TARGET_USER'; $*"
}

# Wrapper for package installation commands.
# The '< /dev/tty' redirection is critical. It forces the standard input of the 'yay'
# command to be the controlling terminal, not the script's stdout pipe. This ensures
# that 'yay' remains interactive (i.e., it can prompt the user for confirmation) even
# when the script's overall output is being redirected to a log file via 'tee'.
install_pkgs() {
  print_warning "You will be prompted to confirm the installation of the following packages: $*"
  yay -S --needed "$@" < /dev/tty
}

# Wrapper for package removal commands.
remove_pkgs() {
  print_warning "You will be prompted to confirm the removal of the following packages: $*"
  yay -Rns "$@" < /dev/tty
}

# --- Task Functions ---

# Installs 'yay-bin' as the AUR helper. This function is called by pre_flight_checks if needed.
task_setup_aur_helper() {
  # This check prevents re-running the installation if the function is ever called twice.
  if command_exists yay; then
    print_success "AUR helper 'yay' is already installed."
    return
  fi

  print_step "Setting up AUR Helper (yay)"
  print_info "Installing 'yay-bin' from the AUR..."
  
  # Ensure base-devel and git are present before trying to build anything from the AUR.
  if ! is_pkg_installed git || ! is_pkg_installed make; then
      print_info "Installing 'git' and 'base-devel' to build the AUR helper..."
      sudo pacman -S --needed --noconfirm git base-devel
  fi

  local tmp_dir
  tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  sudo git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir"
  sudo chown -R "$TARGET_USER:$TARGET_USER" "$tmp_dir"
  (
    cd "$tmp_dir"
    print_info "Building and installing 'yay-bin'..."
    print_warning "You will be prompted to confirm the build and installation."
    run_as_user "makepkg -si < /dev/tty"
  )
  print_success "'yay' has been installed successfully."
}

# Verifies that the script is run in a valid environment before executing tasks.
pre_flight_checks() {
  print_step "Running Pre-flight Checks"

  # --- 1. System and Privilege Verification ---
  if [[ $EUID -eq 0 ]]; then
    print_error "This script must be run as a regular user, not root. Aborting."
    exit 1
  fi
  if ! command_exists sudo; then
    print_error "'sudo' command not found. Aborting."
    exit 1
  fi
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    print_error "No internet connection. Aborting."
    exit 1
  fi

  # --- 2. AUR Helper and Dependency Installation ---
  # Ensure yay is available, as it's the script's primary package manager for all tasks.
  if ! command_exists yay; then
    task_setup_aur_helper
  fi

  # Check for necessary script dependencies and prompt to install if missing.
  local missing_pkgs=()
  for pkg in neovim wl-clipboard curl wget pciutils dmidecode; do
    if ! is_pkg_installed "$pkg"; then
      missing_pkgs+=("$pkg")
    fi
  done

  if ((${#missing_pkgs[@]} > 0)); then
    print_info "Installing missing script dependencies..."
    install_pkgs "${missing_pkgs[@]}"
  fi

  # --- 3. Configuration File Verification ---
  # Check for required external configuration files.
  local required_files=("$PRECONFIG_DIR/packages.txt" "$PRECONFIG_DIR/makepkg.conf.txt" "$PRECONFIG_DIR/99-custom-env.sh.txt")
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      print_error "Required configuration file '$file' not found. Aborting."
      exit 1
    fi
  done

  print_info "Priming sudo. You may be asked for your password now."
  sudo -v
  print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

# Sets up environment variables, Pacman, and Makepkg configurations.
task_initial_setup() {
  print_step "Performing Initial System Setup"

  # --- Copy custom environment variables ---
  print_info "Copying custom environment variables to /etc/profile.d/..."
  sudo cp "$PRECONFIG_DIR/99-custom-env.sh.txt" "/etc/profile.d/99-custom-env.sh"
  sudo chmod +x "/etc/profile.d/99-custom-env.sh"
  print_success "Custom environment variables installed."

  # --- Modify pacman.conf ---
  print_info "Modifying /etc/pacman.conf..."
  # Enable colored output in pacman
  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
  # Add a little pacman animation for fun
  sudo sed -i '/^#\(Color\)/a ILoveCandy' /etc/pacman.conf
  # Show more package details during installation
  sudo sed -i 's/^#\(VerbosePkgLists\)/\1/' /etc/pacman.conf
  # Prevent timeouts on slow connections
  sudo sed -i 's/^#\(DisableDownloadTimeout\)/\1/' /etc/pacman.conf
  # Enable parallel downloads for faster package installation
  sudo sed -i 's/^#\(ParallelDownloads\).*/\1 = 10/' /etc/pacman.conf
  if ! grep -q "^DownloadUser" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a DownloadUser = alpm' /etc/pacman.conf
  else
    sudo sed -i 's/^DownloadUser.*/DownloadUser = alpm/' /etc/pacman.conf
  fi
  print_success "pacman.conf modifications applied."

  # --- Overwrite makepkg.conf ---
  print_info "Overwriting /etc/makepkg.conf with contents from makepkg.conf.txt..."
  if sudo cp "$PRECONFIG_DIR/makepkg.conf.txt" "/etc/makepkg.conf"; then
    print_success "Successfully updated /etc/makepkg.conf."
  else
    print_error "Failed to copy makepkg.conf.txt to /etc/makepkg.conf. Aborting."
    exit 1
  fi

  # --- Interactive Verification Loop ---
  local verified=false
  while [ "$verified" = false ]; do
    print_step "Verify Configuration Files"
    echo -e "${C_HEADER}Current /etc/pacman.conf:${C_END}"
    cat /etc/pacman.conf
    echo -e "\n${C_HEADER}Current /etc/makepkg.conf:${C_END}"
    cat /etc/makepkg.conf

    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Are these configurations okay? [Y/n/edit]: ${C_END}")" -r choice
    case "$choice" in
    [Yy]* | "") # Default to Yes
      print_success "Configuration approved."
      verified=true
      ;;
    [Nn]*)
      print_error "Configuration rejected. Aborting script."
      exit 1
      ;;
    [Ee]*)
      read -p "$(echo -e "${C_CYAN}${I_PROMPT} Which file to edit? [p(acman)/m(akepkg)]: ${C_END}")" -r edit_choice
      case "$edit_choice" in
      [Pp]*) sudo nvim /etc/pacman.conf ;;
      [Mm]*) sudo nvim /etc/makepkg.conf ;;
      *) print_warning "Invalid selection." ;;
      esac
      ;;
    *) print_warning "Invalid input." ;;
    esac
  done
}

# Sets up CachyOS and BlackArch repositories.
task_setup_extra_repos() {
  print_step "Setting up Extra Repositories (CachyOS & BlackArch)"

  # --- CachyOS Setup ---
  if grep -q "\[cachyos\]" /etc/pacman.conf; then
    print_success "CachyOS repository is already configured."
  else
    print_info "Setting up the CachyOS repository..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    TEMP_FILES+=("$tmp_dir")
    (
      cd "$tmp_dir"
      curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
      tar xvf cachyos-repo.tar.xz
      cd cachyos-repo
      print_warning "The CachyOS setup script is interactive. Please follow the prompts."
      sudo ./cachyos-repo.sh
    )
    print_success "CachyOS repository setup finished."
  fi

  # --- BlackArch Setup ---
  if grep -q "\[blackarch\]" /etc/pacman.conf; then
    print_success "BlackArch repository is already configured."
  else
    print_info "Setting up the BlackArch repository..."
    local strap_sh
    strap_sh=$(mktemp)
    TEMP_FILES+=("$strap_sh")
    curl -o "$strap_sh" https://blackarch.org/strap.sh
    chmod +x "$strap_sh"
    sudo bash "$strap_sh"
    print_success "BlackArch repository setup finished."
  fi

  print_info "Synchronizing databases and upgrading system..."
  print_warning "You will be prompted to confirm the system upgrade."
  yay -Syyu < /dev/tty
}

# Installs the CachyOS kernel and corresponding NVIDIA drivers.
task_kernel_and_drivers() {
  print_step "Installing CachyOS Kernel and NVIDIA Drivers"
  if ! grep -q "\[cachyos\]" /etc/pacman.conf; then
    print_warning "CachyOS repository is not enabled. Skipping."
    return
  fi

  print_info "Installing CachyOS kernel and corresponding NVIDIA drivers..."
  install_pkgs linux-cachyos linux-cachyos-headers linux-cachyos-nvidia-open nvidia-utils lib32-nvidia-utils \
    nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader libva-nvidia-driver

  print_warning "CachyOS kernel and NVIDIA drivers have been installed. You must regenerate your bootloader configuration (e.g., 'grub-mkconfig' or 'bootctl update') to use it."
  print_success "CachyOS kernel and driver installation complete."
}

# Installs special drivers and tools for ASUS laptops from the g14 repo.
task_setup_asus() {
  print_step "Setting up for ASUS Laptops (using g14 Repository)"
  if ! sudo dmidecode -s system-manufacturer | grep -qi "ASUS"; then
    print_warning "ASUS hardware not detected. Skipping."
    return
  fi

  local g14_key_id="8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"
  print_info "Configuring GPG key for the g14 repository..."
  if sudo pacman-key --list-keys | grep -q "$g14_key_id"; then
    print_success "GPG key '$g14_key_id' is already present."
  else
    print_info "Receiving and signing GPG key '$g14_key_id'..."
    sudo pacman-key --recv-keys "$g14_key_id"
    sudo pacman-key --lsign-key "$g14_key_id"
    print_success "GPG key setup complete."
  fi

  print_info "Configuring the [g14] repository in /etc/pacman.conf..."
  if grep -q "\[g14\]" /etc/pacman.conf; then
    print_success "The [g14] repository is already configured."
  else
    print_info "Adding [g14] repository to /etc/pacman.conf..."
    local g14_repo_conf
    g14_repo_conf=$( cat <<'EOF'

[g14]
Server = https://arch.asus-linux.org
EOF
    )
    echo "$g14_repo_conf" | sudo tee -a /etc/pacman.conf >/dev/null
    print_info "Synchronizing databases with the new repository..."
    yay -Syu < /dev/tty
  fi

  print_info "Installing ASUS-specific packages from the g14 repository..."
  local asus_packages=("asusctl" "power-profiles-daemon" "supergfxctl" "switcheroo-control" "rog-control-center")
  install_pkgs "${asus_packages[@]}"

  print_info "Enabling required system services for ASUS hardware..."
  sudo systemctl daemon-reload
  sudo systemctl enable --now power-profiles-daemon.service
  sudo systemctl enable --now supergfxd.service
  sudo systemctl enable --now switcheroo-control.service
  print_success "ASUS services enabled."
}

# Sets up greetd with tuigreet as a lightweight, terminal-based login manager.
task_setup_greetd() {
  print_step "Setting up greetd and tuigreet"

  install_pkgs greetd greetd-tuigreet

  print_info "Configuring greetd to use tuigreet with Hyprland..."
  local greetd_config_content
  greetd_config_content=$( cat <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "greeter"
EOF
  )
  sudo mkdir -p /etc/greetd
  echo "$greetd_config_content" | sudo tee /etc/greetd/config.toml >/dev/null
  print_success "greetd configuration written."

  print_info "Checking for and removing SDDM..."
  if is_pkg_installed sddm; then
    if systemctl is-enabled --quiet sddm.service &>/dev/null; then
      print_info "Disabling SDDM service..."
      sudo systemctl disable sddm.service
    fi
    remove_pkgs sddm
    print_success "SDDM has been removed."
  else
    print_success "SDDM is not installed. Skipping removal."
  fi

  print_info "Enabling the greetd service..."
  sudo systemctl enable greetd.service

  print_success "greetd setup complete."
}

# Installs and configures Nix, Flakes, and Home-Manager.
task_setup_nix() {
  print_step "Setting up Nix, Home-Manager, and Flakes"

  local nix_daemon_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

  if [ ! -d "/nix/store" ]; then
    print_info "Nix installation not found. Installing with the Determinate Systems installer..."
    local nix_installer
    nix_installer=$(mktemp)
    TEMP_FILES+=("$nix_installer")

    print_info "Downloading the Determinate Nix installer script..."
    if ! curl -fsSL -o "$nix_installer" https://install.determinate.systems/nix; then
      print_error "Failed to download Nix installer. Aborting Nix setup."
      return 1
    fi
    chmod +x "$nix_installer"
    sudo chown "$TARGET_USER:$TARGET_USER" "$nix_installer"

    print_warning "The interactive Nix installer will now launch. Please follow the prompts."
    run_as_user "$nix_installer install --determinate < /dev/tty"
  else
    print_success "Nix appears to be already installed."
  fi

  if [ -f "$nix_daemon_profile" ]; then
    print_info "Sourcing Nix environment profile for this session..."
    # Sourcing the profile script makes the 'nix' command available to the *current*
    # running script instance, which is necessary to proceed with configuration.
    # shellcheck disable=SC1090
    . "$nix_daemon_profile"
  else
    print_error "Nix profile script '$nix_daemon_profile' not found."
    return 1
  fi

  if ! command_exists nix; then
    print_error "'nix' command is not available even after sourcing the profile."
    return 1
  fi

  print_info "Ensuring Nix is configured with flakes and optimizations..."
  local nix_config_dir="$USER_HOME/.config/nix"
  local nix_config_file="$nix_config_dir/nix.conf"
  local nix_conf_content
  nix_conf_content=$( cat <<'EOF'
experimental-features = nix-command flakes
max-jobs = 4
EOF
  )
  run_as_user "mkdir -p '$nix_config_dir'"
  run_as_user "echo -e \"$nix_conf_content\" > \"$nix_config_file\""

  local nix_cmd_prefix=". '$nix_daemon_profile';"

  print_info "Initializing Home-Manager..."
  if run_as_user "[ -d '$USER_HOME/.config/home-manager' ]" && command_exists home-manager; then
    print_success "Home-Manager seems to be already initialized."
  else
    run_as_user "$nix_cmd_prefix nix run home-manager/master -- init --switch"
  fi

  print_info "Switching to the new Home-Manager configuration..."
  # The first 'home-manager switch' can sometimes fail if it tries to overwrite
  # an existing file. Retrying with a backup flag (-b) is a common and safe
  # workaround to resolve this.
  if ! run_as_user "$nix_cmd_prefix home-manager switch"; then
    print_warning "Initial 'home-manager switch' failed. Retrying with backup flag..."
    run_as_user "$nix_cmd_prefix home-manager switch -b backup"
    run_as_user "$nix_cmd_prefix home-manager switch"
  fi
  print_success "Home-Manager switch complete."

  local hm_session_vars="$USER_HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  if run_as_user "[ -f '$hm_session_vars' ]"; then
    print_info "Sourcing Home-Manager session variables..."
    run_as_user ". '$hm_session_vars'"
  fi
  print_success "Nix, Home-Manager, and Flakes setup complete."
}

# Reads the package list from 'packages.txt' and installs them.
task_install_packages() {
  print_step "Installing System Packages from File"
  mapfile -t packages_to_install < <(grep -vE '^\s*#|^\s*$' "$PRECONFIG_DIR/packages.txt")
  if ((${#packages_to_install[@]} == 0)); then
    print_warning "No packages found in 'packages.txt'. Skipping."
    return
  fi
  install_pkgs "${packages_to_install[@]}"
}

# Installs third-party software that is not available in standard repositories.
task_manual_installations() {
  print_step "Performing Manual Installations"

  if command_exists pia-client; then
    print_success "Private Internet Access is already installed."
  else
    print_info "Installing Private Internet Access (PIA) VPN."
    print_warning "The PIA installer URL is version-specific and may become outdated."
    local pia_url="https://installers.privateinternetaccess.com/download/pia-linux-3.6.2-08398.run"
    local pia_installer
    pia_installer=$(mktemp --suffix=.run)
    TEMP_FILES+=("$pia_installer")
    print_info "Downloading PIA installer..."
    wget -O "$pia_installer" "$pia_url"
    chmod +x "$pia_installer"
    print_warning "The PIA installer will now launch."
    bash "$pia_installer" < /dev/tty
    print_success "PIA VPN installation process finished."
  fi
}

# Applies system-wide security hardening configurations.
task_harden_system() {
  print_step "Applying System Security Hardening"

  # --- 1. Install Security Packages ---
  print_info "Installing security packages..."
  local security_packages=(
    acct apparmor apparmor.d-git audit arch-audit openssh procps-ng rng-tools
    sysstat haveged lynis-git libpwquality bleachbit ufw
  )
  install_pkgs "${security_packages[@]}"

  # --- 2. Enable Core Services ---
  print_info "Enabling core security services..."
  local system_services=(acct auditd apparmor haveged rngd sshd)
  for service in "${system_services[@]}"; do
    if sudo systemctl enable --now "${service}.service"; then
      print_success "Enabled '$service'."
    else
      print_warning "Could not enable '$service'."
    fi
  done

  # --- 3. Configure Auditing ---
  print_info "Configuring audit framework..."
  if ! grep -q '^audit:' /etc/group; then
    sudo groupadd -r audit && print_success "Created 'audit' group."
  fi
  sudo gpasswd -a "$TARGET_USER" audit
  if ! grep -q "^\s*log_group = audit" /etc/audit/auditd.conf; then
    echo "log_group = audit" | sudo tee -a /etc/audit/auditd.conf >/dev/null
    sudo systemctl restart auditd.service
    print_success "Audit configuration applied."
  fi

  # --- 4. Harden SSH and Firewall ---
  print_info "Hardening OpenSSH server configuration..."
  local sshd_hardening_content
  sshd_hardening_content=$( cat <<'EOF'
# Custom hardening rules
Port 47
LogLevel VERBOSE
# Disabling password authentication is a critical security measure that
# forces the use of more secure SSH keys.
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
X11Forwarding no
EOF
  )
  sudo mkdir -p /etc/ssh/sshd_config.d
  echo "$sshd_hardening_content" | sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null
  sudo systemctl reload sshd
  print_success "SSH configuration reloaded."

  if command_exists ufw; then
    print_info "Configuring UFW firewall..."
    sudo ufw allow 47/tcp comment 'Custom SSH Port'
    sudo ufw deny 22/tcp comment 'Default SSH Port'
    sudo ufw --force enable
    print_success "UFW enabled and configured for SSH on port 47."
  fi

  # --- 5. Harden Kernel at Runtime ---
  print_info "Applying custom sysctl kernel settings..."
  local sysctl_file="/etc/sysctl.d/99-custom-hardening.conf"
  local sysctl_content
  sysctl_content=$( cat <<'EOF'
# Restrict access to kernel pointers, mitigating KASLR bypasses.
kernel.kptr_restrict = 2
# Disable the SysRq key entirely.
kernel.sysrq = 0
# Prevent unprivileged users from using the bpf() syscall, reducing attack surface.
kernel.unprivileged_bpf_disabled = 1
# Restrict ptrace scope to prevent non-child processes from debugging other processes.
kernel.yama.ptrace_scope = 2
# Enable source route verification to prevent IP spoofing.
net.ipv4.conf.all.rp_filter = 1
EOF
  )
  echo "$sysctl_content" | sudo tee "$sysctl_file" >/dev/null
  sudo sysctl -p "$sysctl_file"
  print_success "Runtime kernel parameters have been applied."

  # --- 6. Harden /proc Filesystem ---
  print_info "Hardening /proc filesystem with hidepid..."
  # 'hidepid=2' restricts non-root users from seeing processes other than their own.
  # This prevents users from snooping on each other's activities.
  if ! grep "^\s*proc\s*/proc" /etc/fstab | grep -q "hidepid=2"; then
    sudo sed -i 's|^\s*proc\s*/proc.*|proc /proc proc nosuid,nodev,noexec,hidepid=2 0 0|' /etc/fstab
    sudo mount -o remount /proc
    print_success "/proc has been remounted with hidepid=2."
  else
    print_success "/proc entry in fstab is already hardened."
  fi
}

# Sets up the user's shell, dotfiles, and application configs.
task_configure_user() {
  print_step "Configuring User Environment for $TARGET_USER"

  if command_exists setup-github-keys; then
    print_info "Executing 'setup-github-keys'..."
    setup-github-keys
  fi

  print_info "Setting default shell for '$TARGET_USER' to fish..."
  if run_as_user "chsh -s $(which fish)"; then
    print_success "Default shell set to fish."
  else
    print_error "Failed to set fish as the default shell."
  fi

  print_info "Configuring NPM global directory..."
  run_as_user "mkdir -p '$USER_HOME/.npm-global' && npm config set prefix '$USER_HOME/.npm-global'"

  print_step "Setting up Hyprland Desktop Services"
  run_as_user "systemctl --user daemon-reload"
  local user_services=("pipewire.service" "pipewire-pulse.service" "wireplumber.service" "hypridle.service" "hyprpaper.service")
  for service in "${user_services[@]}"; do
    if run_as_user "systemctl --user enable --now '$service'"; then
      print_success "Enabled user service '$service'."
    else
      print_warning "Could not enable user service '$service'."
    fi
  done
}

# Removes orphaned packages and cleans the Nix store.
task_cleanup() {
  print_step "Cleaning Up System"

  print_info "Checking for orphaned packages..."
  if pacman -Qtdq >/dev/null; then
    print_warning "The following orphaned packages will be removed:"
    pacman -Qtd | awk '{print "  - " $1 " " $2}'
    yay -Rns "$(pacman -Qtdq)" < /dev/tty
  else
    print_success "No orphaned packages to remove."
  fi

  if command_exists nix; then
    print_info "Cleaning up Nix store by removing old generations..."
    run_as_user "nix-collect-garbage -d"
    print_success "Nix store cleanup complete."
  fi

  print_success "System cleanup finished."
}

# --- Main Execution Logic ---
main() {
  # 'exec &>' redirects both stdout and stderr of the script.
  # '>(tee -a "$LOG_FILE")' is a process substitution. It sends the redirected
  # output to the 'tee' command, which simultaneously appends it to the log file
  # ('-a') and prints it to the original standard output (the console).
  exec &> >(tee -a "$LOG_FILE")
  print_info "$I_LOG Logging output to: $LOG_FILE"

  local RUN_ALL=true
  if (($# > 0)); then
    while (("$#")); do
      case "$1" in
      # For each flag, first check if the *next* argument is '--docs'.
      # The construct '${2:-}' safely handles cases where a flag is given at the
      # end of the command, preventing an "unbound variable" error when 'set -u' is active.
      # If '--docs' is found, display the relevant documentation and exit.
      # Otherwise, set RUN_ALL to false, run the task, and shift to the next argument.
      --initial-setup)
        if [[ "${2:-}" == "--docs" ]]; then docs_initial_setup >/dev/tty; exit 0; fi
        RUN_ALL=false; task_initial_setup; shift ;;
      --setup-extra-repos)
        if [[ "${2:-}" == "--docs" ]]; then docs_setup_extra_repos >/dev/tty; exit 0; fi
        RUN_ALL=false; task_setup_extra_repos; shift ;;
      --kernel-and-drivers)
        if [[ "${2:-}" == "--docs" ]]; then docs_kernel_and_drivers >/dev/tty; exit 0; fi
        RUN_ALL=false; task_kernel_and_drivers; shift ;;
      --setup-asus)
        if [[ "${2:-}" == "--docs" ]]; then docs_setup_asus >/dev/tty; exit 0; fi
        RUN_ALL=false; task_setup_asus; shift ;;
      --setup-greetd)
        if [[ "${2:-}" == "--docs" ]]; then docs_setup_greetd >/dev/tty; exit 0; fi
        RUN_ALL=false; task_setup_greetd; shift ;;
      --setup-nix)
        if [[ "${2:-}" == "--docs" ]]; then docs_setup_nix >/dev/tty; exit 0; fi
        RUN_ALL=false; task_setup_nix; shift ;;
      --install-packages)
        if [[ "${2:-}" == "--docs" ]]; then docs_install_packages >/dev/tty; exit 0; fi
        RUN_ALL=false; task_install_packages; shift ;;
      --manual-installs)
        if [[ "${2:-}" == "--docs" ]]; then docs_manual_installations >/dev/tty; exit 0; fi
        RUN_ALL=false; task_manual_installations; shift ;;
      --harden-system)
        if [[ "${2:-}" == "--docs" ]]; then docs_harden_system >/dev/tty; exit 0; fi
        RUN_ALL=false; task_harden_system; shift ;;
      --configure-user)
        if [[ "${2:-}" == "--docs" ]]; then docs_configure_user >/dev/tty; exit 0; fi
        RUN_ALL=false; task_configure_user; shift ;;
      --cleanup)
        if [[ "${2:-}" == "--docs" ]]; then docs_cleanup >/dev/tty; exit 0; fi
        RUN_ALL=false; task_cleanup; shift ;;
      --debug)
        DEBUG_MODE=true; shift ;;
      --help)
        print_usage >/dev/tty; exit 0 ;;
      --docs)
        print_documentation >/dev/tty; exit 0 ;;
      *)
        print_error "Unknown flag: $1"; print_usage >/dev/tty; exit 1 ;;
      esac
    done
  fi

  if [ "$DEBUG_MODE" = true ]; then
    print_debug "Debug mode enabled. Activating verbose command tracing (set -x)."
    set -x
  fi

  # Always run pre-flight checks to ensure the system is ready.
  pre_flight_checks

  # If no specific task flags were provided, run the full interactive installation.
  if [ "$RUN_ALL" = true ]; then
    print_step "Full Installation Plan Summary"
    echo "This script will perform a full setup of a Hyprland desktop on Arch Linux."
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
      print_info "Aborting."; exit 0
    fi

    # Execute all setup tasks in the logical order defined at the top of the script.
    task_initial_setup
    task_setup_extra_repos

    # Conditionally run hardware-specific tasks after prompting the user.
    if grep -q "\[cachyos\]" /etc/pacman.conf; then
      read -p "$(echo -e "${C_CYAN}${I_PROMPT} CachyOS repo detected. Install kernel/drivers? [Y/n]: ${C_END}")" -r cachyos_choice
      if [[ ! "$cachyos_choice" =~ ^[Nn]$ ]]; then task_kernel_and_drivers; fi
    fi
    if sudo dmidecode -s system-manufacturer | grep -qi "ASUS"; then
      read -p "$(echo -e "${C_CYAN}${I_PROMPT} ASUS hardware detected. Install specific tools? [Y/n]: ${C_END}")" -r asus_choice
      if [[ ! "$asus_choice" =~ ^[Nn]$ ]]; then task_setup_asus; fi
    fi

    task_setup_greetd
    task_setup_nix
    task_install_packages
    task_manual_installations
    task_harden_system
    task_configure_user
    task_cleanup
  fi

  set +x
  print_step "$I_FINISH Run Complete!"
  print_success "All requested tasks finished successfully."
  print_warning "A final reboot is highly recommended to apply all changes."
}

# --- Script Entry Point ---
# First, ensure we are running with bash. If not, re-execute the script with bash.
# This prevents issues with scripts being run with 'sh' or other shells that may
# not support bash-specific features like 'pipefail' or certain expansions.
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Re-executing with bash..." >&2
  exec bash "$0" "$@"
  exit 1 # Should not be reached, but good practice
fi

# Call the main function with all script arguments.
main "$@"