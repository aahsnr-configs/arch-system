#!/usr/bin/env bash

# This script automates the setup of a complete Nobara Hyprland Environment.
# It is a robust, idempotent, and modular script that reads its package and
# group lists from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
# Use the --debug flag to enable verbose command tracing.
# Use the --help flag to see all available commands.
#
# --- Script Task Order ---
# The script performs the following tasks in a specific order:
#   1.  Pre-flight Checks: Verifies user privileges, sudo access, and internet connectivity.
#   2.  Initial Files Setup: Deploys custom DNF and environment variable configurations.
#   3.  Setup Repos: Enables COPR repositories for extra packages.
#   4.  Install Groups: Installs package groups listed in 'groups.txt'.
#   5.  Install Packages: Installs all individual packages listed in 'packages.txt'.
#   6.  Install Flatpaks (Optional): Installs Flatpak applications from 'flatpaks.txt'.
#   7.  Setup for ASUS Laptops (Optional): Installs asusctl and related tools.
#   8.  Manual Installs: Installs third-party software like themes and VPNs.
#   9.  Setup Nix & Home-Manager (Optional): Installs and configures Nix with flakes and home-manager.
#   10. Harden System: Implements basic security enhancements for SSH, system limits, and kernel parameters.
#   11. Configure User: Sets up the user's environment, including dotfiles, SSH keys, and the default shell.
#   12. Enable System Services: Enables optional, system-wide services for monitoring and performance.
#   13. Setup Hyprland: Enables the necessary systemd user services for the desktop environment to function.
#   14. Cleanup: Removes orphaned packages to free up disk space.

# --- Script Setup and Error Handling ---
set -euo pipefail

# --- Cleanup Trap ---
# Ensures temporary files are removed when the script exits for any reason.
TEMP_FILES=()
cleanup() {
  # 'set +x' is used to turn off debug tracing during the cleanup phase
  # to avoid unnecessary noise when the script exits.
  set +x
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

# --- Global Configuration ---
# Variables are assigned first, then made readonly. This is a best practice
# to ensure that 'set -e' correctly catches any errors from the commands
# used in the assignments.

TARGET_USER="$(logname)"
readonly TARGET_USER

USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
readonly USER_HOME

# Note: The following variables are essential and used in task functions.
# A linter might incorrectly flag them as unused.
readonly DOTFILES_REPO_URL="https://github.com/aahsnr/.hyprdots.git"
readonly DOTFILES_DIR="$USER_HOME/.hyprdots"
DEBUG_MODE=false

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

# --- Usage Information ---
print_usage() {
  echo -e "${C_BOLD}Usage: $0 [OPTIONS...]${C_END}"
  echo "Automates the setup of a complete Nobara Hyprland Environment."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks sequentially.${C_END}"
  echo ""
  echo -e "${C_HEADER}Options:${C_END}"
  echo -e "  ${C_GREEN}--initial-setup${C_END}         Deploy custom DNF and environment variable configurations."
  echo -e "  ${C_GREEN}--setup-repos${C_END}           Enable COPR and other repositories."
  echo -e "  ${C_GREEN}--install-groups${C_END}        Install package groups from 'groups.txt'."
  echo -e "  ${C_GREEN}--install-packages${C_END}      Install individual packages from 'packages.txt'."
  echo -e "  ${C_GREEN}--install-flatpaks${C_END}      Install Flatpak applications from 'flatpaks.txt'."
  echo -e "  ${C_GREEN}--setup-asus${C_END}            Run specific setup for ASUS laptops."
  echo -e "  ${C_GREEN}--manual-installs${C_END}       Perform manual installation of third-party software."
  echo -e "  ${C_GREEN}--setup-nix${C_END}             Install and configure Nix with Home-Manager."
  echo -e "  ${C_GREEN}--harden-system${C_END}         Implement basic security enhancements."
  echo -e "  ${C_GREEN}--configure-user${C_END}        Set up the user's environment (dotfiles, shell, SSH keys)."
  echo -e "  ${C_GREEN}--enable-system-services${C_END}  Enable optional system-wide services (ensures packages are installed)."
  echo -e "  ${C_GREEN}--setup-hyprland${C_END}        Enable systemd user services for Hyprland."
  echo -e "  ${C_GREEN}--cleanup${C_END}               Remove orphaned packages from the system."
  echo -e "  ${C_YELLOW}--debug${C_END}                 Enable verbose command tracing for debugging."
  echo -e "  ${C_BLUE}--help${C_END}                  Display this help message and exit."
}

# --- Utility Functions ---
command_exists() { command -v "$1" &>/dev/null; }
is_pkg_installed() { rpm -q "$1" &>/dev/null; }
run_as_user() { sudo -u "$TARGET_USER" bash -c "export HOME='$USER_HOME'; export USER='$TARGET_USER'; $*"; }

# Writes content to a file only if it's different from the existing content.
write_file_idempotent() {
  local path="$1" content="$2" owner="${3:-root:root}"
  print_info "Configuring file: $path"
  print_debug "Content for '$path':\n---\n$content\n---"

  local tmp_file
  tmp_file=$(mktemp)
  TEMP_FILES+=("$tmp_file")
  echo -e "$content" >"$tmp_file"

  if [ -f "$path" ] && diff -q "$path" "$tmp_file" &>/dev/null; then
    print_success "File '$path' is already up to date."
    return 0
  fi

  sudo mkdir -p "$(dirname "$path")"
  sudo mv "$tmp_file" "$path"
  sudo chown "$owner" "$path"
  print_success "Wrote configuration to '$path'."
}

# --- Task Functions ---

# Verifies that the script is run in a valid environment.
pre_flight_checks() {
  print_step "Running Pre-flight Checks"
  print_debug "Effective UID: $EUID. Target user: $TARGET_USER."
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
  print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

# Copies initial system configuration files from local '.txt' files.
task_initial_files_setup() {
  print_step "Applying Initial System Configurations"

  # DNF Configuration
  if [[ ! -f "dnf.conf.txt" ]]; then
    print_error "Configuration file 'dnf.conf.txt' not found."
    exit 1
  fi
  local dnf_conf_content
  dnf_conf_content=$(<dnf.conf.txt)
  write_file_idempotent "/etc/dnf/dnf.conf" "$dnf_conf_content"

  # Custom Environment Script
  if [[ ! -f "99-custom-env.sh.txt" ]]; then
    print_error "Configuration file '99-custom-env.sh.txt' not found."
    exit 1
  fi
  local env_sh_content
  env_sh_content=$(<99-custom-env.sh.txt)
  write_file_idempotent "/etc/profile.d/99-custom-env.sh" "$env_sh_content"

  print_info "Setting execute permissions on custom environment script."
  sudo chmod +x "/etc/profile.d/99-custom-env.sh"
}

# Configures DNF and enables third-party repositories.
task_setup_repos() {
  print_step "Setting up System Repositories"

  # COPR Repositories
  local copr_repos=("solopasha/hyprland" "errornointernet/quickshell" "deltacopy/darkly" "sneexy/zen-browser")
  for repo in "${copr_repos[@]}"; do
    local repo_filename="_copr_${repo//\//-}.repo"
    if [ -f "/etc/yum.repos.d/$repo_filename" ]; then
      print_success "COPR repository '$repo' is already enabled."
    else
      print_info "Enabling COPR repository: $repo"
      sudo dnf copr enable -y "$repo"
    fi
  done

  # RPM Fusion Repositories (Nobara usually includes these by default)
  for repo_type in free nonfree; do
    if is_pkg_installed "rpmfusion-${repo_type}-release"; then
      print_success "RPM Fusion $repo_type is already installed."
    else
      print_warning "RPM Fusion $repo_type is not installed. Attempting to install..."
      sudo dnf install -y "https://mirrors.rpmfusion.org/${repo_type}/fedora/rpmfusion-${repo_type}-release-$(rpm -E %fedora).noarch.rpm"
    fi
  done

  # OpenSUSE Build Service Repository
  local fedora_version
  fedora_version=$(rpm -E %fedora)
  local obs_repo_url="https://download.opensuse.org/repositories/home:luisbocanegra/Fedora_${fedora_version}/home:luisbocanegra.repo"
  local obs_repo_name="home:luisbocanegra"
  local obs_repo_filename="${obs_repo_name}.repo"
  if [ -f "/etc/yum.repos.d/$obs_repo_filename" ]; then
    print_success "Repository '$obs_repo_name' is already enabled."
  else
    print_info "Enabling repository '$obs_repo_name' from OpenSUSE Build Service."
    sudo dnf config-manager --addrepo "$obs_repo_url"
  fi

  # Update system packages after enabling new repositories.
  print_info "Updating system packages after repository setup..."
  sudo dnf update -y
}

# Reads the group list from 'groups.txt' and installs them using 'dnf install @group'.
task_install_groups() {
  print_step "Installing System Package Groups from File"
  local group_file="groups.txt"

  if [[ ! -f "$group_file" ]]; then
    print_error "Group file '$group_file' not found. It must be in the same directory as this script."
    exit 1
  fi

  print_info "Reading group list from '$group_file'..."
  local group_ids
  mapfile -t group_ids < <(grep -vE '^\s*#|^\s*$' "$group_file")

  if ((${#group_ids[@]} == 0)); then
    print_warning "No groups found in '$group_file'. Skipping group installation."
    return
  fi

  # Prepare the groups for 'dnf install' by prepending '@' to each group ID.
  local groups_to_install=()
  for id in "${group_ids[@]}"; do
    groups_to_install+=("@${id}")
  done

  print_debug "Final list of groups to install: ${groups_to_install[*]}"
  print_info "Installing ${#groups_to_install[@]} DNF groups..."
  sudo dnf install -y "${groups_to_install[@]}"
}

# Reads the package list from 'packages.txt' and installs them.
task_install_packages() {
  print_step "Installing Individual System Packages from File"
  local package_file="packages.txt"

  if [[ ! -f "$package_file" ]]; then
    print_error "Package file '$package_file' not found."
    exit 1
  fi

  print_info "Reading package list from '$package_file'..."
  local packages_to_install
  mapfile -t packages_to_install < <(grep -vE '^\s*#|^\s*$' "$package_file")

  if ((${#packages_to_install[@]} == 0)); then
    print_warning "No packages found in '$package_file'. Skipping installation."
    return
  fi

  print_debug "Final list of packages to install: ${packages_to_install[*]}"
  print_info "Installing ${#packages_to_install[@]} DNF packages. This may take a while..."
  # FIX: Added --allowerasing to handle potential package conflicts automatically.
  sudo dnf install -y --allowerasing "${packages_to_install[@]}"
}

# Installs Flatpaks from the 'flatpaks.txt' file.
task_install_flatpaks() {
  print_step "Installing Flatpaks from File"

  # Ensure flatpak is installed on the system
  if ! command_exists flatpak; then
    print_info "Flatpak is not installed. Installing it now via DNF..."
    sudo dnf install -y flatpak
  else
    print_success "Flatpak is already installed."
  fi

  # Remove Fedora system remote if it exists
  if flatpak remotes --system | grep -q "^fedora\s"; then
    print_info "Removing Fedora system flatpak remote."
    sudo flatpak remote-delete fedora
  else
    print_success "Fedora system flatpak remote not found."
  fi

  # Remove Flathub system remote if it exists
  if flatpak remotes --system | grep -q "^flathub\s"; then
    print_info "Removing Flathub system flatpak remote."
    sudo flatpak remote-delete flathub
  else
    print_success "Flathub system flatpak remote not found."
  fi

  # Add Flathub user remote if it does not exist
  print_info "Ensuring Flathub user repository is configured for user '$TARGET_USER'..."
  run_as_user "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
  print_success "Flathub user remote is configured."

  local flatpak_file="flatpaks.txt"
  if [[ ! -f "$flatpak_file" ]]; then
    print_error "Flatpak list file '$flatpak_file' not found. Aborting Flatpak setup."
    return 1
  fi

  print_info "Reading Flatpak application list from '$flatpak_file'..."
  local flatpaks_to_install
  mapfile -t flatpaks_to_install < <(grep -vE '^\s*#|^\s*$' "$flatpak_file")

  if ((${#flatpaks_to_install[@]} == 0)); then
    print_warning "No applications found in '$flatpak_file'. Skipping installation."
    return
  fi

  print_info "Installing ${#flatpaks_to_install[@]} Flatpaks as user '$TARGET_USER'. This may take a while..."
  # Install all flatpaks in a single command for efficiency.
  if ! run_as_user "flatpak install -y flathub ${flatpaks_to_install[*]}"; then
    print_warning "Failed to install one or more Flatpaks. They might already be installed or there was a network issue."
  fi
  print_success "Flatpak installation process complete."
}

# Installs special drivers and tools for ASUS laptops.
task_setup_asus() {
  print_step "Setting up for ASUS Laptops"
  print_warning "This will install ASUS-specific software and may replace existing packages."

  # Enable COPR Repository for asus-linux
  local asus_repo="lukenukem/asus-linux"
  local asus_repo_filename="_copr_${asus_repo//\//-}.repo"
  if [ -f "/etc/yum.repos.d/$asus_repo_filename" ]; then
    print_success "COPR repository '$asus_repo' is already enabled."
  else
    print_info "Enabling COPR repository for ASUS Linux: $asus_repo"
    sudo dnf copr enable -y "$asus_repo"
  fi

  # Refresh repositories to ensure the new COPR repo is available.
  print_info "Refreshing DNF repositories..."
  sudo dnf update --refresh

  # Install ASUS-specific packages.
  local asus_packages=("asusctl" "supergfxctl" "power-profiles-daemon" "asusctl-rog-gui")
  print_info "Installing ASUS-specific packages: ${asus_packages[*]}"
  # The --allowerasing flag is used as specified in the sample to handle potential conflicts.
  sudo dnf install -y --allowerasing "${asus_packages[@]}"

  # Reload the systemd daemon to ensure it finds the new service files.
  print_info "Reloading systemd manager configuration to detect new services..."
  sudo systemctl daemon-reload

  # Enable the necessary systemd services directly.
  print_info "Enabling system services for ASUS: supergfxd and power-profiles-daemon..."
  sudo systemctl enable --now supergfxd.service power-profiles-daemon.service
  print_success "Attempted to enable ASUS-related services."

  print_success "ASUS-specific setup complete."
}

# Installs third-party software that is not available in standard repositories.
task_manual_installations() {
  print_step "Performing Manual Installations (as User)"

  # --- Install Breeze Plus Icons ---
  local icon_dir="$USER_HOME/.local/share/icons/breeze-plus"
  if [ -d "$icon_dir" ]; then
    print_success "Breeze Plus icons are already installed."
  else
    print_info "Installing Breeze Plus icon theme."
    if ! command_exists git; then
      print_warning "'git' is required. Installing it now."
      sudo dnf install -y git
    fi
    local tmp_repo_dir
    tmp_repo_dir=$(mktemp -d)
    TEMP_FILES+=("$tmp_repo_dir")

    print_info "Cloning icon repository as user '$TARGET_USER'..."
    run_as_user "git clone https://github.com/mjkim0727/breeze-plus.git '$tmp_repo_dir'"

    print_info "Copying icon files..."
    run_as_user "mkdir -p '$USER_HOME/.local/share/icons' && cp -r '$tmp_repo_dir'/src/breeze-plus* '$USER_HOME/.local/share/icons/'"

    print_success "Breeze Plus icons installed successfully."
  fi

  # --- Install Private Internet Access (PIA) VPN ---
  if command_exists pia-client; then
    print_success "Private Internet Access is already installed."
  else
    print_info "Installing Private Internet Access (PIA) VPN."
    if ! command_exists wget; then
      print_warning "'wget' is required. Installing it now."
      sudo dnf install -y wget
    fi

    local pia_url="https://installers.privateinternetaccess.com/download/pia-linux-3.6.2-08398.run"
    local pia_installer
    # Create the temp file in a location the target user can access
    pia_installer=$(run_as_user "mktemp --suffix=.run")
    TEMP_FILES+=("$pia_installer")

    print_info "Downloading PIA installer..."
    # Download the file as the user to avoid permission issues
    run_as_user "wget -O '$pia_installer' '$pia_url'"
    run_as_user "chmod +x '$pia_installer'"

    print_warning "The PIA installer will now launch as user '$TARGET_USER'."
    print_warning "The installer itself will likely prompt for an administrative password to set up system-level services."

    # Run the installer as the target user. The installer will handle its own privilege escalation.
    run_as_user "bash '$pia_installer'"

    print_success "PIA VPN installation process finished."
  fi
}

# Installs and configures Nix, Flakes, and Home-Manager.
task_setup_nix() {
  print_step "Setting up Nix, Home-Manager, and Flakes"

  local nix_daemon_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

  # Step 1: Install Nix using the Determinate Systems installer
  if command_exists nix; then
    print_success "Nix is already installed."
  else
    print_info "Nix not found. Installing with the Determinate Systems installer..."
    if ! command_exists curl; then
      print_warning "'curl' is required. Installing it now."
      sudo dnf install -y curl
    fi

    # The installer uses 'sudo' internally when needed.
    if curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate; then
      print_success "Nix installed successfully."
    else
      print_error "Nix installation failed. Aborting Nix setup."
      return 1
    fi
  fi

  # Step 2: Make sure nix is immediately available to the shell
  if [ -f "$nix_daemon_profile" ]; then
    print_info "Sourcing Nix profile to make commands available for this session..."
    # Use '.' for POSIX compatibility.
    . "$nix_daemon_profile"
  else
    print_error "Nix daemon profile script not found at '$nix_daemon_profile'. Cannot proceed."
    return 1
  fi
  # Verify nix command is now available after sourcing
  if ! command_exists nix; then
    print_error "Nix command is not available even after sourcing the profile. Aborting Nix setup."
    return 1
  fi

  # Step 3: Create nix.conf with experimental features
  local nix_config_dir="$USER_HOME/.config/nix"
  local nix_config_file="$nix_config_dir/nix.conf"
  local nix_config_content="experimental-features = nix-command flakes"
  print_info "Ensuring Nix is configured to use flakes..."
  run_as_user "mkdir -p '$nix_config_dir'"
  # Idempotently write the configuration
  if run_as_user "[ -f '$nix_config_file' ]" && run_as_user "grep -qFx '$nix_config_content' '$nix_config_file'"; then
    print_success "Nix flake features are already configured."
  else
    run_as_user "echo '$nix_config_content' > '$nix_config_file'"
    print_success "Enabled Nix experimental features (flakes)."
  fi

  # Sourcing the profile needs to be done inside 'run_as_user' for subsequent commands
  local user_command_prefix=". $nix_daemon_profile;"

  # Step 4: Setup home-manager (and remove its initial config)
  print_info "Initializing Home-Manager to set up its channels..."
  run_as_user "$user_command_prefix nix run home-manager/master -- init --switch"
  print_info "Removing initial Home-Manager configuration..."
  run_as_user "rm -rf '$USER_HOME/.config/home-manager'"
  print_success "Home-Manager bootstrap complete."

  # Step 5: Clone the custom home-manager configuration
  print_info "Cloning custom Home-Manager configuration repository..."
  if ! command_exists git; then
    print_warning "'git' is required. Installing it now."
    sudo dnf install -y git
  fi
  run_as_user "git clone https://github.com/aahsnr-configs/home-manager.git ~/.config/home-manager"
  print_success "Cloned custom Home-Manager repository."

  # Step 6: Run home-manager switch with backup logic
  print_info "Attempting to switch to the new Home-Manager configuration..."
  if run_as_user "$user_command_prefix home-manager switch"; then
    print_success "Home-Manager switch completed successfully on the first try."
  else
    print_warning "Initial 'home-manager switch' failed, which can be expected if files conflict."
    print_info "Retrying the switch with the backup flag '-b backup'..."
    if ! run_as_user "$user_command_prefix home-manager switch -b backup"; then
      print_error "The 'home-manager switch -b backup' command failed. Please check the logs."
      return 1
    fi
    print_info "Re-running the switch command after creating backups..."
    if ! run_as_user "$user_command_prefix home-manager switch"; then
      print_error "'home-manager switch' failed on the second attempt. Please check the logs."
      return 1
    fi
    print_success "Home-Manager switch completed successfully after handling backups."
  fi
}

# Applies system-wide security hardening configurations.
task_harden_system() {
  print_step "Applying System Security Hardening"
  write_file_idempotent "/etc/security/limits.d/99-custom-limits.conf" '# Custom security limits\n* soft nofile 65536\n* hard nofile 1048576'

  # Define the new, detailed banner content.
  local banner_content="-- WARNING -- This system is for the use of authorized users only. Individuals
using this computer system without authority or in excess of their authority
are subject to having all their activities on this system monitored and
recorded by system personnel. Anyone using this system expressly consents to
such monitoring and is advised that if such monitoring reveals possible
evidence of criminal activity system personal may provide the evidence of such
monitoring to law enforcement officials."

  # Write the new banner to /etc/issue and /etc/issue.net, overwriting existing content.
  write_file_idempotent "/etc/issue" "$banner_content"
  write_file_idempotent "/etc/issue.net" "$banner_content"

  local sshd_content="Include /etc/ssh/sshd_config.d/*.conf\nPermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes\nChallengeResponseAuthentication no\nUsePAM yes\nX11Forwarding no\nPrintMotd no\nAcceptEnv LANG LC_*\nSubsystem sftp /usr/libexec/openssh/sftp-server\nMaxAuthTries 3"
  write_file_idempotent "/etc/ssh/sshd_config.d/99-hardened.conf" "$sshd_content"

  # Define the sysctl settings to be appended.
  local sysctl_content
  sysctl_content=$(
    cat <<'EOF'

# --- Custom Hardening Settings Appended by Script ---
dev.tty.ldisc_autoload = 0
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0
kernel.kptr_restrict = 2
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.log_martians = 1
EOF
  )

  local sysctl_file="/etc/sysctl.d/99-custom.conf"

  # Append settings idempotently. Check for a unique line to see if we've run before.
  if [ -f "$sysctl_file" ] && grep -q -F "kernel.unprivileged_bpf_disabled = 1" "$sysctl_file"; then
    print_success "Custom sysctl settings already exist in '$sysctl_file'."
  else
    print_info "Appending custom sysctl settings to '$sysctl_file'..."
    # Create the directory if it doesn't exist, then append.
    sudo mkdir -p "$(dirname "$sysctl_file")"
    echo "$sysctl_content" | sudo tee -a "$sysctl_file" >/dev/null
    print_success "Appended settings."
  fi

  # Apply the settings from the file.
  print_info "Applying kernel settings from '$sysctl_file'..."
  if sudo sysctl -p "$sysctl_file"; then
    print_success "Kernel settings applied."
  else
    # Some settings might fail on certain systems; this is usually not critical.
    print_warning "There was a non-critical issue applying some kernel settings."
  fi
}

# Sets up the user's shell, dotfiles, and application configs.
task_configure_user() {
  print_step "Configuring User Environment for $TARGET_USER"

  # Run the custom command to set up GitHub SSH keys if it exists.
  print_info "Checking for 'setup-github-keys' command..."
  if command_exists setup-github-keys; then
    print_info "Executing 'setup-github-keys' for user '$TARGET_USER'..."
    run_as_user "setup-github-keys"
    print_success "Finished GitHub key setup."
  else
    print_warning "'setup-github-keys' command not found. Skipping automatic Git/SSH setup."
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    print_success "Dotfiles directory already exists."
  else
    print_info "Cloning Hyprland dotfiles..."
    run_as_user "git clone $DOTFILES_REPO_URL $DOTFILES_DIR"
  fi

  # Define the path for the Nix-managed Zsh.
  local nix_zsh_path="$USER_HOME/.nix-profile/bin/zsh"
  local target_shell="/usr/bin/zsh" # Default to system Zsh.

  # Prefer the Nix-managed Zsh if it has been installed.
  if [ -f "$nix_zsh_path" ]; then
    print_info "Nix-managed Zsh found. Configuring it as the default shell."
    target_shell="$nix_zsh_path"

    # Idempotently add the Nix Zsh path to /etc/shells to make it a valid login shell.
    if grep -qFx "$target_shell" /etc/shells; then
      print_success "Nix Zsh path already exists in /etc/shells."
    else
      print_info "Adding Nix Zsh to /etc/shells..."
      echo "$target_shell" | sudo tee -a /etc/shells >/dev/null
      print_success "Nix Zsh added as a valid shell."
    fi
  else
    print_info "Nix-managed Zsh not found. Defaulting to system Zsh."
  fi

  print_info "Setting default shell for '$TARGET_USER' to '$target_shell'."
  sudo chsh -s "$target_shell" "$TARGET_USER"
  print_success "Default shell has been set."

  print_info "Configuring NPM global directory."
  run_as_user "mkdir -p '$USER_HOME/.npm-global'"
  run_as_user "npm config set prefix '$USER_HOME/.npm-global'"
}

# Enables optional system-wide services for monitoring and performance.
task_enable_system_services() {
  print_step "Enabling System-wide Services"
  local system_services=("psacct.service" "sysstat.service" "rngd.service" "haveged.service")

  for service in "${system_services[@]}"; do
    print_info "Attempting to enable system service: $service"
    # Attempt to enable the service directly. If it fails, print a warning but continue.
    if sudo systemctl enable --now "$service"; then
      print_success "Successfully enabled '$service'."
    else
      print_warning "Could not enable '$service'. The package providing it may not be installed."
    fi
  done
  print_success "System service setup complete."
}

# Enables systemd services required for the Hyprland desktop.
task_setup_hyprland() {
  print_step "Setting up Hyprland Desktop Services"

  if [ ! -d "$DOTFILES_DIR" ]; then
    print_error "Dotfiles not found. Run --configure-user first."
    return 1
  fi

  run_as_user "mkdir -p '$USER_HOME/.config/systemd/user'"
  run_as_user "systemctl --user daemon-reload"

  print_info "Enabling core desktop services for the user."
  local user_services=("pipewire.service" "pipewire-pulse.service" "wireplumber.service" "hypridle.service" "hyprpaper.service")

  local available_services
  available_services=$(run_as_user "systemctl --user list-unit-files --no-legend")

  for service in "${user_services[@]}"; do
    if echo "$available_services" | grep -q "^${service}"; then
      print_info "Enabling user service: $service"
      run_as_user "systemctl --user enable --now '$service'"
    else
      print_warning "Service unit '$service' not found. Skipping."
    fi
  done
  print_success "Desktop service setup complete."
}

# Removes orphaned packages from the system.
task_cleanup() {
  print_step "Cleaning Up System"
  print_info "Removing any orphaned packages..."
  sudo dnf autoremove -y
  print_success "System cleanup complete."
}

# --- Main Execution Logic ---
# Boolean flags to control which tasks are run.
RUN_ALL=true
RUN_INITIAL_SETUP=false
RUN_SETUP_REPOS=false
RUN_INSTALL_GROUPS=false
RUN_INSTALL_PACKAGES=false
RUN_INSTALL_FLATPAKS=false
RUN_SETUP_ASUS=false
RUN_MANUAL_INSTALLS=false
RUN_SETUP_NIX=false
RUN_HARDEN_SYSTEM=false
RUN_CONFIGURE_USER=false
RUN_ENABLE_SYSTEM_SERVICES=false
RUN_SETUP_HYPRLAND=false
RUN_CLEANUP=false

# Parses command-line arguments to determine which tasks to run.
parse_args_and_plan_tasks() {
  # If any flag other than --debug is passed, don't run all tasks.
  local flags_provided=false
  for arg in "$@"; do
    if [[ "$arg" != "--debug" ]]; then
      flags_provided=true
      break
    fi
  done

  if [ "$flags_provided" = true ]; then
    RUN_ALL=false
  fi

  # Use a case statement for robust argument parsing.
  for arg in "$@"; do
    case "$arg" in
    --initial-setup) RUN_INITIAL_SETUP=true ;;
    --setup-repos) RUN_SETUP_REPOS=true ;;
    --install-groups) RUN_INSTALL_GROUPS=true ;;
    --install-packages) RUN_INSTALL_PACKAGES=true ;;
    --install-flatpaks) RUN_INSTALL_FLATPAKS=true ;;
    --setup-asus) RUN_SETUP_ASUS=true ;;
    --manual-installs) RUN_MANUAL_INSTALLS=true ;;
    --setup-nix) RUN_SETUP_NIX=true ;;
    --harden-system) RUN_HARDEN_SYSTEM=true ;;
    --configure-user) RUN_CONFIGURE_USER=true ;;
    --enable-system-services) RUN_ENABLE_SYSTEM_SERVICES=true ;;
    --setup-hyprland) RUN_SETUP_HYPRLAND=true ;;
    --cleanup) RUN_CLEANUP=true ;;
    --debug) DEBUG_MODE=true ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      print_error "Unknown flag: $arg"
      print_usage
      exit 1
      ;;
    esac
  done

  # If --enable-system-services is specified, ensure package installation is also queued.
  if [ "$RUN_ENABLE_SYSTEM_SERVICES" = true ] && [ "$RUN_ALL" = false ]; then
    print_info "The --enable-system-services flag requires packages to be installed."
    print_info "Queuing package installation tasks..."
    RUN_INSTALL_GROUPS=true
    RUN_INSTALL_PACKAGES=true
  fi
}

# The main orchestrator of the script.
main() {
  parse_args_and_plan_tasks "$@"

  if [ "$DEBUG_MODE" = true ]; then
    print_debug "Debug mode enabled. Activating verbose command tracing (set -x)."
    set -x # Enable xtrace debugging.
  fi

  pre_flight_checks

  local ASUS_SETUP_REQUESTED=false
  local FLATPAK_SETUP_REQUESTED=false
  if [ "$RUN_ALL" = true ]; then
    print_step "Full Installation Plan Summary"
    echo -e """
This script will perform a full, opinionated setup of a Nobara Hyprland desktop.
It will configure the system, install packages, harden security,
and configure the user environment.
${C_YELLOW}You will be prompted for your password for 'sudo' commands.${C_END}
"""
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
      print_info "Aborting."
      exit 0
    fi

    read -p "$(echo -e "${C_CYAN}${I_PROMPT} Is this an ASUS laptop? (This will install specific drivers and tools) [y/N]: ${C_END}")" -r asus_choice
    if [[ "$asus_choice" =~ ^[Yy]$ ]]; then
      ASUS_SETUP_REQUESTED=true
    fi

    read -p "$(echo -e "${C_CYAN}${I_PROMPT} Do you want to install Flatpak applications from flatpaks.txt? [y/N]: ${C_END}")" -r flatpak_choice
    if [[ "$flatpak_choice" =~ ^[Yy]$ ]]; then
      FLATPAK_SETUP_REQUESTED=true
    fi
  fi

  # Execute tasks based on flags or full run mode.
  if [ "$RUN_ALL" = true ] || [ "$RUN_INITIAL_SETUP" = true ]; then task_initial_files_setup; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_SETUP_REPOS" = true ]; then task_setup_repos; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_INSTALL_GROUPS" = true ]; then task_install_groups; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_INSTALL_PACKAGES" = true ]; then task_install_packages; fi
  if [ "$FLATPAK_SETUP_REQUESTED" = true ] || [ "$RUN_INSTALL_FLATPAKS" = true ]; then task_install_flatpaks; fi
  if [ "$ASUS_SETUP_REQUESTED" = true ] || [ "$RUN_SETUP_ASUS" = true ]; then task_setup_asus; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_MANUAL_INSTALLS" = true ]; then task_manual_installations; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_SETUP_NIX" = true ]; then task_setup_nix; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_HARDEN_SYSTEM" = true ]; then task_harden_system; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_CONFIGURE_USER" = true ]; then task_configure_user; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_ENABLE_SYSTEM_SERVICES" = true ]; then task_enable_system_services; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_SETUP_HYPRLAND" = true ]; then task_setup_hyprland; fi
  if [ "$RUN_ALL" = true ] || [ "$RUN_CLEANUP" = true ]; then task_cleanup; fi

  set +x # Disable xtrace at the end of the script.
  print_step "$I_FINISH Run Complete!"
  print_success "All requested tasks finished successfully."
  print_warning "A final reboot is highly recommended to apply all changes."
}

# Pass all script arguments to the main function.
main "$@"
