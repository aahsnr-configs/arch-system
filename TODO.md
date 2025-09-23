# General TODOS

- [ ] Move setup-asus directly after setup-repos
- [ ] Add `garuda-update` at the end of setup-repos
- [x] Remove git setup from main script
- [ ] Use hyprland animations from Matt-FTW/dotfiles
- [x] Integrate a custom script to install pia vpn manually using a separate function and separate flag
- [ ] At the end integrate neovim and doom emacs setup using a separate function and a separate flag
- [ ] Make sure to setup neovim for root user using `sudo ln -sv`
- [ ] Integrate reflector setup to the bash script
- [x] Add no-confirm to determinate-nix installer as add the run_as_user function to the installer
- [ ] Enable supergfxd, power-profiles-daemon and switcheroo-control without searching for the service unit files
- [x] Integrate the setup of 99-custom-vars-env.sh
- [x] Integrate task_setup_hyprland to task_setup_user
- [ ] Add stow setup to task_setup_user
- [ ] Use a manual way to symlink instead of using stow
- [x] setup-github-keys not working inside this task
- [x] while installing packages using yay inside the script, there are no verbose/interactive output normally seen when installing arch/AUR packages using yay outside the bash script, i.e. in the terminal. A similar thing happens with the determinate-nix installer where it does not allow interactive installing as well. The script needed use the determinate-nix installer's --no-confirm flag to install nix. Fix these issues for me.
- [ ] add reflector setup to initial setup
- [ ] reorder some of the tasks
- [ ] blackarch repo is not being added

---

# setup.sh tasks

**Determine where to put these functions in setup.sh**

- [ ] [Separate Function] Add the follow mon-arch repos CachyOS and Blackarch

- [ ] [Separate Function] Integrate neovim setup from https://docs.astronvim.com/configuration/manage_user_config/. Integration for emacs step will be added later
