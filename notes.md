# Nobara Linux
**Nobara repository can be used to create custom nobara linux iso**

- setup brew
- sudo dnf install openssh
- setup rustup
- setup ssh
- brew install markdownlint-cli
- sudo dnf install kitty
- git clone --recurse-submodules git@github.com:aahsnr/emacs.git ~/.config/emacs
- installed packages from packages.sh
- brew install yazi
- kept a copy of bash history for later use
- added home-configs
- executed the following commands:
  sudo sh -c 'echo "%\_with_kmod_nvidia_open 1" > /etc/rpm/macros.nvidia-kmod'
  sudo akmods --kernels $(uname -r) --rebuild
- sudo dnf install nvidia-vaapi-driver libva-utils vdpauinfo
- sudo dnf install yarn
- sudo dnf install hspell hspell-devel nuspell nuspell-devel libvoikko libvoikko-devel hunspell-en-US enchant2-devel pkgconf
- sudo dnf install atuin python-neovim npm git-delta git-lfs libsecret-devel
- systemctl --user enable --now gnome-keyring-daemon
- sudo dnf install go ripgrep fd mpv
- sudo dnf remove at abrt nfs-utils chrony tuned-ppd sssd-client zoxide
- use home-manager to setup git and gnome-keyring
