# **Instructions Set 1**

The bash script in the attached setup.txt file already contains a separate function and a corresponding flag to setup nix, home-manager and flakes in fedora/nobara linux. Keeping this function and flag but replace the contents in this function with the following new instructions:

1. Install nix using the determinate nix installer with the following command `curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate`

2. Make sure nix is immediately available to the shell by issuing the command `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

3. Now create a new `nix.conf` file in ~/.config/nix/nix.conf. Create the corresponding directories if they don't exist. Then add the following content at the very beginning of the `nix.conf` file: `experimental-features = nix-command flakes`

4. Now setup home-manager by issuing the command `nix run home-manager/master -- init --switch`. This will create a home-manager directory `~/.config`. Delete this directory immediately.

5. Then issue the following command: `git clone https://github.com/aahsnr-configs/home-manager.git ~/.config/home-manager`

6. Then issue the command `home-manager switch` Now here comes the tricky part. The fedora system will already contain some files and directory that will overlap with the files and directory that my home-manager configuration will create. When that happens, `nix` will report an error saying that these directories/files already exist. In that case, run the command `home-manager switch -b backup`. Then repeat the command `home-manager switch`.

This concludes the instructions for setting up nix, home-manager and flakes. Replace the already existing code for the function relating to this with the new instructions from above, making sure that the instructions run sequentially.

Furthermore, remove the fedora flaptak repository, if it exists, from the system. Also remove flathub system remote repo if it exists. If the flathub user repo does not exist, add it to the system using the following command `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`. All these must occur in the flatpak part of the bash script.

Keep in mind that this bash script is intended for Fedora Linux 42. Make any changes that are necessary that optimize the script and make it useful to run in fedora

---

# Instructions Set 2

Setup a new function and its corresponding flag to setup fedora media and codecs installation from rpm-fusion

Setup a new function to install nvidia drivers using the rpmfusion instructions
