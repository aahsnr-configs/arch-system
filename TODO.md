# General TODOS

- [x] Remove git setup from main script
- [x] Integrate a custom script to install pia vpn manually using a separate function and separate flag
- [x] At the end integrate neovim and doom emacs setup using a separate function and a separate flag
- [x] Make sure to setup neovim for root user using `sudo ln -sv`
- [x] Integrate reflector setup to the bash script
- [x] Add no-confirm to determinate-nix installer as add the run_as_user function to the installer
- [x] Enable supergfxd, power-profiles-daemon and switcheroo-control without searching for the service unit files
- [x] Integrate the setup of 99-custom-vars-env.sh
- [x] Integrate task_setup_hyprland to task_setup_user
- [x] Use a manual way to symlink instead of using stow
- [x] setup-github-keys not working inside this task
- [x] while installing packages using yay inside the script, there are no verbose/interactive output normally seen when installing arch/AUR packages using yay outside the bash script, i.e. in the terminal. A similar thing happens with the determinate-nix installer where it does not allow interactive installing as well. The script needed use the determinate-nix installer's --no-confirm flag to install nix. Fix these issues for me.
- [x] reorder some of the tasks
- [x] blackarch repo is not being added
- [x] add reflector setup to initial setup
- [x] autostart foot-server using systemd service\
- [x] use footclient in Hyprland but use normal foot in pyprland
- [x] setup paru config file in `/etc/paru.conf` in the initial setup task
- [x] make the code and commands to setup limine-mkinitcpio-hook similar to the code for setting up paru
- [x] when installing official/aur packages using paru, add `--skipreview` flag to paru
- [ ] integrate caelestia auto theme with qt6 apps
- [ ] increase the address bar size for brave browser
- [ ] install and implement yazi plugins using home-manager - add hmModule too;
- [ ] install and implement tmux plugins using home-manager - add hmModule too;
- [ ] not able to move floating windows using mouse: fix this
- [ ] change fish theme to catppuccin
- [ ] rearrange linux-system so that dotfiles are in the main repository directory and everything setup related is in setup folder except for TODO.md
- [ ] add matugen templates
- [ ] open an issue for caelestia shell and dots where changing wallpapers doesn't change configuration colorsheme for foot terminal and other shell utilities
- [ ] write a pacman hook that automatically runs `pac-clean` when removing pacman either using paru or pacman. There must be another hook for running `pac-clean` after an AUR package finishes installing
- [ ] setup @swap file
- [ ] fix config files using stow
- [x] change caelestia clock to AM/PM
- [ ] prevent hm from setting theme as it interferes with caelestia automatically changing theme

---

# setup.sh tasks

**Determine where to put these functions in setup.sh**

- [ ] [Separate Function] Add the follow mon-arch repos CachyOS and Blackarch

- [ ] [Separate Function] Integrate neovim setup from https://docs.astronvim.com/configuration/manage_user_config/. Integration for emacs step will be added later

- [ ] reable nvidia-powerd if performance degrades
- [ ] disabling blur makes hdr ineffective
