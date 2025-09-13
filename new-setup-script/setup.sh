#!/usr/bin/env bash

# This script automates the setup of a complete Hyprland Environment on Arch Linux.
# It is a robust, idempotent, and modular script that reads package lists
# from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
#
# --- Features ---
#   - Automatic hardware detection for NVIDIA and ASUS setups.
#   - ASUS setup uses the g14 repo with an interactive pacman session.
#   - Full logging of all operations to a timestamped log file.
#   - A '--yes' flag for fully non-interactive (automated) execution.
#   - Upfront dependency checking and installation.
#   - Idempotent design: safe to re-run without causing issues.
#
# --- Script Task Order ---
#   1.  Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.
#   2.  Configure Pacman: Optimizes pacman.conf and makepkg.conf with interactive verification.
#   3.  Setup AUR Helper: Installs 'paru' for seamless access to the Arch User Repository.
#   4.  Setup NVIDIA Drivers (Optional): Installs proprietary NVIDIA drivers if hardware is detected.
#   5.  Install Packages: Installs packages from 'packages.txt' using the AUR helper.
#   6.  Setup for ASUS Laptops (Optional): Adds the g14 repo and installs specific tools.
#   7.  Manual Installs: Installs third-party software like themes and VPNs.
#   8.  Setup Nix & Home-Manager (Optional): Installs and configures Nix with flakes.
#   9.  Harden System: Implements basic security enhancements and enables services.
#   10. Configure User: Sets up the user's dotfiles, shell, and SSH keys.
#   11. Setup Hyprland: Enables the necessary systemd user services.
#   12. Cleanup: Removes orphaned packages.

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
readonly DOTFILES_REPO_URL="https://github.com/aahsnr-configs/.hyprdots.git"
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
  echo "Automates the setup of a complete Hyprland Environment on Arch Linux."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks interactively.${C_END}"
  echo ""
  echo -e "${C_HEADER}Options:${C_END}"
  echo -e "  ${C_GREEN}--configure-pacman${C_END}      Optimize pacman.conf and makepkg.conf."
  echo -e "  ${C_GREEN}--setup-aur${C_END}             Install and configure the 'paru' AUR helper."
  echo -e "  ${C_GREEN}--setup-nvidia${C_END}          Install and configure NVIDIA drivers."
  echo -e "  ${C_GREEN}--install-packages${C_END}      Install packages from 'packages.txt'."
  echo -e "  ${C_GREEN}--setup-asus${C_END}            Run specific setup for ASUS laptops."
  echo -e "  ${C_GREEN}--manual-installs${C_END}       Perform manual installation of third-party software."
  echo -e "  ${C_GREEN}--setup-nix${C_END}             Install and configure Nix with Home-Manager."
  echo -e "  ${C_GREEN}--harden-system${C_END}         Implement basic security enhancements."
  echo -e "  ${C_GREEN}--configure-user${C_END}        Set up the user's environment."
  echo -e "  ${C_GREEN}--setup-hyprland${C_END}        Enable systemd user services for Hyprland."
  echo -e "  ${C_GREEN}--cleanup${C_END}               Remove orphaned packages from the system."
  echo -e "  ${C_YELLOW}--debug${C_END}                 Enable verbose command tracing for debugging."
  echo -e "  ${C_YELLOW}--yes, -y${C_END}               Bypass all interactive prompts for automated runs."
  echo -e "  ${C_BLUE}--help${C_END}                  Display this help message and exit."
}

# --- Utility Functions ---
command_exists() { command -v "$1" &>/dev/null; }
is_pkg_installed() { pacman -Q "$1" &>/dev/null; }
run_as_user() { sudo -u "$TARGET_USER" bash -c "export HOME='$USER_HOME'; export USER='$TARGET_USER'; $*"; }

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
  for pkg in git curl wget pciutils dmidecode base-devel; do
    if ! is_pkg_installed "$pkg" && [[ "$pkg" != "base-devel" ]]; then
      missing_pkgs+=("$pkg")
    elif [[ "$pkg" == "base-devel" ]] && ! is_pkg_installed "make"; then # Check for a key package from the group
      missing_pkgs+=("base-devel")
    fi
  done
  if ((${#missing_pkgs[@]} > 0)); then
    print_warning "The following dependencies are missing and will be installed: ${missing_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
  fi

  # Check for required input files
  for file in packages.txt; do
    if [[ ! -f "$file" ]]; then
      print_error "Required configuration file '$file' not found. Aborting."
      exit 1
    fi
  done

  print_info "Priming sudo. You may be asked for your password now."
  sudo -v
  print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

# Modifies pacman and makepkg configurations with user verification.
task_configure_pacman() {
  print_step "Configuring Pacman and Makepkg"

  # --- Modify pacman.conf ---
  print_info "Modifying /etc/pacman.conf..."
  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
  sudo sed -i '/^#\(Color\)/a ILoveCandy' /etc/pacman.conf
  sudo sed -i 's/^#\(VerbosePkgLists\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(DisableDownloadTimeout\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(ParallelDownloads\).*/\1 = 10/' /etc/pacman.conf
  # Add DownloadUser if it doesn't exist under the [options] section
  if ! grep -q "^DownloadUser" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a DownloadUser = alpm' /etc/pacman.conf
  else
    sudo sed -i 's/^DownloadUser.*/DownloadUser = alpm/' /etc/pacman.conf
  fi
  print_success "pacman.conf modifications applied."

  # --- Modify makepkg.conf ---
  print_info "Modifying /etc/makepkg.conf..."
  sudo sed -i 's/^CARCH=.*/CARCH="x86_64"/' /etc/makepkg.conf
  sudo sed -i 's/^CHOST=.*/CHOST="x86_64-pc-linux-gnu"/' /etc/makepkg.conf
  sudo sed -i 's/^#PACKAGECARCH=.*/PACKAGECARCH="x86_64"/' /etc/makepkg.conf
  sudo sed -i "s|^CFLAGS=.*|CFLAGS=\"-march=native -O3 -pipe -fno-plt -fexceptions -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security -fstack-clash-protection -fcf-protection\"|" /etc/makepkg.conf
  sudo sed -i "s|^CXXFLAGS=.*|CXXFLAGS=\"\$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS\"|" /etc/makepkg.conf
  sudo sed -i "s|^LDFLAGS=.*|LDFLAGS=\"-Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,-z,pack-relative-relocs\"|" /etc/makepkg.conf
  sudo sed -i "s|^#LTOFLAGS=.*|LTOFLAGS=\"-flto=auto\"|" /etc/makepkg.conf
  sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf
  sudo sed -i "s/^#NINJAFLAGS=.*/NINJAFLAGS=\"-j\$(nproc)\"/" /etc/makepkg.conf
  sudo sed -i "s/^#DEBUG_CFLAGS=.*/DEBUG_CFLAGS=\"-g\"/" /etc/makepkg.conf
  sudo sed -i "s/^#DEBUG_CXXFLAGS=.*/DEBUG_CXXFLAGS=\"\$DEBUG_CFLAGS\"/" /etc/makepkg.conf
  print_success "makepkg.conf modifications applied."

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

    if [ "$NON_INTERACTIVE" = true ]; then
      print_info "--yes flag detected. Proceeding automatically."
      break
    fi

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
        sudo vim /etc/pacman.conf
        ;;
      [Mm]*)
        print_info "Opening /etc/makepkg.conf in vim..."
        sudo vim /etc/makepkg.conf
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

# Installs 'paru' as the AUR helper.
task_setup_aur_helper() {
  print_step "Setting up AUR Helper (paru)"
  if command_exists paru; then
    print_success "AUR helper 'paru' is already installed."
    return
  fi

  print_info "Installing 'paru' from the AUR..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  run_as_user "git clone https://aur.archlinux.org/paru.git '$tmp_dir'"
  (
    cd "$tmp_dir"
    run_as_user "makepkg -si --noconfirm"
  )
  print_success "'paru' has been installed successfully."
}

# Installs and configures NVIDIA drivers for Arch Linux.
task_setup_nvidia() {
  print_step "Setting up NVIDIA Drivers"
  if ! lspci | grep -qi 'VGA compatible controller: NVIDIA'; then
    print_warning "NVIDIA hardware not detected. Skipping driver installation."
    return
  fi

  print_info "Installing NVIDIA driver packages..."
  # Use paru to handle potential conflicts and dependencies smoothly
  paru -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils \
    nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader libva-nvidia-driver

  print_info "Configuring kernel modules and initramfs..."
  # This part is crucial for Arch. We need to tell mkinitcpio to load nvidia modules.
  local mkinitcpio_conf="/etc/mkinitcpio.conf"
  if grep -q "^MODULES=.*nvidia" "$mkinitcpio_conf"; then
    print_success "NVIDIA modules already configured in mkinitcpio.conf."
  else
    print_info "Adding NVIDIA modules to mkinitcpio.conf..."
    sudo sed -i 's/^\(MODULES=.*\))$/\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$mkinitcpio_conf"
  fi

  print_info "Rebuilding the initramfs..."
  sudo mkinitcpio -P

  print_warning "For the NVIDIA driver to load correctly, you may need to add 'nvidia_drm.modeset=1' to your kernel parameters."
  print_warning "This is typically done in /boot/loader/entries/arch.conf (for systemd-boot) or by regenerating your GRUB config."
  print_success "NVIDIA driver setup complete. A reboot is required."
}

# Reads the package list from 'packages.txt' and installs them using paru.
task_install_packages() {
  print_step "Installing System Packages from File"
  mapfile -t packages_to_install < <(grep -vE '^\s*#|^\s*$' "packages.txt")
  if ((${#packages_to_install[@]} == 0)); then
    print_warning "No packages found in 'packages.txt'. Skipping."
    return
  fi
  print_info "Installing/updating ${#packages_to_install[@]} packages from official repos and the AUR..."
  paru -S --needed --noconfirm "${packages_to_install[@]}"
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
    print_info "Synchronizing pacman databases with the new repository..."
    # Run interactively
    sudo pacman -Sy
  fi

  print_info "Installing ASUS-specific packages from the g14 repository..."
  print_warning "You will now be prompted by pacman to confirm the installation."
  local asus_packages=("asusctl" "power-profiles-daemon" "supergfxctl" "switcheroo-control" "rog-control-center")
  # Run interactively by removing --noconfirm
  sudo pacman -S --needed "${asus_packages[@]}"

  print_info "Enabling required system services for ASUS hardware..."
  local asus_services=("power-profiles-daemon.service" "supergfxd.service" "switcheroo-control.service")
  sudo systemctl daemon-reload
  for service in "${asus_services[@]}"; do
    sudo systemctl enable --now "$service"
  done

  print_success "ASUS-specific setup complete."
}

# Installs third-party software that is not available in standard repositories.
task_manual_installations() {
  print_step "Performing Manual Installations (as User)"

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
    if [ -f "$nix_daemon_profile" ]; then
      . "$nix_daemon_profile"
    else
      print_error "Nix daemon profile script '$nix_daemon_profile' not found after installation. Cannot proceed."
      return 1
    fi
  else
    print_success "Nix is already installed."
    if [ -f "$nix_daemon_profile" ]; then
      . "$nix_daemon_profile"
    else
      print_error "Nix daemon profile script '$nix_daemon_profile' not found, but 'nix' command exists. This is unexpected."
      return 1
    fi
  fi

  print_info "Ensuring Nix is configured with flakes and optimizations..."
  local nix_config_dir="$USER_HOME/.config/nix"
  local nix_config_file="$nix_config_dir/nix.conf"
  local nix_conf_content
  nix_conf_content=$(
    cat <<'EOF'
experimental-features = nix-command flakes
auto-optimise-store = true
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
    run_as_user "rm -rf '$USER_HOME/.config/home-manager'"
  fi

  local hm_config_repo_url="https://github.com/aahsnr-configs/home-manager.git"
  local hm_config_dir="$USER_HOME/.config/home-manager"
  if run_as_user "[ -d '$hm_config_dir' ]"; then
    print_success "Custom Home-Manager configuration already cloned to '$hm_config_dir'."
    print_info "Attempting to pull latest changes for Home-Manager configuration..."
    if ! run_as_user "git -C '$hm_config_dir' pull origin master"; then
      print_warning "Failed to pull latest Home-Manager configuration."
    else
      print_success "Pulled latest Home-Manager configuration."
    fi
  else
    print_info "Cloning custom Home-Manager configuration repository..."
    run_as_user "git clone '$hm_config_repo_url' '$hm_config_dir'"
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
    print_info "Sourcing Home-Manager session variables for the current script's environment."
    run_as_user ". '$hm_session_vars'"
    print_success "Home-Manager environment variables applied to current script session."
  else
    print_warning "Home-Manager session variables file '$hm_session_vars' not found after switch."
  fi

  print_success "Nix, Home-Manager, and Flakes setup complete."
}

# Applies system-wide security hardening configurations.
task_harden_system() {
  print_step "Applying System Security Hardening"

  # --- 1. Install Security Packages and Enable Services ---
  print_info "Installing security and monitoring packages..."
  local security_packages=(
    acct apparmor apparmor.d-git audit arch-audit openssh procps-ng rng-tools
    sysstat haveged lynis-git libpwquality bleachbit xorg-xinit stacer-bin
    ssh-audit python-notify2 python-psutil
  )
  paru -S --needed --noconfirm "${security_packages[@]}"

  print_info "Enabling system-wide services for security and performance..."
  local system_services=(acct auditd apparmor haveged rngd sshd)
  for service in "${system_services[@]}"; do
    if sudo systemctl enable --now "$service" 2>/dev/null; then
      print_success "Successfully enabled '$service'."
    else
      print_warning "Could not enable '$service'."
    fi
  done

  # --- 2. Configure Kernel Parameters, Auditd, and AppArmor Notifier ---
  print_info "Configuring kernel parameters for enhanced security..."
  local kernel_params="lsm=landlock,lockdown,yama,integrity,apparmor,bpf audit=1"
  local grub_cfg="/etc/default/grub"
  # For systemd-boot, find the conf file in the entries directory
  local systemd_boot_entry
  systemd_boot_entry=$(find /boot/loader/entries -type f -name "*.conf" 2>/dev/null | head -n 1)

  if [ -f "$grub_cfg" ]; then
    print_info "GRUB bootloader detected. Modifying $grub_cfg..."
    if ! grep -q "GRUB_CMDLINE_LINUX.*$kernel_params" "$grub_cfg"; then
      sudo sed -i "s/^\(GRUB_CMDLINE_LINUX=\"\)/\1$kernel_params /" "$grub_cfg"
      print_info "Regenerating GRUB configuration..."
      sudo grub-mkconfig -o /boot/grub/grub.cfg
    else
      print_success "Kernel parameters already set in GRUB."
    fi
  elif [ -n "$systemd_boot_entry" ]; then
    print_info "systemd-boot detected. Modifying $systemd_boot_entry..."
    if ! grep -q "options.*$kernel_params" "$systemd_boot_entry"; then
      sudo sed -i "s/^\(options.*\)/\1 $kernel_params/" "$systemd_boot_entry"
      print_success "Kernel parameters added to systemd-boot entry."
    else
      print_success "Kernel parameters already set in systemd-boot."
    fi
  else
    print_warning "Could not detect GRUB or systemd-boot. Please add the following to your kernel cmdline manually:"
    print_warning "$kernel_params"
  fi

  print_info "Configuring audit framework..."
  if ! grep -q '^audit:' /etc/group; then
    sudo groupadd -r audit
    print_success "Created 'audit' group."
  fi
  sudo gpasswd -a "$TARGET_USER" audit
  if ! grep -q "^log_group = audit" /etc/audit/auditd.conf; then
    sudo sed -i '1s/^/log_group = audit\n/' /etc/audit/auditd.conf
    print_success "Set audit log group."
  else
    print_success "Audit log group already configured."
  fi

  print_info "Creating AppArmor notification service for user $TARGET_USER..."
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

  # --- 3. Harden OpenSSH Server ---
  print_info "Hardening OpenSSH server configuration..."
  local sshd_hardening_content
  sshd_hardening_content=$(
    cat <<'EOF'
# --- Custom Hardening Settings ---
Port 47
LogLevel VERBOSE
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
TCPKeepAlive no
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
EOF
  )
  echo "$sshd_hardening_content" | sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null

  # --- 4. Configure Firewall ---
  if command_exists ufw; then
    print_info "Configuring UFW firewall for hardened SSH port..."
    sudo ufw allow 47/tcp comment 'Custom SSH Port'
    sudo ufw deny 22/tcp comment 'Default SSH Port'
    sudo ufw enable
    print_success "UFW enabled and configured for SSH on port 47."
  else
    print_warning "'ufw' is not installed. Skipping firewall configuration. Please open TCP port 47 manually."
  fi
  sudo systemctl reload sshd

  # --- 5. Harden Kernel Parameters via sysctl ---
  local sysctl_file="/etc/sysctl.d/99-custom-hardening.conf"
  print_info "Applying custom sysctl kernel settings..."
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
  sudo sysctl -p "$sysctl_file"

  # --- 6. Harden /proc and logind for process hiding ---
  print_info "Hardening /proc filesystem with hidepid..."
  if grep -q "^\s*proc\s*/proc" /etc/fstab; then
    if ! grep "^\s*proc\s*/proc" /etc/fstab | grep -q "hidepid=2"; then
      sudo sed -i 's|^\s*proc\s*/proc.*|proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0|' /etc/fstab
      print_success "Modified /proc entry in /etc/fstab."
    else
      print_success "/proc entry in /etc/fstab is already hardened."
    fi
  else
    echo "proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0" | sudo tee -a /etc/fstab
    print_success "Added hardened /proc entry to /etc/fstab."
  fi

  print_info "Creating systemd-logind override for hidepid compatibility..."
  sudo mkdir -p /etc/systemd/system/systemd-logind.service.d/
  local logind_override_content
  logind_override_content=$(
    cat <<'EOF'
[Service]
SupplementaryGroups=proc
EOF
  )
  echo "$logind_override_content" | sudo tee /etc/systemd/system/systemd-logind.service.d/hidepid.conf >/dev/null
  print_success "systemd-logind override created."
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
  # Check if there are any orphans before trying to remove them
  if pacman -Qtdq >/dev/null; then
    sudo pacman -Rns --noconfirm "$(pacman -Qtdq)"
  fi
  print_success "System cleanup complete."
}

# --- Main Execution Logic ---
main() {
  exec &> >(tee -a "$LOG_FILE")
  print_info "$I_LOG Logging output to: $LOG_FILE"

  local RUN_ALL=true
  if (($# > 0)); then
    while (("$#")); do
      case "$1" in
      --configure-pacman)
        RUN_ALL=false
        task_configure_pacman
        shift
        ;;
      --setup-aur)
        RUN_ALL=false
        task_setup_aur_helper
        shift
        ;;
      --setup-nvidia)
        RUN_ALL=false
        task_setup_nvidia
        shift
        ;;
      --install-packages)
        RUN_ALL=false
        task_install_packages
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

  if [ "$RUN_ALL" = true ]; then
    print_step "Full Installation Plan Summary"
    echo "This script will perform a full setup of a Hyprland desktop on Arch Linux."
    [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
    if [[ "$NON_INTERACTIVE" = false && ! "$choice" =~ ^[Yy]$ ]]; then
      print_info "Aborting."
      exit 0
    fi

    task_configure_pacman
    task_setup_aur_helper

    # Hardware-specific checks
    if lspci | grep -qi 'VGA compatible controller: NVIDIA'; then
      [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_CYAN}${I_PROMPT} NVIDIA hardware detected. Install drivers? [Y/n]: ${C_END}")" -r nvidia_choice
      if [[ "$NON_INTERACTIVE" = true || ! "$nvidia_choice" =~ ^[Nn]$ ]]; then task_setup_nvidia; fi
    fi
    if sudo dmidecode -s system-manufacturer | grep -qi "ASUS"; then
      [ "$NON_INTERACTIVE" = false ] && read -p "$(echo -e "${C_CYAN}${I_PROMPT} ASUS hardware detected. Install specific tools? [Y/n]: ${C_END}")" -r asus_choice
      if [[ "$NON_INTERACTIVE" = true || ! "$asus_choice" =~ ^[Nn]$ ]]; then task_setup_asus; fi
    fi

    task_install_packages
    task_manual_installations
    task_setup_nix
    task_harden_system
    task_configure_user
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
