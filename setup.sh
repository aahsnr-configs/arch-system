#!/usr/bin/env bash

# =================================================================================== #
# Hyprland Arch Linux Setup Script (Paru Edition)
#
# This script automates the setup of a complete Hyprland Environment on Arch Linux.
# It uses 'paru' as its AUR helper.
#
# MODIFICATION: The dangerous 'yes | ...' pipe has been replaced with the safer
# '--noconfirm' flag for all package manager commands. This prevents the script
# from blindly accepting potentially destructive actions. The script will now correctly
# halt on unresolvable package conflicts, which is the desired safe behavior.
# =================================================================================== #

# --- Script Features ---
#   - Automatic hardware detection for ASUS setups.
#   - Full logging of all operations to a timestamped log file.
#   - Idempotent design: safe to re-run without causing issues.
#   - Upfront dependency checking and installation.
#   - Robust execution of user-specific commands via a privilege de-escalation function.
#   - Streamlined user prompts: Pressing 'Enter' defaults to 'Yes' for confirmations.
#   - Embedded documentation accessible via '--docs' and per-task via '--<task> --docs'.
#   - Interactive full-run mode that explains each task and prompts for confirmation.

#  NOTE:
# --- Script Task Order (Full Installation) ---
#   1.  Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.
#       (Includes automatic setup of 'paru' and installation of 'limine-mkinitcpio-hook').
#   2.  Initial Setup: Optimizes pacman.conf, makepkg.conf, reflector, and environment variables.
#   3.  Setup Extra Repos: Adds the CachyOS repository.
#   4.  Setup for ASUS Laptops: Adds the g14 repo and installs specific tools.
#   5.  Install Packages: Installs packages from 'packages.txt'.
#   6.  Manual Installs: Installs third-party software like VPNs.
#   7.  Setup Dotfiles: Symlinks user dotfiles using 'stow'.
#   8.  Setup Nix & Home-Manager: Installs and configures Nix with flakes.
#   9.  Configure User: Sets up the user's shell, services, and XDG directories.
#   10. Setup Editors: Configures Neovim and Doom Emacs with custom configs.
#   11. Cleanup: Removes orphaned packages and cleans the Nix store.
#   12. Setup Greeter: Configures greetd and tuigreet as the login manager.
#   13. Harden System: Implements basic security enhancements and services.

# --- Script Setup and Error Handling ---
set -euo pipefail

# --- Cleanup Trap ---
TEMP_FILES=()
cleanup() {
  set +x # Disable command tracing during cleanup
  if [ ${#TEMP_FILES[@]} -gt 0 ]; then
    rm -rf "${TEMP_FILES[@]}"
  fi
}
trap cleanup EXIT ERR INT TERM

# --- User Interface: Tokyonight Night Theme, Colors, and Icons ---
readonly C_MAUVE=$'\033[38;2;187;154;247m'    # Tokyonight Purple (for Steps)
readonly C_LAVENDER=$'\033[38;2;122;162;247m' # Tokyonight Blue (for Descriptions)
readonly C_PEACH=$'\033[38;2;224;175;104m'    # Tokyonight Orange (for Warnings)
readonly C_SKY=$'\033[38;2;125;207;255m'      # Tokyonight Cyan (for File Paths)
readonly C_GREEN=$'\033[38;2;158;206;106m'    # Tokyonight Green (for Success)
readonly C_RED=$'\033[38;2;247;118;142m'      # Tokyonight Red (for Errors)
readonly C_SAPPHIRE=$'\033[38;2;122;162;247m' # Tokyonight Blue (for Info)
readonly C_YELLOW=$'\033[38;2;224;175;104m'   # Tokyonight Orange (for Prompts)
readonly C_TEXT=$'\033[38;2;192;202;245m'     # Tokyonight Foreground (for main text)
readonly C_BOLD=$'\033[1m'
readonly C_ITALIC=$'\033[3m'
readonly C_END=$'\033[0m'

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
print_step() { echo -e "\n${C_MAUVE}${C_BOLD}═══ $I_STEP $1 ═══${C_END}"; }
print_info() { echo -e "${C_SAPPHIRE}$I_INFO $1${C_END}"; }
print_success() { echo -e "${C_GREEN}$I_SUCCESS $1${C_END}"; }
print_warning() { echo -e "${C_PEACH}$I_WARN $1${C_END}" >&2; }
print_error() { echo -e "${C_RED}$I_ERROR $1${C_END}" >&2; }
print_debug() {
  if [ "$DEBUG_MODE" = true ]; then
    echo -e "${C_SKY}$I_DEBUG [DEBUG] $1${C_END}" >&2
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
readonly LOGS_DIR="$SCRIPT_DIR/logs"

LOG_FILE="" # Will be set by setup_logging()

DEBUG_MODE=false
RUN_ALL=true

# --- Modular Documentation Functions ---

docs_pre_flight_checks() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Performing Pre-flight Safety Checks${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}This initial step performs critical safety and environment checks to ensure the
script can run successfully.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Privilege Verification:${C_END}${C_TEXT} Ensures the script is ${C_RED}NOT${C_END}${C_TEXT} run as the root user.${C_END}
- ${C_PEACH}${C_BOLD}Connectivity Check:${C_END}${C_TEXT} Pings ${C_SKY}8.8.8.8${C_END}${C_TEXT} to confirm internet access.${C_END}
- ${C_PEACH}${C_BOLD}AUR Helper Setup:${C_END}
  - ${C_TEXT}Detects if ${C_GREEN}paru${C_END}${C_TEXT} is installed.${C_END}
  - ${C_TEXT}If not found, it installs ${C_GREEN}git${C_END}${C_TEXT} and ${C_GREEN}base-devel${C_END}${C_TEXT}, clones the
    ${C_SKY}paru-bin.git${C_END}${C_TEXT} repository, and builds it using ${C_SKY}makepkg -si${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Dependency Installation:${C_END}
  - ${C_TEXT}Checks for and installs essential script dependencies:
    ${C_GREEN}neovim${C_END}${C_TEXT}, ${C_GREEN}wl-clipboard${C_END}${C_TEXT}, ${C_GREEN}curl${C_END}${C_TEXT}, ${C_GREEN}wget${C_END}${C_TEXT}, ${C_GREEN}pciutils${C_END}${C_TEXT}, ${C_GREEN}dmidecode${C_END}${C_TEXT}, ${C_GREEN}xdg-user-dirs${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Bootloader Hook:${C_END}${C_TEXT} Ensures the ${C_GREEN}limine-mkinitcpio-hook${C_END}${C_TEXT} package is installed
  to automate bootloader updates when new kernels are installed.${C_END}
- ${C_PEACH}${C_BOLD}Configuration File Check:${C_END}${C_TEXT} Verifies that these files exist:
  - ${C_SKY}${PRECONFIG_DIR}/packages.txt${C_END}
  - ${C_SKY}${PRECONFIG_DIR}/makepkg.conf.txt${C_END}
  - ${C_SKY}${PRECONFIG_DIR}/99-custom-env.sh.txt${C_END}
- ${C_PEACH}${C_BOLD}Sudo Priming:${C_END}${C_TEXT} Runs ${C_SKY}sudo -v${C_END}${C_TEXT} to cache credentials, preventing most
  password prompts during the script's execution.${C_END}
EOF
}

docs_initial_setup() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Configuring Core System Files${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Configures core system files for better performance and user experience.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Environment Variables:${C_END}${C_TEXT} Copies the custom environment file
  ${C_SKY}${PRECONFIG_DIR}/99-custom-env.sh.txt${C_END}${C_TEXT} to ${C_SKY}/etc/profile.d/99-custom-env.sh${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Pacman Configuration:${C_END}${C_TEXT} Modifies ${C_SKY}/etc/pacman.conf${C_END}${C_TEXT} using ${C_SKY}sed${C_END}${C_TEXT} to:
  - Enable ${C_SKY}Color${C_END}${C_TEXT} and add ${C_SKY}ILoveCandy${C_END}${C_TEXT}.${C_END}
  - Enable ${C_SKY}VerbosePkgLists${C_END}${C_TEXT}.${C_END}
  - Uncomment ${C_SKY}DisableDownloadTimeout${C_END}${C_TEXT}.${C_END}
  - Set ${C_SKY}ParallelDownloads = 10${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Makepkg Configuration:${C_END}${C_TEXT} Overwrites ${C_SKY}/etc/makepkg.conf${C_END}${C_TEXT} with the contents of
  ${C_SKY}${PRECONFIG_DIR}/makepkg.conf.txt${C_END}${C_TEXT} to optimize package compilation.${C_END}
- ${C_PEACH}${C_BOLD}Mirrorlist Management:${C_END}
  - ${C_TEXT}Installs the ${C_GREEN}reflector${C_END}${C_TEXT} package.${C_END}
  - ${C_TEXT}Enables and starts ${C_SKY}reflector.service${C_END}${C_TEXT} and ${C_SKY}reflector.timer${C_END}${C_TEXT}.${C_END}
  - ${C_TEXT}Performs an initial mirrorlist update, sorting by rate for servers in
    Bangladesh, India, and Singapore, saving the result to ${C_SKY}/etc/pacman.d/mirrorlist${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}User Verification:${C_END}
  - ${C_TEXT}After making changes, the script displays the contents of ${C_SKY}/etc/pacman.conf${C_END}
    ${C_TEXT}and ${C_SKY}/etc/makepkg.conf${C_END}${C_TEXT}.${C_END}
  - ${C_TEXT}It then enters an interactive loop, prompting you to approve the changes
    or edit the files directly using ${C_GREEN}nvim${C_END}${C_TEXT}.${C_END}
EOF
}

docs_setup_extra_repos() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Setting Up the CachyOS Repository${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Adds and configures the CachyOS pacman repository for performance-optimized packages.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}CachyOS Repository:${C_END}
  - ${C_TEXT}Checks if the ${C_SKY}[cachyos]${C_END}${C_TEXT} repository is already in ${C_SKY}/etc/pacman.conf${C_END}${C_TEXT}.${C_END}
  - ${C_TEXT}If not, it downloads ${C_SKY}cachyos-repo.tar.xz${C_END}${C_TEXT}, extracts it, and runs the
    official ${C_SKY}./cachyos-repo.sh${C_END}${C_TEXT} script.${C_END}
  - ${C_YELLOW}This part of the setup is interactive and requires user input.${C_END}
- ${C_PEACH}${C_BOLD}System Upgrade:${C_END}
  - ${C_TEXT}After adding the repository, it forces a full system synchronization and
    upgrade by running ${C_SKY}paru -Syu${C_END}${C_TEXT}.${C_END}
EOF
}

docs_setup_asus() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Configuring ASUS Laptop Support${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Performs hardware-specific setup for ASUS laptops.${C_END}

${C_PEACH}${C_BOLD}Condition:${C_END}
- ${C_TEXT}This task is skipped automatically if ${C_SKY}dmidecode -s system-manufacturer${C_END}
  ${C_TEXT}does not report "ASUS".${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Add GPG Key:${C_END}${C_TEXT} Imports and locally signs the GPG key required for the
  ASUS Linux repository.${C_END}
- ${C_PEACH}${C_BOLD}Add Repository:${C_END}${C_TEXT} Adds the ${C_SKY}[g14]${C_END}${C_TEXT} repository from ${C_SKY}https://arch.asus-linux.org${C_END}
  to ${C_SKY}/etc/pacman.conf${C_END}${C_TEXT} and runs ${C_SKY}paru -Syu${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Install Packages:${C_END}${C_TEXT} Installs ASUS-specific tools including:
  - ${C_GREEN}asusctl${C_END}${C_TEXT}, ${C_GREEN}power-profiles-daemon${C_END}${C_TEXT}, ${C_GREEN}supergfxctl${C_END}${C_TEXT}, ${C_GREEN}switcheroo-control${C_END}${C_TEXT},
    and ${C_GREEN}rog-control-center${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Enable Services:${C_END}${C_TEXT} Enables and starts the required systemd services:
  - ${C_SKY}power-profiles-daemon.service${C_END}
  - ${C_SKY}supergfxd.service${C_END}
  - ${C_SKY}switcheroo-control.service${C_END}
EOF
}

docs_setup_greetd() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Setting Up the Login Manager${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Configures a lightweight, terminal-based display manager (login screen).${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Installation:${C_END}${C_TEXT} Installs the ${C_GREEN}greetd${C_END}${C_TEXT} package and the ${C_GREEN}greetd-tuigreet${C_END}${C_TEXT} greeter.${C_END}
- ${C_PEACH}${C_BOLD}Configuration:${C_END}${C_TEXT} Creates the configuration file at ${C_SKY}/etc/greetd/config.toml${C_END}
  ${C_TEXT}and sets the default command to launch Hyprland via ${C_SKY}tuigreet --cmd Hyprland${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Conflict Resolution:${C_END}
  - ${C_TEXT}Checks if the ${C_GREEN}sddm${C_END}${C_TEXT} package is installed.${C_END}
  - ${C_TEXT}If found, it disables the ${C_SKY}sddm.service${C_END}${C_TEXT} and removes the package to
    prevent conflicts with greetd.${C_END}
- ${C_PEACH}${C_BOLD}Service Management:${C_END}${C_TEXT} Enables the ${C_SKY}greetd.service${C_END}${C_TEXT} to launch at boot.${C_END}
EOF
}

docs_install_packages() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Installing System Packages${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}The main package installation task. It reads package names line-by-line from
the configuration file and installs them.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_TEXT}Reads the file ${C_SKY}${PRECONFIG_DIR}/packages.txt${C_END}${C_TEXT}.${C_END}
- ${C_TEXT}Ignores any lines that are empty or start with a ${C_SKY}#${C_END}${C_TEXT} character.${C_END}
- ${C_TEXT}Passes the entire list of remaining package names to a single
  ${C_SKY}paru -S --needed${C_END}${C_TEXT} command to install them from both the
  official repositories and the AUR.${C_END}
EOF
}

docs_setup_dotfiles() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Linking User Dotfiles with Stow${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Symlinks configuration files from a local 'dotfiles' directory into the user's
home directory using the 'stow' utility.${C_END}

${C_PEACH}${C_BOLD}Condition:${C_END}
- ${C_TEXT}This task requires a 'dotfiles' directory to exist in the same location
  as the setup script. If not found, the task will be skipped.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Install Stow:${C_END}${C_TEXT} Checks if the ${C_GREEN}stow${C_END}${C_TEXT} package is installed and installs it if missing.${C_END}
- ${C_PEACH}${C_BOLD}Change Directory:${C_END}${C_TEXT} Navigates into the ${C_SKY}${SCRIPT_DIR}/dotfiles/${C_END}${C_TEXT} directory.${C_END}
- ${C_PEACH}${C_BOLD}Execute Stow:${C_END}${C_TEXT} Runs the command ${C_SKY}stow . -t ~${C_END}${C_TEXT} as the target user.
  This command symlinks all packages within the dotfiles directory to the user's
  home directory, creating the correct file structure.${C_END}
EOF
}

docs_setup_nix() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Setting up Nix & Home-Manager${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Installs and configures the Nix package manager with Home-Manager and Flakes.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Nix Installation:${C_END}
  - ${C_TEXT}Checks for the existence of the ${C_SKY}/nix/store${C_END}${C_TEXT} directory.${C_END}
  - ${C_TEXT}If not found, it downloads and runs the official Determinate Systems installer.${C_END}
  - ${C_YELLOW}The Nix installer is interactive and will require user confirmation.${C_END}
- ${C_PEACH}${C_BOLD}Environment Setup:${C_END}${C_TEXT} Sources the Nix environment from
  ${C_SKY}/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Nix Configuration:${C_END}${C_TEXT} Creates ${C_SKY}${USER_HOME}/.config/nix/nix.conf${C_END}${C_TEXT} to enable
  the ${C_SKY}nix-command${C_END}${C_TEXT} and ${C_SKY}flakes${C_END}${C_TEXT} experimental features.${C_END}
- ${C_PEACH}${C_BOLD}Home-Manager Initialization:${C_END}
  - ${C_TEXT}Runs ${C_SKY}nix run home-manager/master -- init --switch${C_END}${C_TEXT} to set up Home-Manager
    for the first time.${C_END}
  - ${C_TEXT}Executes ${C_SKY}home-manager switch${C_END}${C_TEXT} to apply the configuration. If this fails,
    it retries once with a backup flag before the final attempt.${C_END}
EOF
}

docs_manual_installations() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Handling Manual Installations${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Handles software that cannot be installed through a standard package manager.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Private Internet Access VPN:${C_END}
  - ${C_TEXT}Checks if the ${C_GREEN}pia-client${C_END}${C_TEXT} command already exists.${C_END}
  - ${C_TEXT}If not, it downloads the official installer script
    (${C_SKY}pia-linux-3.6.2-08398.run${C_END}${C_TEXT}) using ${C_SKY}wget${C_END}${C_TEXT}.${C_END}
  - ${C_TEXT}It makes the script executable and then runs it.${C_END}
  - ${C_YELLOW}The PIA installer has its own user interface and requires interaction.${C_END}
EOF
}

docs_harden_system() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Applying System Security Hardening${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Applies a variety of security enhancements to the system.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Install Packages:${C_END}${C_TEXT} Installs security tools like ${C_GREEN}apparmor${C_END}${C_TEXT}, ${C_GREEN}audit${C_END}${C_TEXT},
  ${C_GREEN}ufw${C_END}${C_TEXT}, ${C_GREEN}haveged${C_END}${C_TEXT}, and ${C_GREEN}lynis-git${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Enable Services:${C_END}${C_TEXT} Enables and starts core security services like
  ${C_SKY}auditd.service${C_END}${C_TEXT}, ${C_SKY}apparmor.service${C_END}${C_TEXT}, and ${C_SKY}sshd.service${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Harden SSH:${C_END}${C_TEXT} Creates a config file at ${C_SKY}/etc/ssh/sshd_config.d/99-hardening.conf${C_END}${C_TEXT} to:
  - Change the listening port to ${C_SKY}47${C_END}${C_TEXT}.${C_END}
  - Disable root login (${C_SKY}PermitRootLogin no${C_END}${C_TEXT}).${C_END}
  - Disable password-based authentication (${C_SKY}PasswordAuthentication no${C_END}${C_TEXT}).${C_END}
- ${C_PEACH}${C_BOLD}Configure Firewall:${C_END}${C_TEXT} Uses ${C_GREEN}UFW${C_END}${C_TEXT} to:
  - Allow incoming traffic on the new SSH port (${C_SKY}47/tcp${C_END}${C_TEXT}).${C_END}
  - Deny traffic on the default SSH port (${C_SKY}22/tcp${C_END}${C_TEXT}).${C_END}
  - Enable the firewall with ${C_SKY}ufw --force enable${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Kernel Parameters:${C_END}${C_TEXT} Applies secure kernel runtime parameters by writing to
  ${C_SKY}/etc/sysctl.d/99-custom-hardening.conf${C_END}${C_TEXT} and running ${C_SKY}sysctl -p${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Proc Filesystem:${C_END}${C_TEXT} Hardens ${C_SKY}/proc${C_END}${C_TEXT} access by modifying the entry in ${C_SKY}/etc/fstab${C_END}
  ${C_TEXT}to include ${C_SKY}hidepid=2${C_END}${C_TEXT}, preventing users from seeing each other's processes.${C_END}
EOF
}

docs_configure_user() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Configuring User Environment${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Performs user-specific setup for the target user's environment.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Default Shell:${C_END}${C_TEXT} Changes the target user's default shell to ${C_GREEN}fish${C_END}${C_TEXT} using
  the ${C_SKY}chsh${C_END}${C_TEXT} command.${C_END}
- ${C_PEACH}${C_BOLD}NPM Configuration:${C_END}${C_TEXT} Configures ${C_GREEN}npm${C_END}${C_TEXT} to use a local directory for global
  packages at ${C_SKY}${USER_HOME}/.npm-global${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}XDG Configuration:${C_END}
  - ${C_TEXT}Runs ${C_SKY}xdg-user-dirs-update${C_END}${C_TEXT} to create standard user directories (Desktop,
    Documents, etc.).${C_END}
  - ${C_TEXT}Creates ${C_SKY}${USER_HOME}/.config/mimeapps.list${C_END}${C_TEXT} to set default applications
    for images, videos, text files, and web links.${C_END}
- ${C_PEACH}${C_BOLD}User Services:${C_END}${C_TEXT} Enables and starts user-level systemd services for:
  - Audio: ${C_SKY}pipewire.service${C_END}${C_TEXT}, ${C_SKY}pipewire-pulse.service${C_END}${C_TEXT}, ${C_SKY}wireplumber.service${C_END}
  - Desktop: ${C_SKY}hypridle.service${C_END}${C_TEXT}, ${C_SKY}hyprpaper.service${C_END}
EOF
}

docs_setup_editors() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Setting Up Text Editors${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Clones and sets up custom configurations for Neovim and Doom Emacs.${C_END}

${C_PEACH}${C_BOLD}Note:${C_END}
- ${C_TEXT}If existing configurations are found, they will be backed up with a timestamp
  (e.g., ${C_SKY}${USER_HOME}/.config/nvim.bak-YYYY-MM-DD_HH-MM${C_END}${C_TEXT}).${C_END}
- ${C_TEXT}This task will be skipped for an editor that is not installed.${C_END}

${C_PEACH}${C_BOLD}Neovim Actions:${C_END}
- ${C_TEXT}Clones the config from ${C_SKY}https://github.com/aahsnr-configs/nvim-config.git${C_END}${C_TEXT} into
  ${C_SKY}${USER_HOME}/.config/nvim${C_END}${C_TEXT}.${C_END}
- ${C_TEXT}Runs a headless ${C_SKY}nvim${C_END}${C_TEXT} command to automatically sync plugins with Lazy.nvim,
  update treesitter parsers, and install Mason tools.${C_END}

${C_PEACH}${C_BOLD}Doom Emacs Actions:${C_END}
- ${C_TEXT}Clones Doom Emacs from ${C_SKY}https://github.com/doomemacs/doomemacs${C_END}${C_TEXT} into
  ${C_SKY}${USER_HOME}/.config/emacs${C_END}${C_TEXT}.${C_END}
- ${C_TEXT}Clones a custom Doom config from ${C_SKY}https://github.com/aahsnr-configs/doom-config.git${C_END}
  ${C_TEXT}into ${C_SKY}${USER_HOME}/.config/doom${C_END}${C_TEXT}.${C_END}
- ${C_TEXT}Runs ${C_SKY}~/.config/emacs/bin/doom install${C_END}${C_TEXT} to complete the setup.
  ${C_YELLOW}This can take a very long time.${C_END}
EOF
}

docs_cleanup() {
  cat <<EOF
${C_BOLD}${C_ITALIC}${C_MAUVE}Performing System Cleanup${C_END}
${C_MAUVE}──────────────────────────────────────────────────────────────────${C_END}

${C_LAVENDER}Performs system maintenance tasks to free up disk space.${C_END}

${C_PEACH}${C_BOLD}Actions:${C_END}
- ${C_PEACH}${C_BOLD}Remove Orphaned Packages:${C_END}
  - ${C_TEXT}Uses ${C_SKY}paru -Qtdq${C_END}${C_TEXT} to find packages that were installed as dependencies
    but are no longer required by any installed package.${C_END}
  - ${C_TEXT}If orphans are found, they are removed with ${C_SKY}paru -Rns${C_END}${C_TEXT}.${C_END}
- ${C_PEACH}${C_BOLD}Clean Nix Store:${C_END}
  - ${C_PEACH}${C_BOLD}Condition:${C_END}${C_TEXT} This step only runs if Nix is installed.${C_END}
  - ${C_TEXT}Executes ${C_SKY}nix-collect-garbage -d${C_END}${C_TEXT} to delete old, unreferenced
    generations of packages from the Nix store.${C_END}
EOF
}

print_documentation() {
  cat <<EOF
${C_MAUVE}================================================================================${C_END}
${C_BOLD}${C_PEACH}Hyprland Arch Linux Setup Script - Full Documentation${C_END}
${C_MAUVE}================================================================================${C_END}

${C_TEXT}This script provides a comprehensive, automated, and idempotent method for
setting up a feature-rich Hyprland desktop environment on a fresh Arch Linux
installation. It is modular, allowing you to run the entire setup at once or
execute specific tasks individually using flags.${C_END}

EOF
  docs_pre_flight_checks
  echo -e "\n\n"
  docs_initial_setup
  echo -e "\n\n"
  docs_setup_extra_repos
  echo -e "\n\n"
  docs_setup_asus
  echo -e "\n\n"
  docs_install_packages
  echo -e "\n\n"
  docs_manual_installations
  echo -e "\n\n"
  docs_setup_dotfiles
  echo -e "\n\n"
  docs_setup_nix
  echo -e "\n\n"
  docs_configure_user
  echo -e "\n\n"
  docs_setup_editors
  echo -e "\n\n"
  docs_cleanup
  echo -e "\n\n"
  docs_setup_greetd
  echo -e "\n\n"
  docs_harden_system
}

print_usage() {
  echo -e "${C_BOLD}Usage: $0 [OPTIONS...]${C_END}"
  echo "Automates the setup of a complete Hyprland Environment on Arch Linux."
  echo ""
  echo -e "${C_BOLD}If no options are provided, the script will run all setup tasks interactively.${C_END}"
  echo ""
  echo -e "${C_MAUVE}Options:${C_END}"
  echo -e "  ${C_GREEN}--pre-flight-checks${C_END}       Verify system readiness before installation."
  echo -e "  ${C_GREEN}--initial-setup${C_END}           Perform initial system setup."
  echo -e "  ${C_GREEN}--setup-extra-repos${C_END}       Set up the CachyOS repository."
  echo -e "  ${C_GREEN}--setup-asus${C_END}              Run specific setup for ASUS laptops."
  echo -e "  ${C_GREEN}--install-packages${C_END}        Install packages from 'packages.txt'."
  echo -e "  ${C_GREEN}--manual-installs${C_END}         Perform manual installation of third-party software."
  echo -e "  ${C_GREEN}--setup-dotfiles${C_END}          Symlink user dotfiles from a local repository."
  echo -e "  ${C_GREEN}--setup-nix${C_END}               Install and configure Nix with Home-Manager."
  echo -e "  ${C_GREEN}--configure-user${C_END}          Set up the user's environment."
  echo -e "  ${C_GREEN}--setup-editors${C_END}           Set up Neovim and Doom Emacs configurations."
  echo -e "  ${C_GREEN}--cleanup${C_END}                 Remove orphaned packages from the system."
  echo -e "  ${C_GREEN}--setup-greetd${C_END}            Setup greetd and tuigreet as the login manager."
  echo -e "  ${C_GREEN}--harden-system${C_END}           Implement basic security enhancements."
  echo -e "  ${C_YELLOW}--debug${C_END}                   Enable verbose command tracing for debugging."
  echo -e "  ${C_SAPPHIRE}--help${C_END}                    Display this help message and exit."
  echo -e "  ${C_SAPPHIRE}--docs${C_END}                    Display the full embedded documentation and exit."
  echo ""
  echo -e "${C_BOLD}To view docs for a specific task, use: $0 --<task-name> --docs${C_END}"
  echo -e "  Example: $0 --setup-nix --docs"
}

# --- Utility Functions ---

command_exists() { command -v "$1" &>/dev/null; }
is_pkg_installed() { paru -Q "$1" &>/dev/null; }
run_as_user() { sudo -u "$TARGET_USER" bash -c "export HOME='$USER_HOME'; export USER='$TARGET_USER'; $*"; }

install_pkgs() {
  # Use --noconfirm for safe, non-interactive installation.
  paru -S --needed --skipreview --noconfirm "$@"
}

remove_pkgs() {
  # Use --noconfirm for safe, non-interactive removal.
  paru -Rns --noconfirm "$@"
}

prompt_to_run_task() {
  local task_name="$1"
  local docs_func="$2"

  echo -e "\n${C_MAUVE}================================================================================${C_END}"
  print_step "Next Task: $task_name"
  echo -e "${C_SAPPHIRE}This task will perform the following actions:${C_END}"
  "$docs_func" | sed 's/^/  /'
  echo

  while true; do
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Choose an action: Run (Enter), [S]kip, [A]bort? [Y/s/a]: ${C_END}")" -r choice
    case "$choice" in
    "" | [Yy]*) return 0 ;; # Run the task
    [Ss]*)
      print_info "Skipping task: $task_name"
      return 1
      ;; # Skip the task
    [Aa]*)
      print_error "User aborted the script."
      exit 1
      ;;
    *) print_warning "Invalid input. Please choose 's' or 'a', or press Enter to run." ;;
    esac
  done
}

# --- Task Functions ---

task_setup_aur_helper() {
  if command_exists paru; then
    print_success "AUR helper 'paru' is already installed."
    return
  fi

  print_step "Setting up AUR Helper (paru)"
  print_info "Installing 'git' and 'base-devel' to build the AUR helper..."
  sudo pacman -S --needed --noconfirm git base-devel

  local tmp_dir
  tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  sudo git clone https://aur.archlinux.org/paru-bin.git "$tmp_dir"
  sudo chown -R "$TARGET_USER:$TARGET_USER" "$tmp_dir"
  (
    cd "$tmp_dir"
    print_info "Building and installing 'paru-bin'..."
    run_as_user "makepkg -si --noconfirm"
  )
  print_success "'paru' has been installed successfully."
}

task_setup_limine_hook() {
  if is_pkg_installed "limine-mkinitcpio-hook"; then
    print_success "limine-mkinitcpio-hook is already installed."
    return
  fi

  print_step "Setting up Limine Bootloader Hook"
  print_info "Ensuring 'git' and 'base-devel' are present to build the hook..."
  sudo pacman -S --needed --noconfirm git base-devel

  local tmp_dir
  tmp_dir=$(mktemp -d)
  TEMP_FILES+=("$tmp_dir")
  sudo git clone https://aur.archlinux.org/limine-mkinitcpio-hook.git "$tmp_dir"
  sudo chown -R "$TARGET_USER:$TARGET_USER" "$tmp_dir"
  (
    cd "$tmp_dir"
    print_info "Building and installing 'limine-mkinitcpio-hook'..."
    run_as_user "makepkg -si --noconfirm"
  )
  print_success "'limine-mkinitcpio-hook' has been installed successfully."
}

pre_flight_checks() {
  print_step "Running Pre-flight Checks"

  if [ "$RUN_ALL" = true ]; then
    echo -e "\n${C_SAPPHIRE}This initial step performs critical safety and environment checks.${C_END}"
    docs_pre_flight_checks | sed 's/^/  /'
    echo
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Continue with pre-flight checks? (Press Enter for Yes) [Y/n]: ${C_END}")" -r choice
    if [[ -n "$choice" ]]; then
      print_error "Pre-flight checks declined. Aborting script."
      exit 1
    fi
  fi

  if [[ $EUID -eq 0 ]]; then
    print_error "This script must be run as a regular user, not root."
    exit 1
  fi
  if ! command_exists sudo; then
    print_error "'sudo' command not found."
    exit 1
  fi
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    print_error "No internet connection."
    exit 1
  fi

  task_setup_aur_helper
  task_setup_limine_hook

  local missing_pkgs=()
  for pkg in neovim wl-clipboard curl wget pciutils dmidecode xdg-user-dirs; do
    if ! is_pkg_installed "$pkg"; then missing_pkgs+=("$pkg"); fi
  done

  if ((${#missing_pkgs[@]} > 0)); then
    print_info "Installing missing script dependencies..."
    install_pkgs "${missing_pkgs[@]}"
  fi

  local required_files=("$PRECONFIG_DIR/packages.txt" "$PRECONFIG_DIR/makepkg.conf.txt" "$PRECONFIG_DIR/99-custom-env.sh.txt")
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      print_error "Required config file '$file' not found."
      exit 1
    fi
  done

  print_info "Priming sudo. You may be asked for your password now."
  sudo -v
  print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

task_initial_setup() {
  print_step "Performing Initial System Setup"

  print_info "Copying custom environment variables to /etc/profile.d/..."
  sudo cp "$PRECONFIG_DIR/99-custom-env.sh.txt" "/etc/profile.d/99-custom-env.sh"
  sudo chmod +x "/etc/profile.d/99-custom-env.sh"
  print_success "Custom environment variables installed."

  print_info "Modifying /etc/pacman.conf..."
  sudo sed -i 's/^#\(Color\)/\1/' /etc/pacman.conf
  sudo sed -i '/^#\(Color\)/a ILoveCandy' /etc/pacman.conf
  sudo sed -i 's/^#\(VerbosePkgLists\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(DisableDownloadTimeout\)/\1/' /etc/pacman.conf
  sudo sed -i 's/^#\(ParallelDownloads\).*/\1 = 10/' /etc/pacman.conf
  if ! grep -q "^DownloadUser" /etc/pacman.conf; then
    sudo sed -i '/^\[options\]/a DownloadUser = alpm' /etc/pacman.conf
  else
    sudo sed -i 's/^DownloadUser.*/DownloadUser = alpm/' /etc/pacman.conf
  fi
  print_success "pacman.conf modifications applied."

  print_info "Overwriting /etc/makepkg.conf..."
  sudo cp "$PRECONFIG_DIR/makepkg.conf.txt" "/etc/makepkg.conf"
  print_success "Successfully updated /etc/makepkg.conf."

  print_info "Setting up reflector to manage pacman mirrors..."
  install_pkgs reflector
  sudo systemctl enable --now reflector.service reflector.timer
  print_info "Performing initial mirror list update for BD, IN, SG..."
  sudo reflector --verbose -l 25 --country BD,IN,SG --sort rate --save /etc/pacman.d/mirrorlist
  print_success "Reflector setup complete and mirrorlist updated."

  local verified=false
  while [ "$verified" = false ]; do
    print_step "Verify Configuration Files"
    echo -e "${C_MAUVE}Current /etc/pacman.conf:${C_END}"
    cat /etc/pacman.conf
    echo -e "\n${C_MAUVE}Current /etc/makepkg.conf:${C_END}"
    cat /etc/makepkg.conf

    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Are these configurations okay? (Enter=Yes, e=Edit, other=Abort) [Y/n/edit]: ${C_END}")" -r choice
    case "$choice" in
    "")
      print_success "Configuration approved."
      verified=true
      ;;
    [Ee]*)
      read -p "$(echo -e "${C_SKY}${I_PROMPT} Which file to edit? [p(acman)/m(akepkg)]: ${C_END}")" -r edit_choice
      case "$edit_choice" in
      [Pp]*) sudo nvim /etc/pacman.conf ;;
      [Mm]*) sudo nvim /etc/makepkg.conf ;;
      *) print_warning "Invalid selection." ;;
      esac
      ;;
    *)
      print_error "Configuration rejected. Aborting script."
      exit 1
      ;;
    esac
  done
}

task_setup_extra_repos() {
  print_step "Setting Up CachyOS Repository"

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
      # shellcheck disable=SC2024
      sudo ./cachyos-repo.sh </dev/tty
    )
    print_success "CachyOS repository setup finished."
  fi

  print_info "Synchronizing databases and upgrading system..."
  paru -Syu --skipreview --noconfirm
}

task_setup_asus() {
  print_step "Setting up for ASUS Laptops (using g14 Repository)"
  if ! sudo dmidecode -s system-manufacturer | grep -qi "ASUS"; then
    print_warning "ASUS hardware not detected. Skipping."
    return
  fi

  local g14_key_id="8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"
  print_info "Configuring GPG key for the g14 repository..."
  if ! sudo pacman-key --list-keys | grep -q "$g14_key_id"; then
    sudo pacman-key --recv-keys "$g14_key_id"
    sudo pacman-key --lsign-key "$g14_key_id"
  fi
  print_success "GPG key setup complete."

  print_info "Configuring the [g14] repository in /etc/pacman.conf..."
  if ! grep -q "\[g14\]" /etc/pacman.conf; then
    echo -e "\n[g14]\nServer = https://arch.asus-linux.org" | sudo tee -a /etc/pacman.conf >/dev/null
    paru -Syu --skipreview --noconfirm
  fi
  print_success "The [g14] repository is configured."

  print_info "Installing ASUS-specific packages..."
  install_pkgs asusctl power-profiles-daemon supergfxctl switcheroo-control rog-control-center

  print_info "Enabling required system services for ASUS hardware..."
  sudo systemctl daemon-reload
  sudo systemctl enable --now power-profiles-daemon.service
  sudo systemctl enable --now supergfxd.service
  sudo systemctl enable --now switcheroo-control.service
  print_success "ASUS services enabled."
}

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
  print_success "greetd configuration written."

  print_info "Checking for and removing SDDM..."
  if is_pkg_installed sddm; then
    if systemctl is-enabled --quiet sddm.service &>/dev/null; then
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

task_install_packages() {
  print_step "Installing System Packages from File"
  mapfile -t packages_to_install < <(grep -vE '^\s*#|^\s*$' "$PRECONFIG_DIR/packages.txt")
  if ((${#packages_to_install[@]} == 0)); then
    print_warning "No packages found in 'packages.txt'. Skipping."
    return
  fi
  install_pkgs "${packages_to_install[@]}"
}

task_setup_dotfiles() {
  print_step "Setting up User Dotfiles using Stow"

  local dotfiles_dir="$SCRIPT_DIR/dotfiles"
  if [ ! -d "$dotfiles_dir" ]; then
    print_warning "Dotfiles directory not found at '$dotfiles_dir'. Skipping."
    return
  fi

  if ! command_exists stow; then
    print_info "The 'stow' package is required but not installed. Installing it now..."
    install_pkgs stow
  fi

  print_info "Changing directory to '$dotfiles_dir'..."
  cd "$dotfiles_dir"

  print_info "Executing 'stow . -t $USER_HOME' to symlink dotfiles..."
  run_as_user "stow . -t '$USER_HOME'"
  print_success "Dotfiles have been successfully stowed."

  # Return to the original directory
  cd "$SCRIPT_DIR"
}

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
  run_as_user "mkdir -p '$nix_config_dir'"
  run_as_user "echo -e 'experimental-features = nix-command flakes\nmax-jobs = 4' > '$nix_config_file'"

  local nix_cmd_prefix=". '$nix_daemon_profile';"

  print_info "Initializing Home-Manager..."
  if ! (run_as_user "[ -d '$USER_HOME/.config/home-manager' ]" && command_exists home-manager); then
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
  fi
  print_success "Nix, Home-Manager, and Flakes setup complete."
}

task_manual_installations() {
  print_step "Performing Manual Installations"

  if command_exists pia-client; then
    print_success "Private Internet Access is already installed."
  else
    print_info "Installing Private Internet Access (PIA) VPN."
    local pia_url="https://installers.privateinternetaccess.com/download/pia-linux-3.6.2-08398.run"
    local pia_installer
    pia_installer=$(mktemp --suffix=.run)
    TEMP_FILES+=("$pia_installer")
    print_info "Downloading PIA installer..."
    wget -O "$pia_installer" "$pia_url"
    chmod +x "$pia_installer"
    print_warning "The PIA installer will now launch."
    bash "$pia_installer" </dev/tty
    print_success "PIA VPN installation process finished."
  fi
}

# -------------------------MODIFIED FUNCTION START-------------------------
task_harden_system() {
  print_step "Applying System Security Hardening"

  print_info "Installing security packages..."
  install_pkgs apparmor audit arch-audit openssh procps-ng rng-tools \
    sysstat haveged lynis-git libpwquality bleachbit ufw

  print_info "Enabling and starting core security services..."
  local system_services=(auditd apparmor haveged rngd sshd)
  for service in "${system_services[@]}"; do
    if sudo systemctl enable --now "${service}.service"; then
      print_success "Enabled and started '$service' service."
    else
      print_error "Failed to enable and start '$service' service."
    fi
  done

  print_info "Configuring audit framework..."
  if ! grep -q '^audit:' /etc/group; then
    sudo groupadd -r audit
    print_success "Created 'audit' group."
  fi
  if ! getent group audit | grep -qw "$TARGET_USER"; then
    sudo gpasswd -a "$TARGET_USER" audit
    print_success "Added user '$TARGET_USER' to 'audit' group."
  fi
  if ! grep -q "^\s*log_group = audit" /etc/audit/auditd.conf; then
    echo "log_group = audit" | sudo tee -a /etc/audit/auditd.conf >/dev/null
    sudo systemctl restart auditd.service
    print_success "Audit log group configured and service restarted."
  else
    print_success "Audit configuration already applied."
  fi

  print_info "Hardening OpenSSH server configuration..."
  sudo mkdir -p /etc/ssh/sshd_config.d
  # Hardening based on modern security best practices.
  cat <<'EOF' | sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null
# Port and Logging
Port 47
LogLevel VERBOSE

# Authentication
# Disallow root login and password-based authentication. Only public key is allowed.
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
PermitEmptyPasswords no
MaxAuthTries 3

# Security & Forwarding
# Disable features that are common attack vectors if not needed.
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
TCPKeepAlive no

# Performance and Session Management
UseDNS no
PrintMotd no
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2

# Modern, secure cryptographic algorithms
# This ensures that weak/outdated ciphers are not used.
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
EOF
  sudo systemctl reload sshd
  print_success "SSH hardening rules applied and configuration reloaded."

  if command_exists ufw; then
    print_info "Configuring UFW firewall..."
    sudo ufw allow 47/tcp comment 'Custom SSH Port'
    sudo ufw deny 22/tcp comment 'Default SSH Port'
    sudo ufw --force enable
    print_success "UFW enabled and configured for SSH on port 47."
  fi

  print_info "Applying custom sysctl kernel settings..."
  local sysctl_file="/etc/sysctl.d/99-custom-hardening.conf"
  cat <<EOF | sudo tee "$sysctl_file" >/dev/null
kernel.kptr_restrict = 2
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 2
net.ipv4.conf.all.rp_filter = 1
EOF
  sudo sysctl -p "$sysctl_file"
  print_success "Runtime kernel parameters have been applied from '$sysctl_file'."

  print_info "Hardening /proc filesystem with hidepid..."
  if ! grep "^\s*proc\s*/proc" /etc/fstab | grep -q "hidepid=2"; then
    # This sed command is complex; it finds the line for /proc and replaces the whole line
    # to ensure options are set correctly without duplication.
    sudo sed -i 's|^\s*proc\s\+/proc\s\+proc\s\+.*|proc /proc proc nosuid,nodev,noexec,hidepid=2 0 0|' /etc/fstab
    sudo mount -o remount /proc
    print_success "/etc/fstab updated and /proc remounted with hidepid=2."
  else
    print_success "/proc entry in fstab is already hardened."
  fi
}
# -------------------------MODIFIED FUNCTION END---------------------------

task_helper_setup_xdg() {
  print_step "Configuring XDG Base Directories and MIME Associations"
  run_as_user "mkdir -p '$USER_HOME/.config'"

  print_info "Setting up XDG user directories..."
  run_as_user "xdg-user-dirs-update"
  print_success "XDG user directories configured."

  print_info "Setting up default MIME type applications..."
  run_as_user "
    cat <<'EOF' > '$USER_HOME/.config/mimeapps.list'
[Default Applications]
image/png=imv.desktop
image/jpeg=imv.desktop
video/mp4=mpv.desktop
text/html=zen-browser.desktop
x-scheme-handler/http=zen-browser.desktop
x-scheme-handler/https=zen-browser.desktop
text/plain=codium.desktop
application/pdf=org.gnome.Papers.desktop
inode/directory=thunar.desktop
EOF
"
  print_success "Default MIME applications configured."
}

task_configure_user() {
  print_step "Configuring User Environment for $TARGET_USER"

  print_info "Setting default shell for '$TARGET_USER' to fish..."
  if chsh -s "$(which fish)" "$TARGET_USER" </dev/tty; then
    print_success "Default shell set to fish."
  else
    print_error "Failed to set fish as the default shell."
  fi

  print_info "Configuring NPM global directory..."
  run_as_user "mkdir -p '$USER_HOME/.npm-global' && npm config set prefix '$USER_HOME/.npm-global'"

  task_helper_setup_xdg

  print_step "Setting up Hyprland Desktop Services"
  local user_services=("pipewire" "pipewire-pulse" "wireplumber" "foot")
  for service in "${user_services[@]}"; do
    if run_as_user "systemctl --user enable --now '$service'"; then
      print_success "Enabled user service '$service'."
    else
      print_warning "Could not enable user service '$service'."
    fi
  done
}

task_setup_editors() {
  print_step "Setting up Text Editors (Neovim & Doom Emacs)"

  if command_exists nvim; then
    print_info "Setting up Neovim configuration..."
    if run_as_user "[ -d \"$USER_HOME/.config/nvim\" ]"; then
      print_warning "Neovim config directory already exists. Backing it up."
      run_as_user "mv -f '$USER_HOME/.config/nvim' '$USER_HOME/.config/nvim.bak-$(date +%F_%H-%M)'"
    fi
    run_as_user "git clone https://github.com/aahsnr-configs/nvim-config.git '$USER_HOME/.config/nvim'"
    print_info "Running Neovim headless setup for plugins and tools..."
    run_as_user "nvim --headless \"+Lazy! sync\" +TSUpdateSync \"+autocmd User MasonToolsUpdateCompleted quitall\" +MasonToolsInstall"
    print_success "Neovim setup complete."
  else
    print_warning "Neovim ('nvim') is not installed. Skipping its setup."
  fi

  if command_exists emacs; then
    print_info "Setting up Doom Emacs configuration..."
    if run_as_user "[ -d \"$USER_HOME/.config/emacs\" ]"; then
      print_warning "Emacs config directory already exists. Backing it up."
      run_as_user "mv -f '$USER_HOME/.config/emacs' '$USER_HOME/.config/emacs.bak-$(date +%F_%H-%M)'"
    fi
    if run_as_user "[ -d \"$USER_HOME/.config/doom\" ]"; then
      print_warning "Doom config directory already exists. Backing it up."
      run_as_user "mv -f '$USER_HOME/.config/doom' '$USER_HOME/.config/doom.bak-$(date +%F_%H-%M)'"
    fi

    run_as_user "git clone --depth 1 https://github.com/doomemacs/doomemacs '$USER_HOME'/.config/emacs"
    run_as_user "git clone https://github.com/aahsnr-configs/doom-config.git '$USER_HOME'/.config/doom -b lsp-mode"
    print_info "Running 'doom install'. This may take a significant amount of time..."
    run_as_user "'$USER_HOME'/.config/emacs/bin/doom install"
    print_success "Doom Emacs setup complete."
  else
    print_warning "Emacs ('emacs') is not installed. Skipping its setup."
  fi
}

task_cleanup() {
  print_step "Cleaning Up System"

  print_info "Checking for orphaned packages..."
  if paru -Qtdq >/dev/null; then
    print_warning "The following orphaned packages will be removed:"
    paru -Qtd | awk '{print "  - " $1 " " $2}'
    paru -Rns --noconfirm "$(paru -Qtdq)"
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

# --- Logging Setup ---
setup_logging() {
  mkdir -p "$LOGS_DIR"
  LOG_FILE="$LOGS_DIR/setup-log-$(date +'%b.%d.%Y_%I-%M-%p').log"
  # Redirect stdout and stderr to a log file and the console.
  # This should only be called when a task is actually going to be run.
  exec &> >(tee -a "$LOG_FILE")
  print_info "$I_LOG Logging output to: $LOG_FILE"
}

# --- Main Execution Logic ---
main() {
  local TASKS_TO_RUN=()
  if (($# > 0)); then
    RUN_ALL=false
    while (("$#")); do
      case "$1" in
      --pre-flight-checks)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_pre_flight_checks >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("pre_flight_checks")
        shift
        ;;
      --initial-setup)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_initial_setup >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("initial_setup")
        shift
        ;;
      --setup-extra-repos)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_extra_repos >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_extra_repos")
        shift
        ;;
      --setup-asus)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_asus >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_asus")
        shift
        ;;
      --install-packages)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_install_packages >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("install_packages")
        shift
        ;;
      --manual-installs)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_manual_installations >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("manual_installations")
        shift
        ;;
      --setup-dotfiles)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_dotfiles >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_dotfiles")
        shift
        ;;
      --setup-nix)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_nix >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_nix")
        shift
        ;;
      --configure-user)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_configure_user >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("configure_user")
        shift
        ;;
      --setup-editors)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_editors >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_editors")
        shift
        ;;
      --cleanup)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_cleanup >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("cleanup")
        shift
        ;;
      --setup-greetd)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_setup_greetd >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("setup_greetd")
        shift
        ;;
      --harden-system)
        if [[ "${2:-}" == "--docs" ]]; then
          docs_harden_system >/dev/tty
          exit 0
        fi
        TASKS_TO_RUN+=("harden_system")
        shift
        ;;
      --debug)
        DEBUG_MODE=true
        shift
        ;;
      --help)
        print_usage >/dev/tty
        exit 0
        ;;
      --docs)
        print_documentation >/dev/tty
        exit 0
        ;;
      *)
        print_error "Unknown flag: $1"
        print_usage >/dev/tty
        exit 1
        ;;
      esac
    done
  fi

  # --- Execution Phase ---
  # Only proceed to run tasks if specific tasks were selected or if in full-run mode.
  if [ ${#TASKS_TO_RUN[@]} -gt 0 ] || [ "$RUN_ALL" = true ]; then
    setup_logging # Initialize logging only when tasks are about to run.
  else
    # If no tasks and not in full mode, it means only doc flags were processed and exited,
    # or invalid flags were passed. The script can exit cleanly.
    exit 0
  fi

  if [ "$DEBUG_MODE" = true ]; then
    print_debug "Debug mode enabled. Activating verbose command tracing (set -x)."
    set -x
  fi

  # If individual tasks were specified, run them.
  if [ ${#TASKS_TO_RUN[@]} -gt 0 ]; then
    # Pre-flight checks are mandatory before any other task.
    # Run it unless it was the only task requested.
    if [[ ! " ${TASKS_TO_RUN[*]} " =~ " pre_flight_checks " ]] || [ ${#TASKS_TO_RUN[@]} -gt 1 ]; then
      pre_flight_checks
    fi
    for task in "${TASKS_TO_RUN[@]}"; do
      # Dynamically call the task function, e.g., "initial_setup" becomes "task_initial_setup"
      if [[ "$task" == "pre_flight_checks" ]]; then
        pre_flight_checks # Already idempotent
      else
        "task_$task"
      fi
    done
  fi

  if [ "$RUN_ALL" = true ]; then
    pre_flight_checks
    print_step "Starting Full Interactive Installation"
    echo "This script will guide you through a full setup of a Hyprland desktop."
    echo "For each step, press Enter to run it, or 's' to skip."
    read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? (Press Enter for Yes) [Y/n]: ${C_END}")" -r choice
    if [[ -n "$choice" ]]; then
      print_info "Aborting."
      exit 0
    fi

    if prompt_to_run_task "Initial System Setup" "docs_initial_setup"; then task_initial_setup; fi
    if prompt_to_run_task "Setup CachyOS Repository" "docs_setup_extra_repos"; then task_setup_extra_repos; fi

    if sudo dmidecode -s system-manufacturer | grep -qi "ASUS"; then
      read -p "$(echo -e "${C_SKY}${I_PROMPT} ASUS hardware detected. Install specific tools? (Enter=Yes) [Y/n]: ${C_END}")" -r asus_choice
      if [[ -z "$asus_choice" ]]; then task_setup_asus; fi
    fi

    if prompt_to_run_task "Install Packages from File" "docs_install_packages"; then task_install_packages; fi
    if prompt_to_run_task "Perform Manual Installations" "docs_manual_installations"; then task_manual_installations; fi
    if prompt_to_run_task "Setup User Dotfiles" "docs_setup_dotfiles"; then task_setup_dotfiles; fi
    if prompt_to_run_task "Setup Nix & Home-Manager" "docs_setup_nix"; then task_setup_nix; fi
    if prompt_to_run_task "Configure User Environment" "docs_configure_user"; then task_configure_user; fi
    if prompt_to_run_task "Setup Text Editors" "docs_setup_editors"; then task_setup_editors; fi
    if prompt_to_run_task "Perform System Cleanup" "docs_cleanup"; then task_cleanup; fi
    if prompt_to_run_task "Setup Greetd Login Manager" "docs_setup_greetd"; then task_setup_greetd; fi
    if prompt_to_run_task "Harden System Security" "docs_harden_system"; then task_harden_system; fi
  fi

  set +x
  print_step "$I_FINISH Run Complete!"
  print_success "All requested tasks finished successfully."
  print_warning "A final reboot is highly recommended to apply all changes."
}

# --- Script Entry Point ---
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Re-executing with bash..." >&2
  exec bash "$0" "$@"
  exit 1
fi

main "$@"
