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
- [ ] Integrate the setup of 99-custom-vars-env.sh
- [ ] Integrate task_setup_hyprland to task_setup_user
- [ ] Add stow setup to task_setup_user
- [ ] setup-github-keys not working inside this task

---

# setup.sh tasks

**Determine where to put these functions in setup.sh**

- [ ] [Separate Function] Add the follow mon-arch repos CachyOS and Blackarch

- [ ] [Separate Function] Integrate neovim setup from https://docs.astronvim.com/configuration/manage_user_config/. Integration for emacs step will be added later

# packages.txt pkgs

- [ ] papirus-icons
- [ ] nodejs-neovim

Rewrite the bash script from the `setup.txt` file by implementing the following refactoring and logic updates. The final output must be the complete, rewritten script formatted in a single, readable markdown code block.

The core structure of the script and all tasks not explicitly mentioned below should be preserved. The modifications are as follows:

**1. Adapt to a Local File Structure**
All external fetching of configuration files and dotfiles must be removed. The script must be adapted to use a local directory structure relative to its own location:

- **File Paths:** Update all references to configuration files (e.g., `packages.txt`, `makepkg.conf.txt`) to source them from a local `./preconfig/` directory.
- **Dotfiles:** Replace the Git clone operation for `.hyprdots` with logic that copies the contents of a local `./dotfiles/` directory into the user's home directory.
- **Pathing:** Use relative paths wherever feasible, particularly for accessing the `./preconfig/` and `./dotfiles/` directories.

**2. Modify Specific Task Functions**

- **`task_configure_pacman`:**
  - Expand this function to handle initial environment setup.
  - Integrate a new step to copy the file `99-custom-vars-env.sh.txt` (located in the `./preconfig/` directory) to `/etc/profile.d/99-custom-vars-env.sh` and make it executable.

- **`task_setup_asus`:**
  - Simplify the service management logic.
  - Remove the `systemctl list-unit-files` check and directly enable the services: `supergfxd.service`, `power-profiles-daemon.service`, and `switcheroo-control.service`.

- **`task_manual_installations`:**
  - Remove the entire section responsible for the manual installation of "Caelestia Shell".

- **`task_setup_nix`:**
  - Modify the function to align with the new local dotfile structure.
  - The Nix installation using the Determinate Systems installer must be executed with the `run_as_user` function.
  - Remove the logic that clones the home-manager repository from GitHub.
  - Remove the step that deletes the existing `~/.config/home-manager` directory. The script should now assume that the dotfiles from the local `./dotfiles` directory are already correctly placed or symlinked in `~/.config/`.

**3. Merge and Reassign Tasks**

- **`task_configure_user` and `task_setup_hyprland`:**
  - Merge the `task_setup_hyprland` function into the `task_configure_user` function to consolidate all user-specific setup steps into one place.
  - Within the newly merged function, ensure the `setup-github-keys` command is executed **directly**, without using the `run_as_user` wrapper, to allow it to correctly access the Nix/home-manager environment.
