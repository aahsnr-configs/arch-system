## Manual Tasks

- **add blackarch repo manually**
- **Always apply symlinks manually for home configs including `sudo ln -sv` for nvim**

## General TODOS

- [x] Remove git setup from main script

- [x] Integrate a custom script to install pia vpn manually using a separate function and separate flag

- [x] At the end integrate neovim and doom emacs setup using a separate function and a separate flag

- [x] Make sure to setup neovim for root user using `sudo ln -sv`

- [x] Integrate reflector setup to the bash script

- [x] Add no-confirm to determinate-nix installer as add the run_as_user function to the installer

- [x] Enable supergfxd, power-profiles-daemon and switcheroo-control without searching for the service unit files

- [x] Integrate the setup of 99-custom-vars-env.sh

- [x] Integrate task_setup_hyprland to task_setup_user

- [x] setup-github-keys not working inside this task

- [x] reorder some of the tasks

- [x] add reflector setup to initial setup

- [x] autostart foot-server using systemd service

- [x] use footclient in Hyprland

- [ ] use normal foot in pyprland

- [ ] setup paru config file in `/etc/paru.conf` in the initial setup task

- [x] when installing official/aur packages using paru, add `--skipreview` flag to paru

- [ ] integrate caelestia auto theme with qt6 apps

- [ ] increase the address bar size for brave browser by **scaling Hyprland to 1.0 and set resolution to 1080p**

- [ ] install and implement yazi plugins using home-manager - add hmModule too;

- [ ] install and implement tmux plugins using home-manager - add hmModule too;

- [x] not able to move floating windows using mouse: fix this

- [ ] change fish theme to catppuccin

- [ ] add matugen templates

- [ ] open an issue for caelestia shell and dots where changing wallpapers doesn't change configuration colorsheme for foot terminal and other shell utilities

- [ ] write a pacman hook that automatically runs `pac-clean/similar` when removing pacman either using paru or pacman. There must be another hook for running `pac-clean/similar` after an AUR package finishes installation. This script might need to be run inside home-shell as these scripts are created by home-manager and may not be available in root

- [ ] setup @swap subvol and swapfile by chrooting into my arch system from another system

- [x] change caelestia clock to AM/PM

- [x] prevent hm from setting theme as it interferes with caelestia automatically changing theme

- [ ] Set roboto font as the default normal font, normal mono font, sans font and install these packages using

```
paru -S ttf-roboto ttf-roboto-mono-nerd
```

- [ ] Integrate the fisher plugin manager setup along with instructions to install popular fish plugins into the setup script

- [ ] Implement hyprterm scripts for kitty and foot and integrate into home-manager scripts hmModule

- [ ] Make sure emacs setup is printed to tty when executing inside `setup.sh`

- [ ] hdr seems to have blurring issues

- [ ] add `pacman-key --populate` after `reflector` setup

- [ ] switch to dracut from mkinitcpio so that you can add persistent kernel parameters without messing with proc

- [ ] learn more about the power-profiles-daemon for arch linux

- [ ] setup snapshots, snapper and limine integration.

## Issues

---

- [ ] Maybe nvidia env variables fixes nvidia issues
- [ ] Disable shadow if it costs performance
- [ ] Enable the following plugins
  - hyprscrolling
  - [hyprtasking](https://github.com/raybbian/hyprtasking)
- [ ] Find rubik variations using font server
- [ ] re-enable nvidia-powerd if performance degrades
