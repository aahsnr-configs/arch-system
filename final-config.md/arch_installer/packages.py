# arch_installer/packages.py
from typing import List, Set


class PackageLists:
    """A centralized class for all package lists."""

    @staticmethod
    def _get_base_packages() -> Set[str]:
        return {
            "acpid",
            "amd-ucode",
            "arch-audit",
            "btrfs-progs",
            "boost",
            "btop",
            "chrony",
            "curl",
            "cmake",
            "dosfstools",
            "dbus-python",
            "downgrade",
            "efibootmgr",
            "fdupes",
            "fastfetch",
            "fwupd",
            "gcc",
            "grub-btrfs",
            "haveged",
            "jq",
            "jitterentropy-rngd",
            "linux-firmware",
            "lynis",
            "logrotate",
            "libva",
            "make",
            "mesa",
            "meson",
            "networkmanager",
            "openssh",
            "pacman-contrib",
            "pkgconf",
            "plymouth",
            "plocate",
            "piavpn",
            "rng-tools",
            "sysstat",
            "snapper",
            "snap-pac",
            "snap-pac-grub",
            "sof-firmware",
            "smartmontools",
            "texinfo",
            "unzip",
            "unrar",
            "upower",
            "wget",
            "xz",
            "zip",
            "zstd",
        }

    @staticmethod
    def _get_hyprland_packages() -> Set[str]:
        return {
            "adw-gtk-theme",
            "bibata-cursor-theme",
            "cliphist",
            "gnome-themes-extra",
            "greetd",
            "greetd-tuigreet",
            "grim",
            "gstreamer",
            "gst-plugin-pipewire",
            "gst-plugins-bad",
            "gst-plugins-base",
            "gst-plugins-good",
            "gst-plugins-ugly",
            "gtk-engine-murrine",
            "hypridle",
            "hyprland",
            "hyprlock",
            "hyprnome",
            "hyprpaper",
            "hyprpicker",
            "hyprpolkitagent",
            "hyprsunset",
            "inotify-tools",
            "kvantum",
            "kvantum-qt5",
            "mpv",
            "nwg-drawer",
            "nwg-look",
            "papirus-icon-theme",
            "pavucontrol",
            "pipewire",
            "pipewire-alsa",
            "pipewire-pulse",
            "pyprland",
            "qt5-wayland",
            "qt5ct",
            "qt6-wayland",
            "qt6ct",
            "rofi-wayland",
            "sassc",
            "slurp",
            "swappy",
            "swww",
            "socat",
            "thunar",
            "thunar-archive-plugin",
            "thunar-media-tags-plugin",
            "thunar-volman",
            "trash-cli",
            "tumbler",
            "uwsm",
            "wf-recorder",
            "wireplumber",
            "xarchiver",
            "xdg-desktop-portal-hyprland",
            "xdg-user-dirs",
            "xdg-user-dirs-gtk",
            "yazi",
        }

    @staticmethod
    def _get_caelestia_packages() -> Set[str]:
        return {
            "caelestia-cli",
            "quickshell-git",
            "ddcutil",
            "brightnessctl",
            "app2unit",
            "cava",
            "bluez-utils",
            "lm_sensors",
            "fish",
            "aubio",
            "libpipewire",
            "glibc",
            "qt6-declarative",
            "gcc-libs",
            "power-profiles-daemon",
            "ttf-material-symbols-variable",
            "libqalculate",
        }

    @staticmethod
    def _get_applications() -> Set[str]:
        return {
            "zathura",
            "zathura-pdf-poppler",
            "zen-browser-bin",
            "zotero",
            "deluge-gtk",
            "bleachbit",
            "bitwarden",
            "xournalpp",
        }

    @staticmethod
    def _get_dev_tools() -> Set[str]:
        return {
            "autoconf",
            "automake",
            "cargo",
            "devtools",
            "direnv",
            "emacs-lsp-booster-git",
            "fd",
            "fzf",
            "go",
            "hspell",
            "nuspell",
            "libvoikko",
            "hunspell",
            "hunspell-en_us",
            "imagemagick",
            "jansson",
            "neovim",
            "nodejs",
            "nodejs-neovim",
            "npm",
            "org.freedesktop.secrets",
            "pkg-config",
            "poppler",
            "poppler-glib",
            "python-neovim",
            "python-pip",
            "python-pynvim",
            "ripgrep",
            "rust",
            "tree-sitter-cli",
            "tree-sitter-bash",
            "tree-sitter-markdown",
            "tree-sitter-python",
            "ttf-jetbrains-mono",
            "ttf-jetbrains-mono-nerd",
            "ttf-ubuntu-font-family",
            "typescript",
            "wl-clipboard",
            "yarn",
        }

    @staticmethod
    def _get_cli_tools() -> Set[str]:
        return {
            "atuin",
            "bat",
            "eza",
            "starship",
            "tealdeer",
            "thefuck",
            "zoxide",
            "zsh",
        }

    @staticmethod
    def _get_graphics_packages() -> Set[str]:
        return {
            "ffnvcodec-headers",
            "libva-nvidia-driver",
            "linux-cachyos-bore-lto-nvidia-open",
            "nvidia-container-toolkit",
            "nvidia-utils",
            "opencl-nvidia",
            "vulkan-headers",
            "vulkan-tools",
            "vulkan-validation-layers",
            "xf86-video-amdgpu",
            "xorg-xwayland",
        }

    @staticmethod
    def _get_container_packages() -> Set[str]:
        return {
            "aardvark-dns",
            "boxbuddy",
            "cockpit",
            "cockpit-packagekit",
            "cockpit-podman",
            "distrobox",
            "lxd",
            "netavark",
            "podman",
            "podman-docker",
        }

    @staticmethod
    def _get_security_packages() -> Set[str]:
        return {
            "git",
            "git-delta",
            "git-lfs",
            "gnome-keyring",
            "lazygit",
            "libsecret",
            "seahorse",
            "apparmor",
            "apparmor.d-git",
            "audit",
            "python-notify2",
            "python-psutil",
        }

    @classmethod
    def get_all(cls) -> List[str]:
        all_packages = set.union(
            *[
                cls._get_base_packages(),
                cls._get_hyprland_packages(),
                cls._get_caelestia_packages(),
                cls._get_applications(),
                cls._get_dev_tools(),
                cls._get_cli_tools(),
                cls._get_graphics_packages(),
                cls._get_container_packages(),
                cls._get_security_packages(),
            ]
        )
        return sorted(list(all_packages))
