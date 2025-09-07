Of course. The installer has been reviewed and updated to ensure that all custom user systemd services are properly and securely integrated.

The `user_services.py` module is now the definitive source for managing these services. It programmatically creates secure, sandboxed service files for `pyprland` and `cliphist` (for both text and images), and then enables the full suite of necessary user services for a complete desktop experience.

This final version represents a complete, modular, and flexible installer that incorporates all previously requested features, from initial system audit to final cleanup. The entire application is rewritten below.

### How to Use the Flag-Based Application

The usage and prerequisites remain unchanged.

1.  **Prerequisites**: Ensure `python`, `git`, and `openssh` are installed.

    ```bash
    sudo pacman -Syu --noconfirm python git openssh
    ```

2.  **Download**: Get the complete `arch_installer` directory containing all the files listed below.

3.  **Run**: From the directory _containing_ the `arch_installer` package:
    - **Full Installation (Default):**

      ```bash
      # Usage: python -m arch_installer.install --dotfiles-url <URL>
      python -m arch_installer.install --dotfiles-url git@github.com:aahsnr/.hyprdots.git
      ```

    - **Running Specific Tasks:**
      ```bash
      # Example: Apply only user configurations and services
      python -m arch_installer.install --configure-user
      ```

---

### Project Structure

The file structure is the same. All subsequent code blocks should be saved with their corresponding file names inside the `arch_installer` directory.

```
.
└── arch_installer/
    ├── __init__.py
    ├── config.py
    ├── ui.py
    ├── utils.py
    ├── packages.py
    ├── system_config.py
    ├── user_config.py
    ├── user_services.py
    ├── engine.py
    └── install.py
```

---

### The Python Application Files

#### `arch_installer/__init__.py`

```python
# arch_installer/__init__.py
# This file intentionally left blank.
```

#### `arch_installer/config.py`

```python
# arch_installer/config.py
import os

LOG_FILE: str = "arch_setup.log"
USER_HOME: str = os.path.expanduser("~")
CURRENT_USER: str = os.getlogin()
DOTFILES_DIR: str = os.path.join(USER_HOME, ".dots")
```

#### `arch_installer/ui.py`

```python
# arch_installer/ui.py
import logging
import sys
from .config import LOG_FILE

class Colors:
    HEADER, BLUE, GREEN, YELLOW, RED, ENDC, BOLD = "\033[95m", "\033[94m", "\033[92m", "\033[93m", "\033[91m", "\033[0m", "\033[1m"

class Icons:
    STEP, INFO, SUCCESS, WARNING, ERROR, PROMPT, FINISH, PACKAGE, DESKTOP, SECURITY = "⚙️", "ℹ️", "✅", "⚠️", "❌", "❓", "🎉", "📦", "🖥️", "🛡️"

def setup_logging() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s", handlers=[logging.FileHandler(LOG_FILE, mode="w", encoding="utf-8")])

def print_step(message: str) -> None:
    print(f"\n{Colors.HEADER}{Colors.BOLD}═══ {Icons.STEP} {message} ═══{Colors.ENDC}")
    logging.info(f"--- STEP: {message} ---")

def print_info(message: str) -> None:
    print(f"{Colors.BLUE}{Icons.INFO} {message}{Colors.ENDC}")
    logging.info(message)

def print_success(message: str) -> None:
    print(f"{Colors.GREEN}{Icons.SUCCESS} {message}{Colors.ENDC}")
    logging.info(f"SUCCESS: {message}")

def print_warning(message: str) -> None:
    print(f"{Colors.YELLOW}{Icons.WARNING} {message}{Colors.ENDC}", file=sys.stderr)
    logging.warning(message)

def print_error(message: str) -> None:
    print(f"{Colors.RED}{Icons.ERROR} {message}{Colors.ENDC}", file=sys.stderr)
    logging.error(message)
```

#### `arch_installer/utils.py`

```python
# arch_installer/utils.py
import logging
import os
import socket
import subprocess
from .ui import print_info, print_error

def execute_command(command: list[str], description: str, cwd: str | None = None) -> bool:
    print_info(description)
    logging.info(f"Executing command: {' '.join(command)} in '{cwd or os.getcwd()}'")
    try:
        with subprocess.Popen(command, text=True, encoding="utf-8", cwd=cwd) as process:
            process.wait()
            if process.returncode != 0: raise subprocess.CalledProcessError(process.returncode, command)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError, KeyboardInterrupt) as e:
        error_type = "Command not found" if isinstance(e, FileNotFoundError) else "Process interrupted" if isinstance(e, KeyboardInterrupt) else "Command failed"
        print_error(f"{error_type}: {' '.join(command)}. Reason: {e}")
        return False
    except Exception as e:
        print_error(f"An unexpected error occurred: {' '.join(command)}. Reason: {e}")
        return False

def check_internet_connection() -> bool:
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        return True
    except OSError:
        return False
```

#### `arch_installer/packages.py`

```python
# arch_installer/packages.py
from typing import List, Set

class PackageLists:
    """A centralized class for all package lists."""
    @staticmethod
    def _get_base_packages() -> Set[str]: return {"acpid", "amd-ucode", "arch-audit", "btrfs-progs", "boost", "btop", "chrony", "curl", "cmake", "dosfstools", "dbus-python", "downgrade", "efibootmgr", "fdupes", "fastfetch", "fwupd", "gcc", "grub-btrfs", "haveged", "jq", "jitterentropy-rngd", "linux-firmware", "lynis", "logrotate", "libva", "make", "mesa", "meson", "networkmanager", "openssh", "pacman-contrib", "pkgconf", "plymouth", "plocate", "piavpn", "rng-tools", "sysstat", "snapper", "snap-pac", "snap-pac-grub", "sof-firmware", "smartmontools", "texinfo", "unzip", "unrar", "upower", "wget", "xz", "zip", "zstd"}
    @staticmethod
    def _get_hyprland_packages() -> Set[str]: return {"adw-gtk-theme", "bibata-cursor-theme", "cliphist", "gnome-themes-extra", "greetd", "greetd-tuigreet", "grim", "gstreamer", "gst-plugin-pipewire", "gst-plugins-bad", "gst-plugins-base", "gst-plugins-good", "gst-plugins-ugly", "gtk-engine-murrine", "hypridle", "hyprland", "hyprlock", "hyprnome", "hyprpaper", "hyprpicker", "hyprpolkitagent", "hyprsunset", "inotify-tools", "kvantum", "kvantum-qt5", "mpv", "nwg-drawer", "nwg-look", "papirus-icon-theme", "pavucontrol", "pipewire", "pipewire-alsa", "pipewire-pulse", "pyprland", "qt5-wayland", "qt5ct", "qt6-wayland", "qt6ct", "rofi-wayland", "sassc", "slurp", "swappy", "swww", "socat", "thunar", "thunar-archive-plugin", "thunar-media-tags-plugin", "thunar-volman", "trash-cli", "tumbler", "uwsm", "wf-recorder", "wireplumber", "xarchiver", "xdg-desktop-portal-hyprland", "xdg-user-dirs", "xdg-user-dirs-gtk", "yazi"}
    @staticmethod
    def _get_caelestia_packages() -> Set[str]: return {"caelestia-cli", "quickshell-git", "ddcutil", "brightnessctl", "app2unit", "cava", "bluez-utils", "lm_sensors", "fish", "aubio", "libpipewire", "glibc", "qt6-declarative", "gcc-libs", "power-profiles-daemon", "ttf-material-symbols-variable", "libqalculate"}
    @staticmethod
    def _get_applications() -> Set[str]: return {"zathura", "zathura-pdf-poppler", "zen-browser-bin", "zotero", "deluge-gtk", "bleachbit", "bitwarden", "xournalpp"}
    @staticmethod
    def _get_dev_tools() -> Set[str]: return {"autoconf", "automake", "cargo", "devtools", "direnv", "emacs-lsp-booster-git", "fd", "fzf", "go", "hspell", "nuspell", "libvoikko", "hunspell", "hunspell-en_us", "imagemagick", "jansson", "neovim", "nodejs", "nodejs-neovim", "npm", "org.freedesktop.secrets", "pkg-config", "poppler", "poppler-glib", "python-neovim", "python-pip", "python-pynvim", "ripgrep", "rust", "tree-sitter-cli", "tree-sitter-bash", "tree-sitter-markdown", "tree-sitter-python", "ttf-jetbrains-mono", "ttf-jetbrains-mono-nerd", "ttf-ubuntu-font-family", "typescript", "wl-clipboard", "yarn"}
    @staticmethod
    def _get_cli_tools() -> Set[str]: return {"atuin", "bat", "eza", "starship", "tealdeer", "thefuck", "zoxide", "zsh"}
    @staticmethod
    def _get_graphics_packages() -> Set[str]: return {"ffnvcodec-headers", "libva-nvidia-driver", "linux-cachyos-bore-lto-nvidia-open", "nvidia-container-toolkit", "nvidia-utils", "opencl-nvidia", "vulkan-headers", "vulkan-tools", "vulkan-validation-layers", "xf86-video-amdgpu", "xorg-xwayland"}
    @staticmethod
    def _get_container_packages() -> Set[str]: return {"aardvark-dns", "boxbuddy", "cockpit", "cockpit-packagekit", "cockpit-podman", "distrobox", "lxd", "netavark", "podman", "podman-docker"}
    @staticmethod
    def _get_security_packages() -> Set[str]: return {"git", "git-delta", "git-lfs", "gnome-keyring", "lazygit", "libsecret", "seahorse", "apparmor", "apparmor.d-git", "audit", "python-notify2", "python-psutil"}
    @classmethod
    def get_all(cls) -> List[str]:
        all_packages = set.union(*[
            cls._get_base_packages(), cls._get_hyprland_packages(), cls._get_caelestia_packages(),
            cls._get_applications(), cls._get_dev_tools(), cls._get_cli_tools(),
            cls._get_graphics_packages(), cls._get_container_packages(), cls._get_security_packages()
        ])
        return sorted(list(all_packages))
```

#### `arch_installer/system_config.py`

```python
# arch_installer/system_config.py
import os
import shutil
import subprocess
import tempfile
from typing import List
from .config import CURRENT_USER, DOTFILES_DIR
from .ui import Colors, Icons, print_error, print_info, print_success, print_warning
from .utils import execute_command

def _get_variables_sh_content() -> str:
    return """#!/bin/bash
export EDITOR=${EDITOR:-/usr/bin/emacs}
export PAGER=${PAGER:-/usr/bin/less}
export BROWSER="brave-browser"
export TERMINAL="foot"
export PATH=$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.config/emacs/bin:$HOME/.npm-global/bin:/var/lib/flatpak/exports/bin
if [ -d "/opt/nvidia/hpc_sdk" ]; then
    NVARCH=$(uname -s)_$(uname -m)
    export NVARCH
    NVCOMPILERS=/opt/nvidia/hpc_sdk
    export NVCOMPILERS
    if [ -d "$NVCOMPILERS/$NVARCH/23.9" ]; then
        MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.9/compilers/man
        export MANPATH
        PATH=$NVCOMPILERS/$NVARCH/23.9/compilers/bin:$PATH
        export PATH
        export PATH=$NVCOMPILERS/$NVARCH/23.9/comm_libs/mpi/bin:$PATH
        export MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.9/comm_libs/mpi/man
    fi
fi
"""

def _get_limits_conf_content() -> str:
    return "* soft core 0\n* hard core 0\n* hard nproc 15\n* hard rss 10000\n* - maxlogins 2\n@dev hard core 100000\n@dev soft nproc 20\n@dev hard nproc 35\n@dev - maxlogins 10"

def _get_login_banner_content() -> str:
    return "-- WARNING -- This system is for the use of authorized users only. Individuals using this computer system without authority or in excess of their authority are subject to having all their activities on this system monitored and recorded by system personnel. Anyone using this system expressly consents to such monitoring and is advised that if such monitoring reveals possible evidence of criminal activity system personal may provide the evidence of such monitoring to law enforcement officials."

def _get_sshd_config_content() -> str:
    return "# /etc/ssh/sshd_config\nInclude /etc/ssh/sshd_config.d/*.conf\nPort 43\nLogLevel VERBOSE\nMaxAuthTries 3\nMaxSessions 2\nPubkeyAuthentication yes\nKbdInteractiveAuthentication no\nUsePAM yes\nAllowAgentForwarding no\nAllowTcpForwarding no\nX11Forwarding no\nPrintMotd no\nTCPKeepAlive no\nClientAliveCountMax 2\nAcceptEnv LANG LC_*\nSubsystem sftp /usr/lib/openssh/sftp-server"

def configure_environment_variables() -> bool:
    print_info(f"{Icons.SECURITY} Setting system-wide environment variables.")
    content = _get_variables_sh_content()
    try:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as tmp:
            tmp.write(content); tmp_path = tmp.name
        target = "/etc/profile.d/variables.sh"
        return (execute_command(["sudo", "mv", tmp_path, target], f"Moving script to '{target}'") and
                execute_command(["sudo", "chown", "root:root", target], f"Setting ownership for {target}") and
                execute_command(["sudo", "chmod", "755", target], f"Setting permissions for {target}"))
    except Exception as e: print_error(f"Failed to write environment variables script: {e}"); return False

def configure_security_limits() -> bool:
    print_info(f"{Icons.SECURITY} Setting user resource limits in /etc/security/limits.conf.")
    content = _get_limits_conf_content()
    try:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as tmp:
            tmp.write(content + "\n"); tmp_path = tmp.name
        target = "/etc/security/limits.conf"
        return (execute_command(["sudo", "mv", tmp_path, target], f"Moving config to '{target}'") and
                execute_command(["sudo", "chown", "root:root", target], f"Setting ownership for {target}") and
                execute_command(["sudo", "chmod", "644", target], f"Setting permissions for {target}"))
    except Exception as e: print_error(f"Failed to write security limits: {e}"); return False

def configure_login_banners() -> bool:
    print_info(f"{Icons.SECURITY} Setting security login banner.")
    content = _get_login_banner_content()
    try:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as tmp:
            tmp.write(content.strip() + "\n"); tmp_path = tmp.name
        issue_ok = (execute_command(["sudo", "mv", tmp_path, "/etc/issue"], "Moving banner to '/etc/issue'") and
                    execute_command(["sudo", "chown", "root:root", "/etc/issue"], "Setting ownership") and
                    execute_command(["sudo", "chmod", "644", "/etc/issue"], "Setting permissions"))
        if not issue_ok: return False
        return (execute_command(["sudo", "cp", "/etc/issue", "/etc/issue.net"], "Copying banner to '/etc/issue.net'") and
                execute_command(["sudo", "chown", "root:root", "/etc/issue.net"], "Setting ownership") and
                execute_command(["sudo", "chmod", "644", "/etc/issue.net"], "Setting permissions"))
    except Exception as e: print_error(f"Failed to write login banners: {e}"); return False

def configure_sshd() -> bool:
    print_info(f"{Icons.SECURITY} Applying hardened SSH server configuration.")
    content = _get_sshd_config_content()
    try:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, encoding='utf-8') as tmp:
            tmp.write(content); tmp_path = tmp.name
        target = "/etc/ssh/sshd_config"
        return (execute_command(["sudo", "mv", tmp_path, target], f"Moving config to '{target}'") and
                execute_command(["sudo", "chown", "root:root", target], "Setting ownership") and
                execute_command(["sudo", "chmod", "644", target], "Setting permissions"))
    except Exception as e: print_error(f"Failed to write SSH config: {e}"); return False

def configure_symlinks() -> bool:
    print_info("Creating system-wide symbolic links for custom scripts.")
    base_dir = os.path.join(DOTFILES_DIR, "arch-scripts", "bin")
    if not os.path.isdir(base_dir): print_error(f"Dotfiles script directory not found: {base_dir}"); return False
    success = True
    for script in ["cliphist-rofi", "hyprlauncher", "hyprrunner", "hyprterm", "hyprtheme"]:
        src, dest = os.path.join(base_dir, script), f"/usr/local/bin/{script}"
        if os.path.lexists(dest) or not os.path.exists(src): continue
        if not execute_command(["sudo", "ln", "-s", src, dest], f"Linking '{script}' to '{dest}'"): success = False
    return success

def configure_system_services(extra_services: List[str]) -> bool:
    print_info("Enabling system-wide services.")
    services = {"acpid.service", "apparmor.service", "auditd.service", "chronyd.service", "cockpit.socket", "grub-btrfsd.service", "haveged.service", "lxd.service", "NetworkManager.service", "piavpn.service", "rngd.service", "sshd.service", "sysstat.service", "power-profiles-daemon.service"}
    services.update(extra_services)
    return execute_command(["sudo", "systemctl", "enable"] + sorted(list(services)), "Enabling systemd services.")

def configure_shell() -> bool:
    print_info("Setting Zsh as the default shell.")
    zsh_path = shutil.which("zsh")
    if zsh_path:
        return execute_command(["sudo", "chsh", "-s", zsh_path, CURRENT_USER], f"Changing shell for '{CURRENT_USER}' to Zsh.")
    print_error("Zsh not found, cannot set as default shell."); return False

def cleanup_orphan_packages() -> bool:
    print_info("Checking for orphan packages...")
    try:
        proc = subprocess.run(["pacman", "-Qdtq"], capture_output=True, text=True, check=False)
        if proc.returncode != 0 and not proc.stdout.strip(): print_success("No orphan packages found."); return True
        orphans = [line for line in proc.stdout.strip().split('\n') if line]
        if not orphans: print_success("No orphan packages found."); return True
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        print_error(f"Failed to query orphan packages: {e}"); return False
    print_warning(f"Found {len(orphans)} orphan package(s):")
    for orphan in orphans: print(f"  - {orphan}")
    try:
        prompt = f"{Colors.YELLOW}{Icons.PROMPT} Do you want to remove them? [Y/n]: {Colors.ENDC}"
        if input(prompt).lower().strip() not in ['n', 'no']:
            return execute_command(["sudo", "pacman", "-Rns"] + orphans, "Removing orphan packages.")
        print_info("Skipping removal of orphan packages.")
    except (EOFError, KeyboardInterrupt): print_info("\nSkipping removal of orphan packages.")
    return True
```

#### `arch_installer/user_config.py`

```python
# arch_installer/user_config.py
import os
from .config import USER_HOME
from .ui import Icons, print_info, print_warning
from .utils import execute_command

def configure_caelestia() -> bool:
    print_info(f"{Icons.DESKTOP} Configuring Caelestia Desktop Shell.")
    config_dir = os.path.join(USER_HOME, ".config", "quickshell")
    if not os.path.exists(config_dir):
        if not execute_command(["git", "clone", "https://github.com/caelestia-dots/shell.git", config_dir], "Cloning Caelestia config."):
            return False
    source_file = os.path.join(config_dir, "cxx", "beat_detector.cpp")
    if not os.path.exists(source_file):
        print_warning("Caelestia source not found, skipping compilation."); return True
    output_file = os.path.join(config_dir, "beat_detector")
    cmd = ["g++", "-std=c++17", "-Wall", "-Wextra", "-o", output_file, source_file, "-lpipewire-0.3", "-laubio"]
    if not execute_command(cmd, "Compiling Caelestia utility.", cwd=config_dir): return False
    dest_dir = "/usr/lib/caelestia"
    return (execute_command(["sudo", "mkdir", "-p", dest_dir], f"Creating directory '{dest_dir}'.") and
            execute_command(["sudo", "mv", output_file, os.path.join(dest_dir, 'beat_detector')], "Installing binary."))

def configure_git() -> bool:
    print_info("Configuring global Git settings.")
    configs = [
        (["git", "config", "--global", "user.name", "aahsnr"], "Configuring Git user name."),
        (["git", "config", "--global", "user.email", "ahsanur041@proton.me"], "Configuring Git user email."),
        (["git", "config", "--global", "credential.helper", "/usr/lib/git-core/git-credential-libsecret"], "Configuring Git credential helper.")
    ]
    return all(execute_command(cmd, desc) for cmd, desc in configs)

def configure_npm() -> bool:
    print_info("Configuring NPM global directory.")
    npm_dir = os.path.join(USER_HOME, ".npm-global")
    os.makedirs(npm_dir, exist_ok=True)
    return execute_command(["npm", "config", "set", "prefix", npm_dir], "Setting NPM global prefix.")
```

#### `arch_installer/user_services.py`

```python
# arch_installer/user_services.py
import os
import shutil
from .config import USER_HOME
from .ui import Icons, print_error, print_info
from .utils import execute_command

def _get_pyprland_service_content(exec_path: str) -> str:
    return f"""[Unit]
Description=Pyprland - Hyprland IPC gateway
Documentation=https://github.com/hyprland-community/pyprland
PartOf=graphical-session.target
After=graphical-session.target
[Service]
Type=simple
ExecStart={exec_path}
Restart=on-failure
RestartSec=1
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
NoNewPrivileges=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
ReadWritePaths=%t/hypr
[Install]
WantedBy=graphical-session.target
"""

def _get_cliphist_service_content(exec_start: str, service_type: str) -> str:
    return f"""[Unit]
Description=Clipboard History Manager ({service_type})
Documentation=https://github.com/sentriz/cliphist
PartOf=graphical-session.target
After=graphical-session.target
[Service]
Type=simple
ExecStart={exec_start}
Restart=on-failure
RestartSec=1
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
NoNewPrivileges=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX
ReadWritePaths=%h/.local/share/cliphist/
[Install]
WantedBy=graphical-session.target
"""

def _create_service_file(service_name: str, content: str) -> bool:
    """Helper to write a systemd service file."""
    service_dir = os.path.join(USER_HOME, ".config", "systemd", "user")
    os.makedirs(service_dir, exist_ok=True)
    try:
        with open(os.path.join(service_dir, service_name), "w", encoding="utf-8") as f:
            f.write(content)
        return True
    except IOError as e:
        print_error(f"Failed to write {service_name}: {e}")
        return False

def configure_all_user_services() -> bool:
    """Creates and enables all custom and standard user systemd services."""
    print_step("Configuring User Systemd Services")

    # 1. Create custom service files programmatically
    print_info(f"{Icons.DESKTOP} Creating custom service files.")
    pypr_path = shutil.which("pypr")
    wl_paste_path = shutil.which("wl-paste")
    cliphist_path = shutil.which("cliphist")

    if pypr_path:
        _create_service_file("pyprland.service", _get_pyprland_service_content(pypr_path))
    else: print_error("'pypr' not found, skipping service creation.")

    if wl_paste_path and cliphist_path:
        _create_service_file("cliphist-text.service", _get_cliphist_service_content(f"{wl_paste_path} --watch {cliphist_path} store", "Text"))
        _create_service_file("cliphist-image.service", _get_cliphist_service_content(f"{wl_paste_path} --type image/png --watch {cliphist_path} store", "Image"))
    else: print_error("'wl-paste' or 'cliphist' not found, skipping service creation.")

    # 2. Reload the systemd daemon to recognize the new files
    if not execute_command(["systemctl", "--user", "daemon-reload"], "Reloading user systemd daemon."):
        return False

    # 3. Enable all required user services (both custom and pre-packaged)
    print_info("Enabling user services.")
    services_to_enable = {
        "hypridle.service", "hyprpaper.service", "hyprpolkitagent.service",
        "hyprsunset.service", "pipewire.service", "pipewire.socket",
        "pipewire-pulse.service", "pipewire-pulse.socket", "uwsm.service",
        "wireplumber.service", "pyprland.service", "cliphist-text.service",
        "cliphist-image.service"
    }
    return execute_command(["systemctl", "--user", "enable"] + sorted(list(services_to_enable)), "Enabling all user systemd services.")
```

#### `arch_installer/engine.py`

```python
# arch_installer/engine.py
import os
import shutil
import subprocess
import tempfile
from typing import Tuple
from .config import DOTFILES_DIR, USER_HOME
from .packages import PackageLists
from .ui import Icons, print_error, print_info, print_step, print_success, print_warning
from .utils import check_internet_connection, execute_command

class SetupManager:
    """Orchestrates the main steps of the installation process."""
    def run_pre_cleanup_step(self) -> bool:
        print_step("Running Initial System Audit")
        if not execute_command(["sudo", "pacman", "-S", "--needed", "--noconfirm", "awk"], "Ensuring 'awk' is available."): return False
        try:
            pacman_proc = subprocess.Popen(["pacman", "-Q"], stdout=subprocess.PIPE, text=True)
            awk_proc = subprocess.Popen(["awk", "{print $1}"], stdin=pacman_proc.stdout, stdout=subprocess.PIPE, text=True)
            if pacman_proc.stdout: pacman_proc.stdout.close()
            package_list, _ = awk_proc.communicate()
            if awk_proc.returncode != 0: raise subprocess.CalledProcessError(awk_proc.returncode, "awk")
            output_file_path = os.path.join(USER_HOME, "pre-cleaned.txt")
            with open(output_file_path, "w", encoding="utf-8") as f: f.write(package_list)
            print_success(f"Saved initial package list to '{output_file_path}'")
            return True
        except (IOError, FileNotFoundError, subprocess.CalledProcessError) as e:
            print_error(f"Failed to audit packages: {e}"); return False

    def run_bootstrap_checks(self, dotfiles_url: str) -> bool:
        print_step("Running Bootstrap Checks")
        checks = { "Must not be run as root": lambda: os.geteuid() != 0, "Internet connection available": check_internet_connection, "`git` command installed": lambda: shutil.which("git") is not None }
        if dotfiles_url.startswith("git@"):
            print_info("SSH URL detected. Will check for SSH client.")
            checks["`ssh` command for SSH cloning"] = lambda: shutil.which("ssh") is not None
        for desc, check_func in checks.items():
            if not check_func(): print_error(f"Bootstrap check failed: {desc}."); return False
            print_success(f"{desc}: OK")
        if dotfiles_url.startswith("git@"): print_warning("Ensure your SSH keys are configured correctly to clone via SSH.")
        if os.path.isdir(DOTFILES_DIR): print_warning(f"Dotfiles directory '{DOTFILES_DIR}' exists. Skipping clone.")
        elif not execute_command(["git", "clone", dotfiles_url, DOTFILES_DIR], "Cloning dotfiles repository."): return False
        return True

    def ensure_yay_installed(self) -> bool:
        if shutil.which("yay"): print_success("'yay' is already installed."); return True
        print_step(f"{Icons.PACKAGE} Installing AUR Helper (yay)")
        if not execute_command(["sudo", "pacman", "-S", "--needed", "--noconfirm", "base-devel", "git"], "Installing build dependencies."): return False
        with tempfile.TemporaryDirectory() as tmpdir:
            if not execute_command(["git", "clone", "https://aur.archlinux.org/yay-bin.git", tmpdir], "Cloning 'yay-bin' repo."): return False
            if not execute_command(["makepkg", "-si", "--noconfirm"], "Building and installing 'yay'.", cwd=tmpdir): return False
        if shutil.which("yay"): print_success("'yay' has been successfully installed."); return True
        print_error("Installation failed. 'yay' command not found."); return False

    def run_package_installation(self, extra_packages: list) -> bool:
        print_step("Installing System Packages")
        packages_to_install = PackageLists.get_all()
        if extra_packages: packages_to_install = sorted(list(set(packages_to_install).union(extra_packages)))
        print_info(f"Found {len(packages_to_install)} unique packages to install.")
        return execute_command(["yay", "-S", "--needed", "--noconfirm"] + packages_to_install, "Installing all packages.")

    def prompt_for_asus_setup(self) -> Tuple[list, list]:
        print_step("Asus ROG Laptop Configuration (Optional)")
        prompt = f"{Icons.PROMPT} Run Asus-specific setup (G14/ROG)? [y/N]: "
        try:
            if input(prompt).lower().strip() != "y": print_info("Skipping Asus setup."); return [], []
        except (EOFError, KeyboardInterrupt): print_info("\nSkipping Asus setup."); return [], []
        print_info("Proceeding with Asus setup...")
        key_id = "8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"
        if not execute_command(["sudo", "pacman-key", "--recv-keys", key_id], "Receiving g14 repo key.") or \
           not execute_command(["sudo", "pacman-key", "--lsign-key", key_id], "Signing g14 repo key."): return [], []
        try:
            with open("/etc/pacman.conf", "r+", encoding="utf-8") as f:
                if "[g14]" not in f.read(): f.write("\n[g14]\nServer = https://arch.asus-linux.org\n"); print_success("Added [g14] repo.")
        except IOError as e: print_error(f"Could not access /etc/pacman.conf: {e}"); return [],[]
        execute_command(["sudo", "pacman", "-Syyu"], "Synchronizing package databases.")
        return ["asusctl", "supergfxctl", "rog-control-center"], ["supergfxd.service", "switcheroo-control.service"]
```

#### `arch_installer/install.py`

```python
# arch_installer/install.py
import argparse
import sys
import os
from .config import CURRENT_USER, USER_HOME, DOTFILES_DIR
from .engine import SetupManager
from .ui import Colors, Icons, print_error, print_info, print_step, print_success, print_warning, setup_logging
from .utils import execute_command
from . import system_config, user_config, user_services

def print_summary_and_confirm(dotfiles_url: str):
    print_step("Installation Plan Summary")
    summary = f"""
This script will perform a full installation, including the following actions:
{Colors.HEADER}1. System Audit & Bootstrap:{Colors.ENDC}
   - Save a list of current packages, run pre-flight checks, and clone dotfiles from:
     {Colors.BLUE}{dotfiles_url}{Colors.ENDC}
{Colors.HEADER}2. Core Installation & Configuration:{Colors.ENDC}
   - Install 'yay' (AUR Helper) and a large set of system packages.
   - {Icons.SECURITY} Set system-wide environment variables, resource limits, login banners, and a hardened SSH config.
   - Configure and enable essential system services.
   - Set up Git, NPM, and Zsh as the default shell for '{CURRENT_USER}'.
   - {Icons.DESKTOP} Create and enable secure user systemd services for pyprland, cliphist, and more.
{Colors.HEADER}3. Hardware-Specific Setup:{Colors.ENDC}
   - You will be prompted to run an {Colors.YELLOW}optional{Colors.ENDC} setup for Asus ROG laptops.
{Colors.HEADER}4. Final Cleanup:{Colors.ENDC}
   - After installation, you will be prompted to remove any unnecessary 'orphan' packages.
{Colors.YELLOW}{Icons.WARNING} This will make significant changes to your system and requires sudo.{Colors.ENDC}
"""
    print(summary)
    try:
        prompt = f"{Colors.YELLOW}{Icons.PROMPT} Do you want to proceed? [Y/n]: {Colors.ENDC}"
        if input(prompt).lower().strip() in ['n', 'no']:
            print_info("Aborting at user request."); sys.exit(0)
    except (EOFError, KeyboardInterrupt):
        print_info("\nNo input received. Aborting."); sys.exit(0)

def main() -> None:
    parser = argparse.ArgumentParser(description="A modular installer for a personalized Arch Linux setup.", epilog="If no flags are provided, a full installation is attempted, which requires --dotfiles-url.")
    parser.add_argument("--dotfiles-url", help="HTTPS or SSH URL of the dotfiles repository.")
    parser.add_argument("--bootstrap", action="store_true", help="Run pre-flight checks and clone dotfiles.")
    parser.add_argument("--install-packages", action="store_true", help="Install yay and all system packages.")
    parser.add_argument("--configure-system", action="store_true", help="Apply all system-wide configurations.")
    parser.add_argument("--configure-user", action="store_true", help="Apply all user-specific configurations.")
    parser.add_argument("--cleanup", action="store_true", help="Remove orphan packages.")
    args = parser.parse_args()

    setup_logging()
    print(f"{Colors.BOLD}--- Arch Linux Setup Script (Modular Version) ---{Colors.ENDC}")

    manager = SetupManager()
    failed_tasks = []

    task_flags_provided = any([args.bootstrap, args.install_packages, args.configure_system, args.configure_user, args.cleanup])

    if not task_flags_provided:
        if not args.dotfiles_url: parser.error("The --dotfiles-url argument is required for a full installation.")
        print_summary_and_confirm(args.dotfiles_url)

        if not manager.run_pre_cleanup_step() or not manager.run_bootstrap_checks(args.dotfiles_url):
            print_error("Preliminary checks failed. Aborting."); sys.exit(1)

        print_step("Acquiring Administrator Privileges")
        if not execute_command(["sudo", "-v"], "Caching sudo credentials."):
            print_error("Could not acquire sudo privileges. Aborting."); sys.exit(1)

        if not manager.ensure_yay_installed(): print_error("'yay' installation failed. Aborting."); sys.exit(1)

        asus_packages, asus_services = manager.prompt_for_asus_setup()
        if not manager.run_package_installation(asus_packages): print_error("Package installation failed. Aborting."); sys.exit(1)

        for config_func, name in [
            (system_config.configure_environment_variables, "Set environment variables"),
            (system_config.configure_security_limits, "Set security limits"),
            (system_config.configure_login_banners, "Set login banners"),
            (system_config.configure_sshd, "Configure SSH daemon"),
            (system_config.configure_symlinks, "Create system symlinks"),
            (lambda: system_config.configure_system_services(asus_services), "Enable system services"),
            (system_config.configure_shell, "Change default shell"),
            (user_config.configure_caelestia, "Configure Caelestia"),
            (user_services.configure_all_user_services, "Configure user services"),
            (user_config.configure_git, "Configure Git"),
            (user_config.configure_npm, "Configure NPM")
        ]:
            if not config_func(): failed_tasks.append(name)

        if not system_config.cleanup_orphan_packages(): failed_tasks.append("Clean up orphan packages")
    else:
        if any([args.install_packages, args.configure_system, args.cleanup, args.configure_user]):
            print_step("Acquiring Administrator Privileges")
            if not execute_command(["sudo", "-v"], "Caching sudo credentials for requested tasks."):
                print_error("Could not acquire sudo privileges. Aborting."); sys.exit(1)

        if args.bootstrap:
            if not args.dotfiles_url: parser.error("--bootstrap requires --dotfiles-url.")
            if not manager.run_bootstrap_checks(args.dotfiles_url): failed_tasks.append("Bootstrap")

        if args.install_packages:
            if manager.ensure_yay_installed():
                asus_pkgs, _ = manager.prompt_for_asus_setup()
                if not manager.run_package_installation(asus_pkgs): failed_tasks.append("Package Installation")
            else: failed_tasks.append("Install yay")

        if args.configure_system:
            print_step("Applying System-Wide Configurations")
            if not os.path.isdir(DOTFILES_DIR): print_warning("Dotfiles directory not found. Some configs may fail.")
            for func, name in [(system_config.configure_environment_variables, "Set environment variables"), (system_config.configure_security_limits, "Set security limits"), (system_config.configure_login_banners, "Set login banners"), (system_config.configure_sshd, "Configure SSH daemon"), (system_config.configure_symlinks, "Create system symlinks"), (lambda: system_config.configure_system_services([]), "Enable system services"), (system_config.configure_shell, "Change default shell")]:
                if not func(): failed_tasks.append(name)

        if args.configure_user:
            print_step("Applying User-Specific Configurations")
            if not os.path.isdir(DOTFILES_DIR): print_warning("Dotfiles directory not found. Some configs may fail.")
            for func, name in [(user_config.configure_caelestia, "Configure Caelestia"), (user_services.configure_all_user_services, "Configure user services"), (user_config.configure_git, "Configure Git"), (user_config.configure_npm, "Configure NPM")]:
                if not func(): failed_tasks.append(name)

        if args.cleanup:
            print_step("Running Final System Cleanup")
            if not system_config.cleanup_orphan_packages(): failed_tasks.append("Clean up orphan packages")

    print_step(f"{Icons.FINISH} Run Complete!")
    if not failed_tasks:
        print_success("All requested tasks finished successfully!")
    else:
        print_warning(f"Process finished with {len(failed_tasks)} error(s):")
        for failure in failed_tasks: print(f"  - {failure}")
        print_warning("Please review the output and the log file for details."); sys.exit(1)

    print(f"\n{Colors.BLUE}{Icons.INFO} A reboot may be needed to apply all changes.{Colors.ENDC}")
    sys.exit(0)

if __name__ == "__main__":
    main()
```
