Of course. My apologies for the previous formatting issues. I have meticulously reviewed the structure and rewritten the entire output to ensure it is clean, correctly formatted, and highly readable in Markdown.

I've used consistent headings, proper code blocks with language identifiers for syntax highlighting, and clear instructions for each file.

# Complete Fedora Hyprland Setup Script

This setup consists of five files that work together to automate the installation and configuration of a complete Fedora Hyprland environment.

**Instructions:**

1.  Create a new directory for this project.
2.  Save each of the five files below with the specified names inside that new directory.
3.  Make the `setup.sh` script executable by running: `chmod +x setup.sh`
4.  Run the script with `./setup.sh` or with specific flags like `./setup.sh --install-packages`.

---

### 1. DNF Configuration (`dnf.conf.txt`)

**(New File)** This file contains the optimized DNF configuration settings.

**Save the following content to a file named `dnf.conf.txt`:**

```ini
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
```

---

### 2. Custom Environment Script (`99-custom-env.sh.txt`)

**(New File)** This file defines system-wide environment variables for all users.

**Save the following content to a file named `99-custom-env.sh.txt`:**

```sh
#!/bin/sh
export EDITOR=${EDITOR:-/usr/bin/nano}
export PAGER=${PAGER:-/usr/bin/less}
export BROWSER="firefox"
export PATH="$PATH:$HOME/.local/bin:$HOME/.npm-global/bin"
```

---

### 3. DNF Group List (`groups.txt`)

This file specifies the DNF package groups to install, providing a base for development.

**Save the following content to a file named `groups.txt`:**

````ini
# --------------------------------------------------------------------------
# Fedora DNF Group List
# --------------------------------------------------------------------------
# This file should contain the DNF Group ID for each group to be installed.
# Use 'dnf group list ids' to find available group IDs.
# --------------------------------------------------------------------------
development-tools```

---

### 4. DNF Package List (`packages.txt`)

This file is a clean, alphabetized list of all the individual packages required for the desktop environment.

**Save the following content to the `packages.txt` file:**
````

adw-gtk3-theme
appstream-util
axel
bluedevil
bluez
bluez-cups
brightnessctl
cava
clang
cliphist
cmake
coreutils
curl
darkly
ddcutil
ffmpeg
file-devel
fish
fontconfig
fuzzel
gdouros-symbola-fonts
geoclue2
gjs
gjs-devel
gnome-bluetooth
gnome-themes-extra
go
gobject-introspection
gobject-introspection-devel
grim
grimblast
gtk-layer-shell-devel
gtk3
gtk4-devel
gtksourceview3
gtksourceview3-devel
gtksourceviewmm3-devel
hypridle
hyprland
hyprland-plugins
hyprlang-devel
hyprlock
hyprpicker
hyprshot
hyprsunset
hyprutils
hyprwayland-scanner
jq
kcmshell6
kde-material-you-colors
kdialog
kitty
kvantum
kvantum-qt5
lato-fonts
libadwaita-devel
libdbusmenu
libdbusmenu-gtk3-devel
libdrm-devel
libgbm-devel
libportal
libsass
libsass-devel
libsoup-devel
libsoup3-devel
libwebp-devel
libxdp
libxdp-devel
make
mate-polkit
matugen
meson
mpvpaper
npm
pam-devel
pavucontrol
plasma-desktop
plasma-nm
plasma-systemmonitor
playerctl
pugixml
pulseaudio-libs-devel
python-opencv
python3
python3-devel
python3.12
python3.12-devel
qalc
qt5-qtwayland
qt5ct
qt6-qtwayland
qt6ct
quickshell-git
ripgrep
rsync
scdoc
slurp
swappy
tesseract
translate-shell
typescript
unzip
upower
uv
webp-pixbuf-loader
wget
wf-recorder
wireplumber
wl-clipboard
wlogout
wtype
xdg-desktop-portal
xdg-desktop-portal-hyprland
xdg-desktop-portal-kde
xdg-user-dirs
xdg-utils
xrandr
yad
ydotool

````

---

### 5. The Complete Bash Script (`setup.sh`)

This is the main orchestrator script that reads the four text files and performs all the setup tasks.

**Save the following complete and rewritten script as `setup.sh`:**
```bash
#!/usr/bin/env bash

# This script automates the setup of a complete Fedora Hyprland Environment.
# It is a robust, idempotent, and modular script that reads its package and
# group lists from external '.txt' files for easy management.
#
# It should be run as a regular user with sudo privileges.
# Use the --debug flag to enable verbose command tracing.

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
        rm -f "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT ERR INT TERM

# --- User Interface: Colors and Icons ---
readonly C_HEADER='\033[95m'; readonly C_BLUE='\033[94m'; readonly C_GREEN='\033[92m'
readonly C_YELLOW='\033[93m'; readonly C_RED='\033[91m'; readonly C_BOLD='\033[1m'
readonly C_CYAN='\033[96m'; readonly C_END='\033[0m'

readonly I_STEP="⚙️"; readonly I_INFO="ℹ️"; readonly I_SUCCESS="✅"; readonly I_WARN="⚠️"
readonly I_ERROR="❌"; readonly I_PROMPT="❓"; readonly I_FINISH="🎉"; readonly I_DEBUG="🐞"

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
readonly HM_CONFIG_DIR="$USER_HOME/.config/home-manager"
readonly HM_REPO_URL="https://github.com/aahsnr-configs/home-manager.git"
DEBUG_MODE=false
NIX_SOURCED=false

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
    echo -e "$content" > "$tmp_file"

    if [ -f "$path" ] && diff -q "$path" "$tmp_file" &>/dev/null; then
        print_success "File '$path' is already up to date."
        return 0
    fi

    sudo mkdir -p "$(dirname "$path")"
    sudo mv "$tmp_file" "$path"
    sudo chown "$owner" "$path"
    print_success "Wrote configuration to '$path'."
}

# Sources the Nix environment profile to make its commands available.
source_nix_env() {
    if [ "$NIX_SOURCED" = true ]; then
        print_debug "Nix environment already sourced."
        return
    fi
    local nix_profile_script="/etc/profile.d/nix-determinate-installer.sh"
    if [ -f "$nix_profile_script" ]; then
        print_info "Sourcing Nix environment profile..."
        # We need to source this into the current script's shell
        # shellcheck source=/dev/null
        . "$nix_profile_script"
        NIX_SOURCED=true
        print_debug "Nix environment sourced successfully."
    else
        print_debug "Nix profile script not found at '$nix_profile_script'."
    fi
}

# --- Task Functions ---

# Verifies that the script is run in a valid environment.
pre_flight_checks() {
    print_step "Running Pre-flight Checks"
    print_debug "Effective UID: $EUID. Target user: $TARGET_USER."
    if [[ $EUID -eq 0 ]]; then print_error "This script must be run as a regular user, not root. Aborting."; exit 1; fi
    if ! command_exists sudo; then print_error "'sudo' command not found. Aborting."; exit 1; fi
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then print_error "No internet connection. Aborting."; exit 1; fi
    print_success "Checks passed. Configuring system for user: $TARGET_USER"
}

# Copies initial system configuration files from local '.txt' files.
task_initial_files_setup() {
    print_step "Applying Initial System Configurations"

    # DNF Configuration
    if [[ ! -f "dnf.conf.txt" ]]; then print_error "Configuration file 'dnf.conf.txt' not found."; exit 1; fi
    local dnf_conf_content
    dnf_conf_content=$(< dnf.conf.txt)
    write_file_idempotent "/etc/dnf/dnf.conf" "$dnf_conf_content"

    # Custom Environment Script
    if [[ ! -f "99-custom-env.sh.txt" ]]; then print_error "Configuration file '99-custom-env.sh.txt' not found."; exit 1; fi
    local env_sh_content
    env_sh_content=$(< 99-custom-env.sh.txt)
    write_file_idempotent "/etc/profile.d/99-custom-env.sh" "$env_sh_content"

    print_info "Setting execute permissions on custom environment script."
    sudo chmod +x "/etc/profile.d/99-custom-env.sh"
}

# Configures DNF and enables third-party repositories.
task_setup_repos() {
    print_step "Setting up System Repositories"

    local copr_repos=("solopasha/hyprland" "errornointernet/quickshell" "deltacopy/darkly")
    for repo in "${copr_repos[@]}"; do
        local repo_filename="_copr_${repo//\//-}.repo"
        if [ -f "/etc/yum.repos.d/$repo_filename" ]; then
            print_success "COPR repository '$repo' is already enabled."
        else
            print_info "Enabling COPR repository: $repo"
            sudo dnf copr enable -y "$repo"
        fi
    done

    for repo_type in free nonfree; do
        if ! is_pkg_installed "rpmfusion-${repo_type}-release"; then
            print_info "Installing RPM Fusion $repo_type repository."
            sudo dnf install -y "https://mirrors.rpmfusion.org/${repo_type}/fedora/rpmfusion-${repo_type}-release-$(rpm -E %fedora).noarch.rpm"
        else
            print_success "RPM Fusion $repo_type is already installed."
        fi
    done
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

    if (( ${#group_ids[@]} == 0 )); then
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

    if (( ${#packages_to_install[@]} == 0 )); then
        print_warning "No packages found in '$package_file'. Skipping installation."
        return
    fi

    print_debug "Final list of packages to install: ${packages_to_install[*]}"
    print_info "Installing ${#packages_to_install[@]} DNF packages. This may take a while..."
    sudo dnf install -y "${packages_to_install[@]}"
}

# Applies specific configurations for NVIDIA hardware.
task_configure_hardware() {
    print_step "Applying Hardware Configurations"
    if is_pkg_installed "akmod-nvidia"; then
        print_info "NVIDIA drivers detected. Applying configurations."
        local services=("nvidia-suspend.service" "nvidia-resume.service" "nvidia-hibernate.service")
        sudo systemctl enable "${services[@]}"
        sudo systemctl mask nvidia-fallback.service
        print_success "NVIDIA power management services enabled."
        print_warning "A reboot is required to build and load new NVIDIA kernel modules."
    else
        print_info "No NVIDIA drivers (akmod-nvidia) found. Skipping hardware configuration."
    fi
}

# Applies system-wide security hardening configurations.
task_harden_system() {
    print_step "Applying System Security Hardening"
    write_file_idempotent "/etc/security/limits.d/99-custom-limits.conf" '# Custom security limits\n* soft nofile 65536\n* hard nofile 1048576'
    local banner_content="--- WARNING ---\nThis system is for authorized use only. Activity may be monitored.\n"
    write_file_idempotent "/etc/issue" "$banner_content"
    write_file_idempotent "/etc/issue.net" "$banner_content"
    local sshd_content="Include /etc/ssh/sshd_config.d/*.conf\nPermitRootLogin no\nPasswordAuthentication no\nPubkeyAuthentication yes\nChallengeResponseAuthentication no\nUsePAM yes\nX11Forwarding no\nPrintMotd no\nAcceptEnv LANG LC_*\nSubsystem sftp /usr/libexec/openssh/sftp-server\nMaxAuthTries 3"
    write_file_idempotent "/etc/ssh/sshd_config.d/99-hardened.conf" "$sshd_content"
}

# Sets up the user's shell, dotfiles, and application configs.
task_configure_user() {
    print_step "Configuring User Environment for $TARGET_USER"

    if [ -d "$DOTFILES_DIR" ]; then
        print_success "Dotfiles directory already exists."
    else
        print_info "Cloning Hyprland dotfiles..."
        run_as_user git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
    fi

    print_info "Setting Zsh as the default shell."
    sudo chsh -s /usr/bin/zsh "$TARGET_USER"

    print_info "Configuring global Git settings."
    run_as_user git config --global user.name "aahsnr"
    run_as_user git config --global user.email "ahsanur041@proton.me"
    run_as_user git config --global credential.helper "/usr/libexec/git-core/git-credential-libsecret"

    print_info "Configuring NPM global directory."
    run_as_user mkdir -p "$USER_HOME/.npm-global"
    run_as_user npm config set prefix "$USER_HOME/.npm-global"
}

# Installs Nix, sets up Home Manager, and applies the user's custom configuration.
task_setup_nix() {
    print_step "Setting up Nix and Home Manager"

    if ! command_exists curl || ! command_exists git; then
        print_warning "curl and git are required for Nix setup. Installing them now."
        sudo dnf install -y curl git
    fi

    if command_exists nix; then
        print_success "Nix is already installed. Skipping installation."
    else
        print_info "Installing Nix using the Determinate Systems installer..."
        run_as_user "curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate"
        print_success "Nix installation complete."
    fi

    source_nix_env
    if ! command_exists nix; then
        print_error "Failed to find 'nix' command after installation and sourcing. Aborting Nix setup."
        return 1
    fi

    print_info "Initializing Home Manager..."
    run_as_user "nix run home-manager/master -- init --switch --extra-experimental-features 'nix-command flakes'"

    if [ -d "$HM_CONFIG_DIR" ]; then
        print_info "Removing temporary Home Manager configuration."
        run_as_user "rm -rf '$HM_CONFIG_DIR'"
    fi

    print_info "Cloning custom Home Manager configuration from repository..."
    run_as_user "git clone '$HM_REPO_URL' '$HM_CONFIG_DIR'"

    print_info "Applying new Home Manager configuration..."
    run_as_user "home-manager switch"

    print_success "Nix and Home Manager setup complete."
}

# Enables systemd services required for the Hyprland desktop.
task_setup_hyprland() {
    print_step "Setting up Hyprland Desktop Services"

    if [ ! -d "$DOTFILES_DIR" ]; then print_error "Dotfiles not found. Run --configure-user first."; return 1; fi

    run_as_user mkdir -p "$USER_HOME/.config/systemd/user"
    run_as_user systemctl --user daemon-reload

    print_info "Enabling core desktop services for the user."
    local user_services=("pipewire.service" "pipewire-pulse.service" "wireplumber.service" "hypridle.service" "hyprpaper.service")

    local available_services
    available_services=$(run_as_user systemctl --user list-unit-files --no-legend)

    for service in "${user_services[@]}"; do
        if echo "$available_services" | grep -q "^${service}"; then
            print_info "Enabling user service: $service"
            run_as_user systemctl --user enable --now "$service"
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
declare -A tasks_to_run
declare run_all

# Parses command-line arguments to determine which tasks to run.
parse_args_and_plan_tasks() {
    run_all=true
    local flags_provided=false
    tasks_to_run=(
        [initial-setup]=false [setup-repos]=false [install-groups]=false
        [install-packages]=false [harden-system]=false [configure-hardware]=false
        [configure-user]=false [setup-nix]=false [setup-hyprland]=false [cleanup]=false
    )

    local task_args=()
    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG_MODE=true
        else
            task_args+=("$arg")
        fi
    done

    for arg in "${task_args[@]}"; do
        flags_provided=true
        local flag_name="${arg#--}"
        if [[ -v "tasks_to_run[$flag_name]" ]]; then
            tasks_to_run[$flag_name]=true
        else
            print_error "Unknown flag: $arg"
            echo "Usage: $0 [--initial-setup] [...] [--setup-nix] [--debug]"
            exit 1
        fi
    done

    if [ "$flags_provided" = true ]; then
        run_all=false
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

    if [ "$run_all" = true ]; then
        print_step "Full Installation Plan Summary"
        echo -e """
This script will perform a full, opinionated setup of a Fedora Hyprland desktop.
It will configure the system, install packages, set up Nix/Home-Manager,
harden security, and configure the user environment.
${C_YELLOW}You will be prompted for your password for 'sudo' commands.${C_END}
"""
        read -p "$(echo -e "${C_YELLOW}${I_PROMPT} Do you want to begin? [y/N]: ${C_END}")" -r choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then print_info "Aborting."; exit 0; fi
    fi

    # Execute tasks based on flags or full run mode.
    if [ "$run_all" = true ] || [ "${tasks_to_run[initial-setup]}" = true ]; then task_initial_files_setup; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[setup-repos]}" = true ]; then task_setup_repos; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[install-groups]}" = true ]; then task_install_groups; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[install-packages]}" = true ]; then task_install_packages; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[configure-hardware]}" = true ]; then task_configure_hardware; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[harden-system]}" = true ]; then task_harden_system; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[configure-user]}" = true ]; then task_configure_user; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[setup-nix]}" = true ]; then task_setup_nix; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[setup-hyprland]}" = true ]; then task_setup_hyprland; fi
    if [ "$run_all" = true ] || [ "${tasks_to_run[cleanup]}" = true ]; then task_cleanup; fi

    set +x # Disable xtrace at the end of the script.
    print_step "$I_FINISH Run Complete!"
    print_success "All requested tasks finished successfully."
    print_warning "A final reboot is highly recommended to apply all changes."
}

# Pass all script arguments to the main function.
main "$@"
````
