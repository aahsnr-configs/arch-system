#!/usr/bin/env bash

# This script automates the setup of a complete Hyprland Environment on Arch Linux.
# It is a robust, idempotent, and modular script that reads package lists
# from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
#
# --- Features ---
#   - Automatic hardware detection for ASUS setups.
#   - Full logging of all operations to a timestamped log file.
#   - Idempotent design: safe to re-run without causing issues.
#   - Upfront dependency checking and installation.
#   - Robust execution of user-specific commands via a privilege de-escalation function.
#   - Fully interactive package management for user confirmation.
#
# --- Script Task Order ---
#   1.  Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.
#   2.  Initial Setup: Optimizes pacman.conf, overwrites makepkg.conf, and sets up environment variables.
#   3.  Setup Extra Repos (Optional): Adds CachyOS and BlackArch repositories.
#   4.  Setup AUR Helper: Installs 'yay-bin' for seamless access to the Arch User Repository.
#   5.  Install Kernel and Drivers (Optional): Installs the CachyOS kernel and NVIDIA drivers.
#   6.  Setup for ASUS Laptops (Optional): Adds the g14 repo and installs specific tools.
#   7.  Setup Greeter: Configures greetd and tuigreet as the login manager.
#   8.  Setup Nix & Home-Manager (Optional): Installs and configures Nix with flakes.
#   9.  Install Packages: Installs packages from 'packages.txt' using the AUR helper.
#   10. Manual Installs: Installs third-party software like themes and VPNs.
#   11. Harden System: Implements basic security enhancements and enables services.
#   12. Configure User: Sets up the user's dotfiles, shell, and SSH keys.
#   13. Cleanup: Removes orphaned packages and cleans the Nix store.

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
# Assign critical variables first and check for errors before making them read-only.
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

# Set up script-relative directories
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
readonly SCRIPT_DIR
readonly PRECONFIG_DIR="$SCRIPT_DIR/preconfig"

LOG_FILE="setup-log-$(date +%F_%H-%M).log"
readonly LOG_FILE

DEBUG_MODE=false

# --- Usage Information ---
print_usage() {
  echo -e "${C_BOLD}Usage: $0 [OPTIONS...]${C_END}"
  echo "Automates the setup of a complete Hyprland Environment on Arch Linux."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks interactively.${C_END}"
  echo ""
  echo -e "${C_HEADER}Options:${C_END}"
  echo -e "  ${C_GREEN}--initial-setup${C_END}           Perform initial system setup (pacman, environment vars)."
  echo -e "  ${C_GREEN}--setup-extra-repos${C_END}       Set up CachyOS and BlackArch repositories."
  echo -e "  ${C_GREEN}--setup-aur${C_END}               Install and configure the 'yay' AUR helper."
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
}

# --- Utility Functions ---
command_exists() { command -v "$1" &>/dev/null; }
is_pkg_installed() { pacman -Q "$1" &>/dev/null; }

# De-escalates privileges to run a command as the original user.
# This ensures correct file ownership and a sanitized environment, making
# user-specific operations more robust and portable.
run_as_user() {
  sudo -u "$TARGET_USER" bash -c "export HOME='$USER_HOME'; export USER='$TARGET_USER'; $*"
}

# Wrapper for package installation commands.
install_pkgs() {
  print_warning "You will be prompted to confirm the installation of the following packages: $*"
  yay -S --needed "$@"
}

# Wrapper for package removal commands.
remove_pkgs() {
  print_warning "You will be prompted to confirm the removal of the following packages: $*"
  yay -Rns "$@"
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

  # Check for necessary commands/packages and prompt to install if missing
  local missing_pkgs=()
  for pkg in git neovim wl-clipboard curl wget pciutils dmidecode base-devel; do
    if ! is_pkg_installed "$pkg" && [[ "$pkg" != "base-devel" ]]; then
      missing_pkgs+=("$pkg")
    elif [[ "$pkg" == "base-devel" ]] && ! is_pkg_installed "make"; then # Check for a key package from the group
      missing_pkgs+=("base-devel")
    fi
  done
  if ((${#missing_pkgs[@]} > 0)); then
    # First, ensure yay is available to install the dependencies.
    task_setup_aur_helper
    install_pkgs "${missing_pkgs[@]}"
  fi

  # Check for required input files
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
  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
  sudo sed -i '/^#\(Color\)/a ILoveCandy' /etc/pacman.conf
  sudo sed -i 's/^#\(VerbosePkgLists\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(DisableDownloadTimeout\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(TotalDownload\)/\1/' /etc/pacman.conf
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
    echo "--------------------------------------------------"
    cat /etc/pacman.conf
    echo "--------------------------------------------------"
    echo -e "\n${C_HEADER}Current /etc/makepkg.conf:${C_END}"
    echo "--------------------------------------------------"
    cat /etc/makepkg.conf
    echo "--------------------------------------------------"

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
      [Pp]*)
        print_info "Opening /etc/pacman.conf in vim..."
        sudo nvim /etc/pacman.conf
        ;;
      [Mm]*)
        print_info "Opening /etc/makepkg.conf in vim..."
        sudo nvim /etc/makepkg.conf
        ;;
      *)
        print_warning "Invalid selection. Returning to verification."
        ;;
      esac
      ;;
    *)
      print_warning "Invalid input. Please choose Y, n, or edit."
      ;;
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
    ( # Run in a subshell to isolate cd and prevent script exit
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

    print_info "Downloading BlackArch strap.sh script..."
    curl -o "$strap_sh" https://blackarch.org/strap.sh

    chmod +x "$strap_sh"
    sudo bash "$strap_sh"
    print_success "BlackArch repository setup finished."
  fi

  print_info "Synchronizing databases and upgrading system..."
  print_warning "You will be prompted to confirm the system upgrade."
  yay -Syyu

}

# Installs 'yay-bin' as the AUR helper.
task_setup_aur_helper() {
  print_step "Setting up AUR Helper (yay-bin)"
  if command_exists yay; then
    print_success "AUR helper 'yay' is already installed."
    return
  fi

  print_info "Installing 'yay-bin' from the AUR..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  sudo git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir"
  sudo chown -R "$TARGET_USER:$TARGET_USER" "$tmp_dir"
  (
    cd "$tmp_dir"
    print_info "Building and installing 'yay-bin'. This may take a moment..."
    print_warning "You will be prompted to confirm the build and installation."
    run_as_user "makepkg -si"
  )
  print_success "'yay' has been installed successfully."
}

# Installs the CachyOS kernel and corresponding NVIDIA drivers.
task_kernel_and_drivers() {
  print_step "Installing CachyOS Kernel and NVIDIA Drivers"
  if ! grep -q "\[cachyos\]" /etc/pacman.conf; then
    print_warning "CachyOS repository is not enabled. Skipping kernel and driver installation."
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
    g14_repo_conf=$(
      cat <<'EOF'

[g14]
Server = https://arch.asus-linux.org
EOF
    )
    echo "$g14_repo_conf" | sudo tee -a /etc/pacman.conf >/dev/null
    print_info "Synchronizing databases with the new repository..."
    yay -Syu
  fi

  print_info "Installing ASUS-specific packages from the g14 repository..."
  local asus_packages=("asusctl" "power-profiles-daemon" "supergfxctl" "switcheroo-control" "rog-control-center")
  install_pkgs "${asus_packages[@]}"

  print_info "Enabling required system services for ASUS hardware..."
  sudo systemctl daemon-reload
  sudo systemctl enable --now power-profiles-daemon.service
  print_success "Enabled 'power-profiles-daemon.service'."
  sudo systemctl enable --now supergfxd.service
  print_success "Enabled 'supergfxd.service'."
  sudo systemctl enable --now switcheroo-control.service
  print_success "Enabled 'switcheroo-control.service'."

  print_success "ASUS-specific setup complete."
}

# Sets up greetd with tuigreet as a lightweight, terminal-based login manager.
task_setup_greetd() {
  print_step "Setting up greetd and tuigreet"

  install_pkgs greetd greetd-tuigreet

  print_info "Configuring greetd to use tuigreet with Hyprland..."
  local greetd_config_content
  greetd_config_content=$(
    cat <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd Hyprland"
user = "greeter"
EOF
  )
  sudo mkdir -p /etc/greetd
  echo "$greetd_config_content" | sudo tee /etc/greetd/config.toml >/dev/null
  print_success "greetd configuration written to /etc/greetd/config.toml."

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
    run_as_user "curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm"
  else
    print_success "Nix appears to be already installed. Skipping installation."
  fi

  if [ -f "$nix_daemon_profile" ]; then
    print_info "Sourcing Nix environment profile for this session..."
    # shellcheck disable=SC1090
    . "$nix_daemon_profile"
  else
    print_error "Nix profile script '$nix_daemon_profile' not found. Cannot proceed."
    return 1
  fi

  if ! command_exists nix; then
    print_error "'nix' command is not available even after sourcing the profile. Aborting Nix setup."
    return 1
  fi

  print_info "Ensuring Nix is configured with flakes and optimizations..."
  local nix_config_dir="$USER_HOME/.config/nix"
  local nix_config_file="$nix_config_dir/nix.conf"
  local nix_conf_content
  nix_conf_content=$(
    cat <<'EOF'
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
  else
    print_warning "Home-Manager session variables file not found after switch."
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
    bash "$pia_installer"
    print_success "PIA VPN installation process finished."
  fi
}

# Applies system-wide security hardening configurations.
task_harden_system() {
  print_step "Applying System Security Hardening"

  # --- 1. Install Security Packages ---
  local security_packages=(
    acct apparmor apparmor.d-git audit arch-audit openssh procps-ng rng-tools
    sysstat haveged lynis-git libpwquality bleachbit xorg-xinit stacer-bin
    ssh-audit python-notify2 python-psutil ufw
  )
  install_pkgs "${security_packages[@]}"

  # --- 2. Enable Core Services ---
  print_info "Enabling system-wide services..."
  local system_services=(acct auditd apparmor bluetooth haveged rngd sshd)
  for service in "${system_services[@]}"; do
    print_info "Attempting to enable and start '$service'..."
    if sudo systemctl enable --now "${service}.service"; then
      print_success "Successfully enabled and started '$service'."
    else
      print_warning "Could not enable or start '$service'. It may not exist on this system."
    fi
  done

  # --- 3. Configure Auditing and AppArmor ---
  print_info "Configuring audit framework..."
  if ! grep -q '^audit:' /etc/group; then
    sudo groupadd -r audit && print_success "Created 'audit' group."
  fi
  sudo gpasswd -a "$TARGET_USER" audit
  if ! grep -q "^\s*log_group = audit" /etc/audit/auditd.conf; then
    echo "log_group = audit" | sudo tee -a /etc/audit/auditd.conf >/dev/null
    print_info "Set audit log group. Restarting auditd service..."
    sudo systemctl restart auditd.service
    print_success "Audit configuration applied."
  else
    print_success "Audit log group already configured."
  fi

  print_info "Creating AppArmor notification service..."
  run_as_user "mkdir -p '$USER_HOME/.config/autostart'"
  local apparmor_desktop_content
  apparmor_desktop_content=$(
    cat <<'EOF'
[Desktop Entry]
Type=Application
Name=AppArmor Notify
Comment=Receive on screen notifications of AppArmor denials
TryExec=aa-notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
StartupNotify=false
NoDisplay=true
EOF
  )
  run_as_user "echo -e \"$apparmor_desktop_content\" > \"$USER_HOME/.config/autostart/apparmor-notify.desktop\""
  print_success "AppArmor notifier created."

  # --- 4. Harden SSH and Firewall ---
  print_info "Hardening OpenSSH server configuration..."
  local sshd_hardening_content
  sshd_hardening_content=$(
    cat <<'EOF'
Port 47
LogLevel VERBOSE
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
X11Forwarding no
EOF
  )
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
  sysctl_content=$(
    cat <<'EOF'
dev.tty.ldisc_autoload = 0
fs.suid_dumpable = 0
kernel.kptr_restrict = 2
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.rp_filter = 1
EOF
  )
  echo "$sysctl_content" | sudo tee "$sysctl_file" >/dev/null
  sudo sysctl -p "$sysctl_file"
  print_success "Runtime kernel parameters have been applied."

  # --- 6. Harden /proc Filesystem ---
  print_info "Hardening /proc filesystem with hidepid..."
  if ! grep -q '^proc:' /etc/group; then
    sudo groupadd -r proc && print_success "Created 'proc' group for hidepid."
  fi
  if ! grep "^\s*proc\s*/proc" /etc/fstab | grep -q "hidepid=2"; then
    sudo sed -i 's|^\s*proc\s*/proc.*|proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0|' /etc/fstab
    print_info "Modified fstab for hidepid. Remounting /proc..."
    sudo mount -o remount /proc
    print_success "/proc has been remounted with hidepid=2."
  else
    print_success "/proc entry in fstab is already hardened."
  fi

  print_info "Creating systemd-logind override for hidepid compatibility..."
  sudo mkdir -p /etc/systemd/system/systemd-logind.service.d/
  local logind_override_content
  logind_override_content='[Service]\nSupplementaryGroups=proc'
  echo -e "$logind_override_content" | sudo tee /etc/systemd/system/systemd-logind.service.d/hidepid.conf >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl restart systemd-logind.service
  print_success "systemd-logind has been reconfigured and restarted."
}

# Sets up the user's shell, dotfiles, and application configs.
task_configure_user() {
  print_step "Configuring User Environment for $TARGET_USER"

  if command_exists setup-github-keys; then
    print_info "Executing 'setup-github-keys'..."
    # Execute directly to inherit the sourced Nix/HM environment
    setup-github-keys
  fi

  print_info "Setting default shell for '$TARGET_USER' to fish..."
  if run_as_user "chsh -s $(which fish)"; then
    print_success "Default shell set to fish."
  else
    print_error "Failed to set fish as the default shell."
  fi

  print_info "Configuring NPM global directory."
  run_as_user "mkdir -p '$USER_HOME/.npm-global' && npm config set prefix '$USER_HOME/.npm-global'"

  print_step "Setting up Hyprland Desktop Services"
  run_as_user "systemctl --user daemon-reload"
  local user_services=("pipewire.service" "pipewire-pulse.service" "wireplumber.service" "hypridle.service" "hyprpaper.service")
  for service in "${user_services[@]}"; do
    print_info "Attempting to enable user service: $service"
    if run_as_user "systemctl --user enable --now '$service'"; then
      print_success "Successfully enabled user service '$service'."
    else
      print_warning "Could not enable user service '$service'. It may not be available."
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
    yay -Rns "$(pacman -Qtdq)"
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
  exec &> >(tee -a "$LOG_FILE")
  print_info "$I_LOG Logging output to: $LOG_FILE"

  local RUN_ALL=true
  if (($# > 0)); then
    while (("$#")); do
      case "$1" in
      --initial-setup)
        RUN_ALL=false
        task_initial_setup
        shift
        ;;
      --setup-extra-repos)
        RUN_ALL=false
        task_setup_extra_repos
        shift
        ;;
      --setup-aur)
        RUN_ALL=false
        task_setup_aur_helper
        shift
        ;;
      --kernel-and-drivers)
        RUN_ALL=false
        task_kernel_and_drivers
        shift
        ;;
      --setup-asus)
        RUN_ALL=false
        task_setup_asus
        shift
        ;;
      --setup-greetd)
        RUN_ALL=false
        task_setup_greetd
        shift
        ;;
      --setup-nix)
        RUN_ALL=false
        task_setup_nix
        shift
        ;;
      --install-packages)
        RUN_ALL=false
        task_install_packages
        shift
        ;;
      --manual-installs)
        RUN_ALL=false
        task_manual_installations
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
      --cleanup)
        RUN_ALL=false
        task_cleanup
        shift
        ;;
      --debug)
        DEBUG_MODE=true
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

  if [ "$RUN_ALL" = true ]; then
    print_step "Full Installation Plan Summary"
    echo "This script will perform a full setup of a Hyprland desktop on Arch Linux."
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
      print_info "Aborting."
      exit 0
    fi

    task_initial_setup
    task_setup_extra_repos
    task_setup_aur_helper

    if grep -q "\[cachyos\]" /etc/pacman.conf; then
      read -p "$(echo -e "${C_CYAN}${I_PROMPT} CachyOS repo detected. Install optimized kernel and NVIDIA drivers? [Y/n]: ${C_END}")" -r cachyos_choice
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
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Attempting to re-execute with bash..." >&2
  exec bash "$0" "$@"
  echo "Failed to re-execute with bash. Please run the script using 'bash $0'." >&2
  exit 1
fi

# Call the main function with all script arguments.
main "$@"
