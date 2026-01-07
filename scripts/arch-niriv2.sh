#!/bin/sh
# NOTE: Don't install any emacs related packages
# NOTE: Don't install any neovim related packages
# NOTE: Dont't install pymol
paru -S adw-gtk-theme \
  ananicy-cpp \
  arch-audit \
  atuin \
  audit \
  bat \
  bibata-cursor-theme-bin \
  bitwarden \
  bleachbit \
  bluez \
  bluez-utils \
  bpf \
  bpftune-git \
  brave-bin \
  brightnessctl \
  btop \
  chafa \
  cliphist \
  ddcutil \
  dgop \
  direnv \
  distrobox \
  dms-shell-bin \
  dosfstools \
  dust \
  egl-gbm \
  egl-wayland \
  egl-wayland2 \
  egl-x11 \
  eza \
  firewalld \
  flatpak \
  fwupd \
  fwupd-efi \
  fzf \
  git \
  github-cli \
  git-lfs \
  gnome-keyring \
  grim \
  gst-plugin-pipewire \
  gst-plugins-bad \
  gst-plugins-good \
  gst-plugins-ugly \
  gstreamer \
  gtk3 \
  gtk4 \
  gvfs \
  gzip \
  haveged \
  hwdata \
  imv \
  inotify-tools \
  jitterentropy \
  jitterentropy-rngd \
  jq \
  kitty \
  kitty-shell-integration \
  kitty-terminfo \
  lazygit \
  logrotate \
  lynis \
  matugen \
  mpv \
  niri \
  noto-color-emoji-fontconfig \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  nvidia-settings \
  nvidia-utils \
  nwg-look \
  onlyoffice-bin \
  opencl-nvidia \
  org.freedesktop.secrets \
  papirus-folders \
  papirus-icon-theme \
  pay-respects-bin \
  pipewire \
  pipewire-alsa \
  pipewire-audio \
  pipewire-jack \
  pipewire-pulse \
  pkgconf \
  pkgfile \
  planify \
  plocate \
  plymouth \
  podman \
  polkit \
  poppler \
  poppler-glib \
  profile-sync-daemon \
  python-notify2 \
  python-psutil \
  qt5ct \
  qt6ct-kde \
  quickshell-git \
  rate-mirrors \
  rebuild-detector \
  reflector \
  rng-tools \
  seatd \
  sed \
  sof-firmware \
  sound-theme-freedesktop \
  starship \
  superproductivity-bin \
  switcheroo-control \
  sysfsutils \
  sysstat \
  systemd \
  systemd-sysvcompat \
  taglib \
  tar \
  tealdeer \
  tk \
  tpm2-tss \
  transmission-gtk \
  trash-cli \
  ttf-jetbrains-mono \
  ttf-jetbrains-mono-nerd \
  ttf-nerd-fonts-symbols \
  ttf-nerd-fonts-symbols-common \
  udiskie \
  unrar \
  unzip \
  wget \
  which \
  wl-clipboard \
  wpa_supplicant \
  x264 \
  x265 \
  xdg-desktop-portal \
  xdg-desktop-portal-gnome \
  xdg-desktop-portal-gtk \
  xdg-user-dirs \
  xdg-user-dirs-gtk \
  xdg-utils \
  xorg-xwayland \
  xournalpp \
  xwayland-satellite \
  yazi \
  yyjson \
  zathura \
  zathura-pdf-poppler \
  zen-browser-bin \
  zoxide \
  zram-generator \
  zsh

# ASUS Linux setup
sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
sudo pacman-key --finger 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35

wget "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8b15a6b0e9a3fa35" -O g14.sec
sudo pacman-key -a g14.sec

sudo nvim /etc/pacman.conf

paru -Syyuu
paru -S asusctl power-profiles-daemon rog-control-center

git clone https://gitlab.com/asus-linux/nvidia-laptop-power-cfg.git
cd nvidia-laptop-power-cfg
makepkg -sfi && cd

sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
sudo systemctl enable --now nvidia-powerd
sudo systemctl enable nvidia-suspend-then-hibernate.service
sudo systemctl enable --now bluetooth

curl -fsSL https://install.danklinux.com | sh
ln -sv "$HOME/Git/configs/arch-system/dots/bin/" "$HOME/"
ln -sv "$HOME/Git/configs/arch-system/dots/.zshrc" "$HOME/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/atuin/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/bat/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/btop/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/enchant/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/fd/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/imv/" "$HOME/.config/"
sudo rm -rf "$HOME/.config/niri"
sudo rm -rf "$HOME/.config/kitty"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/kitty/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/lazygit/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/niri/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/nvim/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/starship.toml" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/swappy/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/tealdeer/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/tmux/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/yazi/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/zathura/" "$HOME/.config/"

# Harden System
sudo tee /etc/issue >/dev/null <<'EOF'
-- WARNING -- This system is for the use of authorized users only. Individuals
using this computer system without authority or in excess of their authority
are subject to having all their activities on this system monitored and
recorded by system personnel. Anyone using this system expressly consents to
such monitoring and is advised that if such monitoring reveals possible
evidence of criminal activity system personal may provide the evidence of such
monitoring to law enforcement officials.
EOF

sudo systemctl enable bluetooth power-profiles-daemon

sudo cp /etc/issue /etc/issue.net

sudo tee /etc/security/limits.d/99-custom-limits.conf >/dev/null <<'EOF'
* soft nofile 65536
* hard nofile 1048576
EOF

# sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOF'
# Port 47
# LogLevel VERBOSE
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes
# ChallengeResponseAuthentication no
# X11Forwarding no
# AllowTcpForwarding no
# AllowAgentForwarding no
# TCPKeepAlive no
# ClientAliveCountMax 2
# MaxAuthTries 3
# MaxSessions 2
# EOF
#
# sudo firewall-cmd --add-port=47/tcp --permanent
# sudo firewall-cmd --remove-service=ssh --permanent
# sudo firewall-cmd --reload
# sudo systemctl reload sshd
#
# # Configure User
# mkdir -p "$HOME/.npm-global"
# npm config set prefix "$HOME/.npm-global"
