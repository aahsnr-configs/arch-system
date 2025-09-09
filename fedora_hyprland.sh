#!/bin/sh

sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
# sudo dnf config-manager --enable fedora-cisco-openh264

sudo dnf copr enable solopasha/hyprland
sudo dnf copr enable sneexy/zen-browser
sudo dnf copr enable lukenukem/asus-linux
sudo dnf update

sudo dnf install -y dnf-automatic cargo copr-selinux dnf-plugins-core fedora-workstation-repositories flatpak gtkmm3.0-devel gnome-keyring xcur2png kernel kernel-core kernel-devel kernel-devel-matched kernel-modules kernel-modules-core kernel-modules-extra nodejs npm pixman plymouth-theme-spinner fd-find poppler-utils ripgrep ffmpegthumbnailer mediainfo ImageMagick tar unzip aide arpwatch chrony cronie curl fail2ban fdupes lsd lynis PackageKit-command-not-found p7zip powertop psacct rng-tools sysstat wget neovim python3-neovim tree-sitter wl-clipboard deluge-gtk emacs file-roller zen-browser thunar thunar-volman thunar-media-tags-plugin thunar-archive-plugin tumbler kitty zathura zathura-zsh-completion zathura-pdf-poppler kvantum papirus-icon-theme qt5ct qt6ct gnome-themes-extra gtk-murrine-engine sassc vulkan xorg-x11-drv-nvidia-cuda-libs nvidia-vaapi-driver libva-utils vdpauinfo autoconf automake binutils bison ccache cmake ctags elfutils flex go gcc gcc-c++ gdb glibc-devel libtool make perf pkgconf strace valgrind gettext meson ninja-build abrt-desktop setroubleshoot system-config-language alsa-utils pavucontrol pamixer pipewire pipewire-alsa pipewire-gstreamer pipewire-pulseaudio pipewire-utils pulseaudio-utils wireplumber redhat-rpm-config rpm-build koji mock rpmdevtools pungi rpmlint cliphist egl-wayland greetd pam-devel grim hyprcursor hypridle hyprland hyprland-devel hyprland-contrib hyprlang hyprnome hyprpaper hyprpicker hyprwayland-scanner pyprland qt5-qtwayland qt6-qtwayland slurp tomlplusplus xisxwayland xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xorg-x11-server-Xwayland xorg-x11-server-Xwayland-devel wf-recorder asusctl power-profiles-daemon supergfxctl asusctl-rog-gui NetworkManager bluez --allowerasing

sudo systemctl enable supergfxd.service power-profiles-daemon

sudo systemctl set-default graphical.target
systemctl --user enable --now wireplumber.service pipewire-pulse.socket pipewire.socket pipewire-pulse.service pipewire.service

