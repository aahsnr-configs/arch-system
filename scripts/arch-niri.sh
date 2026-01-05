#!/bin/sh
# NOTE: Don't install any emacs related packages
# NOTE: Don't install any neovim related packages
# NOTE: Dont't install pymol
paru -S adw-gtk-theme \
  alsa-firmware \
  alsa-utils \
  amd-ucode \
  ananicy-cpp \
  apparmor \
  apparmor.d-git \
  arch-audit \
  archlinux-keyring \
  atuin \
  audit \
  base-devel \
  bash-completion \
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
  btrfs-assistant \
  btrfs-progs \
  cachyos-ananicy-rules \
  cachyos-hello \
  cachyos-hooks \
  cachyos-kernel-manager \
  cachyos-keyring \
  cachyos-mirrorlist \
  cachyos-plymouth-bootanimation \
  cachyos-rate-mirrors \
  cachyos-v3-mirrorlist \
  cachyos-v4-mirrorlist \
  chafa \
  chezmoi \
  cliphist \
  ddcutil \
  dgop \
  direnv \
  distrobox \
  dms-shell-bin \
  dnsmasq \
  dosfstools \
  dust \
  efibootmgr \
  egl-gbm \
  egl-wayland \
  egl-wayland2 \
  egl-x11 \
  exfatprogs \
  eza \
  ffmpeg \
  ffmpeg4.4 \
  ffmpegthumbnailer \
  firewalld \
  flatpak \
  fwupd \
  fwupd-efi \
  fzf \
  git \
  github-cli \
  git-lfs \
  gnome-keyring \
  gnome-tweaks \
  gnome-desktop-4 \
  gnome-desktop-common \
  grim \
  gsettings-desktop-schemas \
  gsettings-system-schemas \
  gst-plugin-pipewire \
  gst-plugins-bad \
  gst-plugins-bad-libs \
  gst-plugins-base-libs \
  gst-plugins-good \
  gst-plugins-ugly \
  gstreamer \
  gtk-update-icon-cache \
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
  linux-api-headers \
  linux-cachyos \
  linux-cachyos-headers \
  linux-cachyos-nvidia-open \
  linux-firmware \
  linux-firmware-amdgpu \
  linux-firmware-broadcom \
  linux-firmware-mediatek \
  linux-firmware-nvidia \
  linux-firmware-other \
  linux-firmware-realtek \
  linux-firmware-whence \
  logrotate \
  lynis \
  matugen \
  mesa \
  mesa-utils \
  mkinitcpio \
  mpv \
  nautilus \
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
  pacman-contrib \
  pacman-mirrorlist \
  papirus-folders \
  papirus-icon-theme \
  pay-respects-bin \
  pciutils \
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
  smartmontools \
  snap-pac \
  snapper \
  sof-firmware \
  sound-theme-freedesktop \
  soundtouch \
  starship \
  sudo \
  superproductivity-bin \
  switcheroo-control \
  sysfsutils \
  sysstat \
  systemd \
  systemd-resolvconf \
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
  udisks2 \
  unrar \
  unzip \
  upower \
  usbutils \
  util-linux \
  util-linux-libs \
  volume_key \
  vulkan-icd-loader \
  vulkan-tools \
  wavpack \
  wayland \
  wayland-protocols \
  wget \
  which \
  wireplumber \
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
  xf86-input-libinput \
  xf86-video-amdgpu \
  xorg-xwayland \
  xournalpp \
  xwayland-satellite \
  yazi \
  yyjson \
  zathura \
  zathura-pdf-poppler \
  zen-browser-bin \
  zeromq \
  zoxide \
  zram-generator \
  zsh \
  zstd

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
