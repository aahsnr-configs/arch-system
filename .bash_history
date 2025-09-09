sudo dnf update
sudo reboot
sudo dnf install akmod-nvidia
sudo dnf install git-core
mkdir git
cd git/
git clone https://github.com/aahsnr/fedora-setup
cd fedora-setup/
ls
cd preconfigured-files/
ls
sudo cp -R dnf.conf /etc/dnf/
sudo cp -R variables.sh /etc/profile.d/
cd
sudo dnf install akmod-nvidia
sudo dnf install neovim tree-sitter-cli
cd git/q
git clone https://github.com/aahsnr/nvim-config ~/.config/nvim
nvim
cd
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
nvim .bashrc 
sudo nvim /etc/profile.d/variables.sh 
sudo dnf install akmod-nvidia
sudo dnf install emacs
sudo dnf install cargo rust
sudo reboot
sudo dnf install libreoffice*
sudo dnf install papirus-icon-theme
sudo dnf install wl-clipboardx
sudo dnf install wl-clipboard
cargo install emacs-lsp-booster
killall emacs
sudo dnf install libzmq-devel
sudo dnf install libzmq
dnf search zmq-devel
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew
cd git/
ls
cd fedora-setup/
ls
cd setup-scripts/
ls
nvim fedora-setup.sh 
./fedora-setup.sh 
sudo ./fedora-setup.sh 
sudo dnf install zen-browser
cd
cd git/
git clone https://github.com/aahsnr/.hyprdots
ln -sv $HOME/git/.hyprdots/.fonts/ ~/
cd
sudo dnf install podman distrobox
git clone --recurse-submodules git@github.com:aahsnr/emacs.git ~/.config/emacs
git clone https://github.com/aahsnr/emacs ~/.config/emacs
cd .config/emacs/
git submodule init
git submodule update
cd
reload-emacs
cd .config/emacs/
ls
cd bin/
ls
cd
emacs-log 
dnf search zmq
sudo dnf install cppzmq-devel
reload-emacs
cd
killall emacs
emacs --daemon
sudo rm -rf .config/emacs/
git clone https://github.com/aahsnr/emacs ~/.config/emacs
cd .config/emacs/
git submodule init
git submodule update
ls
cd bin/
ls
nvim emacs-log 
ls
./reload-emacs-daemon 
killall emacs
./reload-emacs-daemon 
cd .config/kitty/
ls
nvim kitty.conf 
cd
ls -a
nvim .bash_history 
nvim .bashrc
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ahsan/.bashrc
source .bashrc
brew install zmq
killall emacs
emacs --daemon
killall emacs
git clone https://github.com/aahsnr/oth
git clone https://github.com/aahsnr/org
rm -rf org/
git clone https://github.com/aahsnr/org
git clone https://github.com/aahsnr/org.git
cd git/
ls
sudo dnf install openssh
cd
nvim .bash_history 
cd git/
ls
cd fedora-setup/
ls
nvim notes.md
sudo systemctl enable --now sshd
ssh-keygen -t ed25519 -C "aahsnr@proton.me"
nvim ~/.ssh/id_ed25519.pub
rm -rf ~/.ssh/id_ed25519.pub
ssh-keygen -t ed25519 -C "ahsanur041@proton.me"
nvim ~/.ssh/id_ed25519.pub
ssh-keygen -t ed25519 -C "ahsanur041@proton.me"
nvim ~/.ssh/id_ed25519.pub
cd
ls
ls -a
git clone git@github.com:aahsnr/org.git
cd git/fedora-setup/
ls
nvim notes.md 
sudo dnf install markdownlint
dnf search markdown
brew install markdownlint
brew install markdownlint-cli
nvim notes.md 
cd
rm -rf .config/emacs/
killall emacs
git clone --recurse-submodules git@github.com:aahsnr/emacs.git ~/.config/emacs
cd git/fedora-setup/
ls
nvim notes.md 
cd ..
ls
git clone https://github.com/aahsnr/arch-system
cd arch-system/
ls
cd final-config.md/
ls
nvim final_script.md 
brew install zmq
sudo dnf install direnv
sudo dnf updater
sudo dnf update
cd git/
ls
cd
nvim .bashrc 
ls
ls -a
nvim .bash_history 
cd git/fedora-setup/
ls
nvim notes.md 
nvim
nvim notes.md 
sudo dnf install gnome-tweaks
cd
cd git/
ls
git clone https://github.com/aahsnr/.hyprdots
cd
ln -sv $HOME/git/.hyprdots/.config/kitty/ ~/.config/
rm -rf .config/kitty/
ln -sv $HOME/git/.hyprdots/.config/kitty/ ~/.config/
sudo dnf install kitty
nvim sample
mv sample sample.sh
nvim sample.sh 
bash sample.sh 
sudo dnf copr enable atim/starship
bash sample.sh 
sudo dnf clean all
nvim sample.sh 
bash sample.sh 
nvim sample.sh 
z
cd git/fedora-setup/
ls
nvim notes.md 
nvim packages.sh 
sudo dnf copr enable errornointernet/quickshell
sudo dnf copr enable atim/starship
