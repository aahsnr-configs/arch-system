#!/usr/bin/env bash

# This script automates the setup of a complete Hyprland Environment on Fedora 42.
# It is a robust, idempotent, and modular script that reads package lists
# from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
#
# --- Features ---
#   - Automatic hardware detection for NVIDIA and ASUS setups.
#   - Full logging of all operations to a timestamped log file.
#   - A '--yes' flag for fully non-interactive (automated) execution.
#   - Upfront dependency checking and installation.
#   - Idempotent design: safe to re-run without causing issues.
#
# --- Script Task Order ---
#   1.  Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.
#   2.  Initial Files Setup: Deploys custom DNF and environment configurations.
#   3.  Setup Repos: Enables COPR and RPM Fusion repositories.
#   4.  Setup NVIDIA Drivers (Optional): Installs proprietary NVIDIA drivers if hardware is detected.
#   5.  Install Groups: Installs package groups from 'groups.txt'.
#   6.  Install Packages: Installs individual packages from 'packages.txt'.
#   7.  Install Flatpaks (Optional): Installs Flatpak applications from 'flatpaks.txt'.
#   8.  Setup for ASUS Laptops (Optional): Installs asusctl if hardware is detected.
#   9.  Manual Installs: Installs third-party software like themes and VPNs.
#   10. Setup Nix & Home-Manager (Optional): Installs and configures Nix with flakes.
#   11. Harden System: Implements basic security enhancements.
#   12. Configure User: Sets up the user's dotfiles, shell, and SSH keys.
#   13. Enable System Services: Enables optional system-wide services.
#   14. Setup Hyprland: Enables the necessary systemd user services.
#   15. Cleanup: Removes orphaned packages.

# --- Script Setup and Error Handling ---
set -euo pipefail

# --- Cleanup Trap ---
# Ensures temporary files are removed when the script exits for any reason.
TEMP_FILES=()
cleanup() {
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
readonly I_LOG="📄"

# --- Global Configuration ---
readonly TARGET_USER="$(logname)"
readonly USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
readonly DOTFILES_REPO_URL="https://github.com/aahsnr/.hyprdots.git"
readonly DOTFILES_DIR="$USER_HOME/.hyprdots"
readonly LOG_FILE="setup-log-$(date +%F_%H-%M).log"
DEBUG_MODE=false
NON_INTERACTIVE=false

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
  echo "Automates the setup of a complete Hyprland Environment on Fedora 42."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks interactively.${C_END}"
  echo ""
  echo -e "${C_HEADER}Options:${C_END}"
  echo -e "  ${C_GREEN}--initial-setup${C_END}         Deploy custom DNF and environment variable configurations."
  echo -e "  ${C_GREEN}--setup-repos${C_END}           Enable COPR and other repositories."
  echo -e "  ${C_GREEN}--setup-nvidia${C_END}          Install and configure NVIDIA drivers."
  echo -e "  ${C_GREEN}--install-groups${C_END}        Install package groups from 'groups.txt'."
  echo -e "  ${C_GREEN}--install-packages${C_END}      Install individual packages from 'packages.txt'."
  echo -e "  ${C_GREEN}--install-flatpaks${C_END}      Install Flatpak applications from 'flatpaks.txt'."
  echo -e "  ${C_GREEN}--setup-asus${C_END}            Run specific setup for ASUS laptops."
  echo -e "  ${C_GREEN}--manual-installs${C_END}       Perform manual installation of third-party software."
  echo -e "  ${C_GREEN}--setup-nix${C_END}             Install and configure Nix with Home-Manager."
  echo -e "  ${C_GREEN}--harden-system${C_END}         Implement basic security enhancements."
  echo -e "  ${C_GREEN}--configure-user${C_END}        Set up the user's environment."
  echo -e "  ${C_GREEN}--enable-system-services${C_END}  Enable optional system-wide services."
  echo -e "  ${C_GREEN}--setup-hyprland${C_END}        Enable systemd user services for Hyprland."
  echo -e "  ${C_GREEN}--cleanup${C_END}               Remove orphaned packages from the system."
  echo -e "  ${C_YELLOW}--debug${C_END}                 Enable verbose command tracing for debugging."
  echo -e "  ${C_YELLOW}--yes, -y${C_END}               Bypass all interactive prompts for automated runs."
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

  # Check for necessary commands and prompt to install if missing
  local missing_deps=()
  for cmd in git curl wget lspci; do
    if ! command_exists "$cmd"; then
      missing_deps+=("$cmd")
    fi
  done
  if ((${#missing_deps[@]} > 0)); then
    print_warning "The following dependencies are missing: ${missing_deps[*]}"
    sudo dnf install -y "${missing_deps[@]}"
  fi

  # Check for required input files
  for file in dnf.conf.txt 99-custom-env.sh.txt packages.txt groups.txt flatpaks.txt; do
    if [[ ! -f "$file" ]]; then
      print_error "Required configuration file '$file' not found. Aborting."
      exit 1
    fi
  done

  print_info "Priming sudo. You may be asked for your password now."
  sudo -v
  print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

# Copies initial system configuration files from local '.txt' files.
task_initial_files_setup() {
  print_step "Applying Initial System Configurations"
  local dnf_conf_content
  dnf_conf_content=$(<dnf.conf.txt)
  write_file_idempotent "/etc/dnf/dnf.conf" "$dnf_conf_content"

  local env_sh_content
  env_sh_content=$(<99-custom-env.sh.txt)
  write_file_idempotent "/etc/profile.d/99-custom-env.sh" "$env_sh_content"
  sudo chmod +x "/etc/profile.d/99-custom-env.sh"
}

# Configures DNF and enables third-party repositories.
task_setup_repos() {
  print_step "Setting up System Repositories"
  local copr_repos=("solopasha/hyprland" "errornointernet/quickshell" "deltacopy/darkly" "sneexy/zen-browser")
  for repo in "${copr_repos[@]}"; do
    if [ -f "/etc/yum.repos.d/_copr_${repo//\//-}.repo" ]; then
      print_success "COPR repository '$repo' is already enabled."
    else
      print_info "Enabling COPR repository: $repo"
      sudo dnf copr enable -y "$repo"
    fi
  done

  # RPM Fusion
  for repo_type in free nonfree; do
    if ! is_pkg_installed "rpmfusion-${repo_type}-release"; then
      print_info "Installing RPM Fusion $repo_type repository..."
      sudo dnf install -y "https://mirrors.rpmfusion.org/${repo_type}/fedora/rpmfusion-${repo_type}-release-$(rpm -E %fedora).noarch.rpm"
    else
      print_success "RPM Fusion $repo_type is already installed."
    fi
  done

  print_info "Updating system packages after repository setup..."
  sudo dnf update -y
}

# Installs and configures NVIDIA drivers.
task_setup_nvidia() {
  print_step "Setting up NVIDIA Drivers"
  if ! lspci | grep -qi 'VGA compatible controller: NVIDIA'; then
    print_warning "NVIDIA hardware not detected. Skipping driver installation."
    return
  fi
  if [[ "$(rpm -E %fedora)" -ne 42 ]]; then
    print_warning "This NVIDIA setup is intended for Fedora 42. Skipping driver installation."
    return
  fi

  print_info "Installing NVIDIA driver packages..."
  sudo dnf install -y --setopt=install_weak_deps=False \
    akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power \
    vulkan xorg-x11-drv-nvidia-cuda-libs nvidia-vaapi-driver libva-utils vdpauinfo libva-nvidia-driver

  print_info "Reloading systemd daemon to recognize new services..."
  sudo systemctl daemon-reload

  print_info "Marking 'akmod-nvidia' as a user-installed package."
  sudo dnf mark user akmod-nvidia

  print_info "Enabling NVIDIA power management services..."
  sudo systemctl enable nvidia-{suspend,resume,hibernate}

  print_info "Configuring RPM macros for open NVIDIA kernel modules..."
  sudo sh -c 'echo "%_with_kmod_nvidia_open 1" > /etc/rpm/macros.nvidia-kmod'

  print_info "Rebuilding akmods for the current kernel..."
  sudo akmods --kernels "$(uname -r)" --rebuild

  print_success "NVIDIA driver setup complete. A reboot is required."
}

# Reads the group list from 'groups.txt' and installs them.
task_install_groups() {
  print_step "Installing System Package Groups from File"
  mapfile -t group_ids < <(grep -vE '^\s*#|^\s*$' "groups.txt")

  if ((${#group_ids[@]} == 0)); then
    print_warning "No groups found in 'groups.txt'. Skipping."
    return
  fi

  local groups_to_install=("${group_ids[@]}")
  print_info "Installing ${#groups_to_install[@]} DNF groups..."
  sudo dnf group install -y "${groups_to_install[@]}"
}

# Reads the package list from 'packages.txt' and installs them.
task_install_packages() {
  print_step "Installing Individual System Packages from File"
  mapfile -t packages_to_install < <(grep -vE '^\s*#|^\s*$' "packages.txt")
  if ((${#packages_to_install[@]} == 0)); then
    print_warning "No packages found in 'packages.txt'. Skipping."
    return
  fi
  print_info "Installing ${#packages_to_install[@]} DNF packages..."
  sudo dnf install -y --allowerasing "${packages_to_install[@]}"
}

# Installs Flatpaks from the 'flatpaks.txt' file.
task_install_flatpaks() {
  print_step "Installing Flatpaks from File"
  if ! command_exists flatpak; then
    sudo dnf install -y flatpak
  fi

  print_info "Configuring Flathub repository for user '$TARGET_USER'..."
  run_as_user "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"

  mapfile -t flatpaks_to_install < <(grep -vE '^\s*#|^\s*$' "flatpaks.txt")
  if ((${#flatpaks_to_install[@]} == 0)); then
    print_warning "No applications found in 'flatpaks.txt'. Skipping."
    return
  fi
  print_info "Installing ${#flatpaks_to_install[@]} Flatpaks..."
  run_as_user "flatpak install -y flathub ${flatpaks_to_install[*]}"
  print_success "Flatpak installation process complete."
}

# Installs special drivers and tools for ASUS laptops.
task_setup_asus() {
  print_step "Setting up for ASUS Laptops"
  if ! sudo lspci | grep -qi 'ASUSTek'; then
    print_warning "ASUS hardware not detected. Skipping."
    return
  fi

  local asus_repo="lukenukem/asus-linux"
  if [ ! -f "/etc/yum.repos.d/_copr_lukenukem-asus-linux.repo" ]; then
    print_info "Enabling COPR repository for ASUS Linux: $asus_repo"
    sudo dnf copr enable -y "$asus_repo"
    sudo dnf update --refresh -y
  fi

  local asus_packages=("asusctl" "supergfxctl" "power-profiles-daemon" "asusctl-rog-gui")
  print_info "Installing ASUS-specific packages..."
  sudo dnf install -y --allowerasing "${asus_packages[@]}"
  sudo systemctl daemon-reload
  sudo systemctl enable --now supergfxd.service power-profiles-daemon.service
  print_success "ASUS-specific setup complete."
}

# Installs third-party software that is not available in standard repositories.
task_manual_installations() {
  print_step "Performing Manual Installations (as User)"

  # Install Breeze Plus Icons
  if [ -d "$USER_HOME/.local/share/icons/breeze-plus" ]; then
    print_success "Breeze Plus icons are already installed."
  else
    print_info "Installing Breeze Plus icon theme..."
    local tmp_repo_dir
    tmp_repo_dir=$(mktemp -d)
    TEMP_FILES+=("$tmp_repo_dir")
    run_as_user "git clone https://github.com/mjkim0727/breeze-plus.git '$tmp_repo_dir'"
    run_as_user "mkdir -p '$USER_HOME/.local/share/icons' && cp -r '$tmp_repo_dir'/src/breeze-plus* '$USER_HOME/.local/share/icons/'"
    print_success "Breeze Plus icons installed."
  fi

  # Install Private Internet Access (PIA) VPN
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
    print_warning "The PIA installer will now launch. It may prompt for an administrative password."
    # Installer handles its own privilege escalation.
    bash "$pia_installer"
    print_success "PIA VPN installation process finished."
  fi
}

# Installs and configures Nix, Flakes, and Home-Manager.
task_setup_nix() {
  print_step "Setting up Nix, Home-Manager, and Flakes"

  local nix_daemon_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

  if ! command_exists nix; then
    print_info "Installing Nix with the Determinate Systems installer..."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
  else
    print_success "Nix is already installed."
  fi

  if [ ! -f "$nix_daemon_profile" ]; then
    print_error "Nix daemon profile script not found. Cannot proceed."
    return 1
  fi
  # Source the profile for the current shell to ensure commands are available.
  . "$nix_daemon_profile"

  print_info "Ensuring Nix is configured to use flakes..."
  local nix_config_dir="$USER_HOME/.config/nix"
  local nix_config_file="$nix_config_dir/nix.conf"
  run_as_user "mkdir -p '$nix_config_dir'"
  run_as_user "echo 'experimental-features = nix-command flakes' > '$nix_config_file'"

  # Define the command prefix to correctly source the nix environment inside the subshell
  local nix_cmd_prefix=". '$nix_daemon_profile';"

  print_info "Initializing Home-Manager..."
  run_as_user "$nix_cmd_prefix nix run home-manager/master -- init --switch"
  run_as_user "rm -rf '$USER_HOME/.config/home-manager'"

  print_info "Cloning custom Home-Manager configuration repository..."
  run_as_user "git clone https://github.com/aahsnr-configs/home-manager.git ~/.config/home-manager"

  print_info "Switching to the new Home-Manager configuration..."
  if ! run_as_user "$nix_cmd_prefix home-manager switch"; then
    print_warning "Initial 'home-manager switch' failed. Retrying with backup flag..."
    run_as_user "$nix_cmd_prefix home-manager switch -b backup"
    run_as_user "$nix_cmd_prefix home-manager switch"
  fi
  print_success "Home-Manager switch complete."
}

# Applies system-wide security hardening configurations.
task_harden_system() {
  print_step "Applying System Security Hardening"
  write_file_idempotent "/etc/security/limits.d/99-custom-limits.conf" "* soft nofile 65536\n* hard nofile 1048576"
  local sshd_content="PermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes\nChallengeResponseAuthentication no"
  write_file_idempotent "/etc/ssh/sshd_config.d/99-hardened.conf" "$sshd_content"

  local sysctl_file="/etc/sysctl.d/99-custom-hardening.conf"
  if [ -f "$sysctl_file" ] && grep -q "# --- Custom Hardening Settings ---" "$sysctl_file"; then
    print_success "Custom sysctl settings already exist."
  else
    print_info "Appending custom sysctl settings to '$sysctl_file'..."
    local sysctl_content
    sysctl_content=$(
      cat <<'EOF'
# --- Custom Hardening Settings ---
dev.tty.ldisc_autoload = 0
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0
kernel.kptr_restrict = 2
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF
    )
    echo "$sysctl_content" | sudo tee "$sysctl_file" >/dev/null
    print_info "Applying kernel settings..."
    sudo sysctl -p "$sysctl_file"
  fi
}

# Sets up the user's shell, dotfiles, and application configs.
task_configure_user() {
  print_step "Configuring User Environment for $TARGET_USER"

  if command_exists setup-github-keys; then
    print_info "Executing 'setup-github-keys' for user '$TARGET_USER'..."
    run_as_user "setup-github-keys"
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    print_success "Dotfiles directory already exists."
  else
    print_info "Cloning Hyprland dotfiles..."
    run_as_user "git clone $DOTFILES_REPO_URL $DOTFILES_DIR"
  fi

  local nix_zsh_path="$USER_HOME/.nix-profile/bin/zsh"
  if [ -f "$nix_zsh_path" ] && ! grep -qFx "$nix_zsh_path" /etc/shells; then
    print_info "Adding Nix Zsh to /etc/shells..."
    echo "$nix_zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  local target_shell
  target_shell=$([ -f "$nix_zsh_path" ] && echo "$nix_zsh_path" || echo "/usr/bin/zsh")
  print_info "Setting default shell for '$TARGET_USER' to '$target_shell'."
  sudo chsh -s "$target_shell" "$TARGET_USER"

  print_info "Configuring NPM global directory."
  run_as_user "mkdir -p '$USER_HOME/.npm-global' && npm config set prefix '$USER_HOME/.npm-global'"
}

# Enables optional system-wide services for monitoring and performance.
task_enable_system_services() {
  print_step "Enabling System-wide Services"
  local system_services=("psacct.service" "sysstat.service" "rngd.service" "haveged.service")
  for service in "${system_services[@]}"; do
    if sudo systemctl enable --now "$service" 2>/dev/null; then
      print_success "Successfully enabled '$service'."
    else
      print_warning "Could not enable '$service'. The package may not be installed."
    fi
  done
}

# Enables systemd services required for the Hyprland desktop.
task_setup_hyprland() {
  print_step "Setting up Hyprland Desktop Services"
  run_as_user "systemctl --user daemon-reload"
  local user_services=("pipewire.service" "pipewire-pulse.service" "wireplumber.service" "hypridle.service" "hyprpaper.service")
  for service in "${user_services[@]}"; do
    if run_as_user "systemctl --user list-unit-files | grep -q '^${service}'"; then
      print_info "Enabling user service: $service"
      run_as_user "systemctl --user enable --now '$service'"
    else
      print_warning "Service unit '$service' not found. Skipping."
    fi
  done
}

# Removes orphaned packages from the system.
task_cleanup() {
  print_step "Cleaning Up System"
  print_info "Removing any orphaned packages..."
  sudo dnf autoremove -y
  print_success "System cleanup complete."
}

# --- Main Execution Logic ---
main() {
  # Redirect all output to a log file and the terminal
  exec &> >(tee -a "$LOG_FILE")
  print_info "$I_LOG Logging output to: $LOG_FILE"

  # --- Argument Parsing and Direct Action ---
  local RUN_ALL=true
  if (($# > 0)); then
    while (("$#")); do
      case "$1" in
      --initial-setup)
        RUN_ALL=false
        task_initial_files_setup
        shift
        ;;
      --setup-repos)
        RUN_ALL=false
        task_setup_repos
        shift
        ;;
      --setup-nvidia)
        RUN_ALL=false
        task_setup_nvidia
        shift
        ;;
      --install-groups)
        RUN_ALL=false
        task_install_groups
        shift
        ;;
      --install-packages)
        RUN_ALL=false
        task_install_packages
        shift
        ;;
      --install-flatpaks)
        RUN_ALL=false
        task_install_flatpaks
        shift
        ;;
      --setup-asus)
        RUN_ALL=false
        task_setup_asus
        shift
        ;;
      --manual-installs)
        RUN_ALL=false
        task_manual_installations
        shift
        ;;
      --setup-nix)
        RUN_ALL=false
        task_setup_nix
        shift
        ;;
      --harden-system)
        RUN_ALL=false
        task_harden_system
        shift
        ;;
      --configure-user)
        RUN_ALL=false
        task_configure_user
        shift
        ;;
      --enable-system-services)
        RUN_ALL=false
        task_enable_system_services
        shift
        ;;
      --setup-hyprland)
        RUN_ALL=false
        task_setup_hyprland
        shift
        ;;
      --cleanup)
        RUN_ALL=false
        task_cleanup
        shift
        ;;
      --debug)
        DEBUG_MODE=true
        shift
        ;;
      -y | --yes)
        NON_INTERACTIVE=true
        shift
        ;;
      --help)
        print_usage
        exit 0
        ;;
      *)
        print_error "Unknown flag: $1"
        print_usage
        exit 1
        ;;
      esac
    done
  fi

  if [ "$DEBUG_MODE" = true ]; then
    print_debug "Debug mode enabled. Activating verbose command tracing (set -x)."
    set -x
  fi

  pre_flight_checks

  # --- Full Interactive Execution Plan (only if no task flags were passed) ---
  if [ "$RUN_ALL" = true ]; then
    print_step "Full Installation Plan Summary"
    echo "This script will perform a full setup of a Hyprland desktop."
    [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
    if [[ "$NON_INTERACTIVE" = false && ! "$choice" =~ ^[Yy]$ ]]; then
      print_info "Aborting."
      exit 0
    fi

    task_initial_files_setup
    task_setup_repos

    # Ask about optional, hardware-specific tasks
    if lspci | grep -qi 'VGA compatible controller: NVIDIA'; then
      [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_CYAN}${I_PROMPT} NVIDIA hardware detected. Install drivers (for Fedora 42)? [Y/n]: ${C_END}")" -r nvidia_choice
      if [[ "$NON_INTERACTIVE" = true || ! "$nvidia_choice" =~ ^[Nn]$ ]]; then task_setup_nvidia; fi
    fi
    if lspci | grep -qi 'ASUSTek'; then
      [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_CYAN}${I_PROMPT} ASUS hardware detected. Install specific tools? [Y/n]: ${C_END}")" -r asus_choice
      if [[ "$NON_INTERACTIVE" = true || ! "$asus_choice" =~ ^[Nn]$ ]]; then task_setup_asus; fi
    fi

    task_install_groups
    task_install_packages

    [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_CYAN}${I_PROMPT} Do you want to install Flatpak applications? [y/N]: ${C_END}")" -r flatpak_choice
    if [[ "$NON_INTERACTIVE" = true || "$flatpak_choice" =~ ^[Yy]$ ]]; then task_install_flatpaks; fi

    task_manual_installations
    task_setup_nix
    task_harden_system
    task_configure_user
    task_enable_system_services
    task_setup_hyprland
    task_cleanup
  fi

  set +x
  print_step "$I_FINISH Run Complete!"
  print_success "All requested tasks finished successfully."
  print_warning "A final reboot is highly recommended to apply all changes."
}

# Pass all script arguments to the main function.
main "$@"
