#!/bin/sh
paru -S rustup
rustup default stable

curl -fsSL https://install.danklinux.com | sh
ln -sv "$HOME/Git/configs/arch-system/dots/bin/" "$HOME/"
ln -sv "$HOME/Git/configs/arch-system/dots/.zshrc" "$HOME/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/atuin/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/bat/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/btop/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/enchant/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/fd/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/imv/" "$HOME/.config/"
sudo rm -rf "$HOME/.config/niri"
sudo rm -rf "$HOME/.config/kitty"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/kitty/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/lazygit/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/niri/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/nvim/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/starship.toml" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/swappy/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/tealdeer/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/tmux/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/yazi/" "$HOME/.config/"
ln -sv "$HOME/Git/configs/arch-system/dots/.config/zathura/" "$HOME/.config/"

# Harden System
sudo tee /etc/issue >/dev/null <<'EOF'
-- WARNING -- This system is for the use of authorized users only. Individuals
using this computer system without authority or in excess of their authority
are subject to having all their activities on this system monitored and
recorded by system personnel. Anyone using this system expressly consents to
such monitoring and is advised that if such monitoring reveals possible
evidence of criminal activity system personal may provide the evidence of such
monitoring to law enforcement officials.
EOF

sudo cp /etc/issue /etc/issue.net

sudo tee /etc/security/limits.d/99-custom-limits.conf >/dev/null <<'EOF'
* soft nofile 65536
* hard nofile 1048576
EOF

sudo tee /etc/ssh/sshd_config.d/99-hardening.conf >/dev/null <<'EOF'
Port 47
LogLevel VERBOSE
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
TCPKeepAlive no
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 2
EOF

sudo firewall-cmd --add-port=47/tcp --permanent
sudo firewall-cmd --remove-service=ssh --permanent
sudo firewall-cmd --reload
sudo systemctl reload sshd

# Configure User
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
