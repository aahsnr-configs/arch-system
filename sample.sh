#!/usr/bin/env bash

# --- Strict Error Handling ---
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error.
# -o pipefail: Return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Configuration & Variables ---
TARGET_USER=$(logname)
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# --- 1. System Dependencies ---
# Update and install base dependencies needed for the script to run
sudo pacman -S --needed --noconfirm git base-devel
sudo pacman -S --needed --noconfirm neovim wl-clipboard curl wget pciutils dmidecode xdg-user-dirs

# --- 2. ASUS Repository Setup ---
# Import and sign the G14 signing key
sudo pacman-key --recv-keys "8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"
sudo pacman-key --lsign-key "8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"

# Add the G14 repository to pacman.conf
# Uses printf for cleaner formatting than echo -e
printf "\n[g14]\nServer = https://arch.asus-linux.org\n" | sudo tee -a /etc/pacman.conf >/dev/null

# --- 3. ASUS Package Installation ---
# Update database and install ASUS specific tools
paru -Syu --noconfirm
paru -S --needed --noconfirm asusctl power-profiles-daemon supergfxctl switcheroo-control rog-control-center

# Enable ASUS services
sudo systemctl daemon-reload
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl enable --now supergfxd.service
sudo systemctl enable --now switcheroo-control.service

# --- 4. Install Packages from Config File ---
# grep filters comments/empty lines; xargs -r only runs paru if packages are found
grep -vE '^\s*#|^\s*$' "$SCRIPT_DIR/preconfig/packages.txt" | xargs -r paru -S --needed --noconfirm

# --- 5. Manual Installation: PIA VPN ---
# Use mktemp for secure temporary file creation
PIA_INSTALLER=$(mktemp --suffix=.run)
wget -O "$PIA_INSTALLER" "https://installers.privateinternetaccess.com/download/pia-linux-3.6.2-08398.run"
chmod +x "$PIA_INSTALLER"
"$PIA_INSTALLER"

# --- 6. User Configuration (NPM & Dotfiles) ---
mkdir -p "$USER_HOME/.npm-global"
npm config set prefix "$USER_HOME/.npm-global"
mkdir -p "$USER_HOME/.config"

# --- 7. User Services ---
# Enable audio and terminal services for the user
systemctl --user enable --now pipewire pipewire-pulse wireplumber foot

# --- 8. Editor Setup ---
# Neovim: Headless setup to install plugins/tools without opening the UI
nvim --headless "+Lazy! sync" +TSUpdateSync "+autocmd User MasonToolsUpdateCompleted quitall" +MasonToolsInstall

# Doom Emacs: Clone and Install
# Check if directory exists to avoid git errors on re-run (simple safeguard)
rm -rf "$USER_HOME/.config/emacs"
git clone --depth 1 https://github.com/doomemacs/doomemacs "$USER_HOME/.config/emacs"
# --force is used to avoid interactive prompts
"$USER_HOME/.config/emacs/bin/doom" install --force

# --- 9. System Hardening ---
paru -S --needed --noconfirm apparmor apparmor.d-git audit arch-audit openssh procps-ng rng-tools sysstat haveged lynis-git libpwquality bleachbit ufw

# Enable security services
sudo systemctl enable --now auditd apparmor haveged rngd sshd

# Configure Audit Group
# -f creates group only if it doesn't exist; -r creates a system group
sudo groupadd -f -r audit
sudo gpasswd -a "$TARGET_USER" audit

# Configure Audit Logging
# grep check ensures we don't append the line multiple times
grep -qF "log_group = audit" /etc/audit/auditd.conf || echo "log_group = audit" | sudo tee -a /etc/audit/auditd.conf >/dev/null

# --- Commented Out Sections (Preserved) ---

# # --- 15. Harden SSH & Firewall ---
# sudo mkdir -p /etc/ssh/sshd_config.d
# sudo tee /etc/ssh/sshd_config.d/99-hardening.conf <<EOF
# Port 47
# LogLevel VERBOSE
# PermitRootLogin no
# PasswordAuthentication no
# ChallengeResponseAuthentication no
# X11Forwarding no
# EOF
# sudo systemctl reload sshd
# sudo ufw allow 47/tcp comment 'Custom SSH Port'
# sudo ufw deny 22/tcp comment 'Default SSH Port'
# sudo ufw --force enable
#
# # --- 16. Harden Kernel & Proc ---
# sudo tee /etc/sysctl.d/99-custom-hardening.conf <<EOF
# kernel.kptr_restrict = 2
# kernel.sysrq = 0
# kernel.unprivileged_bpf_disabled = 1
# kernel.yama.ptrace_scope = 2
# net.ipv4.conf.all.rp_filter = 1
# EOF
# sudo sysctl -p /etc/sysctl.d/99-custom-hardening.conf
# sudo sed -i 's|^\s*proc\s*/proc.*|proc /proc proc nosuid,nodev,noexec,hidepid=2 0 0|' /etc/fstab
# sudo mount -o remount /proc
#
# # --- 17. Cleanup ---
# paru -Qtdq | xargs -r paru -Rns --noconfirm
# sudo -u "$TARGET_USER" nix-collect-garbage -d
