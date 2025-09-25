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

# --- Script Task Order (Full Installation) ---

Rewrite the new attached bash script `setup.txt` so that the new order of tasks now follows this order:

1. Pre-flight Checks: Verifies privileges, connectivity, dependencies, and required files.

2. Initial Setup: Optimizes pacman.conf, makepkg.conf, and environment variables.

3. Setup Extra Repos: Adds CachyOS and BlackArch repositories.

4. Install Kernel and Drivers: Installs the CachyOS kernel and NVIDIA drivers.

5. Setup for ASUS Laptops: Adds the g14 repo and installs specific tools.

6. Install Packages: Installs packages from 'packages.txt' using the AUR helper.

7. Manual Installs: Installs third-party software like themes and VPNs.

8. Setup Dotfiles: Symlinks user dotfiles from a predefined source directory.

9. Setup Nix & Home-Manager: Installs and configures Nix with flakes.

10. Configure User: Sets up the user's dotfiles, shell, and services.

11. Cleanup: Removes orphaned packages and cleans the Nix store.

12. Setup Greeter: Configures greetd and tuigreet as the login manager.

13. Harden System: Implements basic security enhancements and enables services.

Only add docs for the safety checks. This docs must be accessible in the linux terminal like the other docs, but does not have an associated flag like the others

Fix the documentation at the start of the script for configure user as it does not setup dotfiles
