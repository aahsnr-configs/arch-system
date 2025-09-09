# TODO

- [ ] Add _app2unit-git_ to source installer
- [ ] Add _determinate_nix_ setup

Of course. I have added a new section that explicitly describes what the program does, placing it right after the features list for clarity. The rest of the enhanced, debug-ready, and object-oriented code remains the same.

Here is the updated and rewritten markdown file.

### **Program Features and Qualities**

This Python application is an automated, idempotent, and highly modular installer for a complete Fedora Hyprland desktop environment. It is engineered with the following key features and qualities:

**Automation & User Experience**

- **Fully Automated ("Fire-and-Forget") Mode:** Executes the entire installation, including a mandatory system reboot, without any further user interaction.
- **Automatic Reboot & Resume:** Intelligently saves its state before a reboot and uses a temporary `systemd` service to resume the process automatically, ensuring a seamless experience.
- **Modular Manual Control:** Allows any individual step or group of steps to be run via command-line flags, disabling the automatic reboot for granular control and testing.
- **Idempotent by Design:** Core operations can be run multiple times without negative side effects; the script will skip tasks that are already completed.
- **Interactive Confirmation:** Prompts the user with a clear execution plan before starting the fully automated process to prevent accidental runs.

**Architectural Qualities**

- **Object-Oriented, Task-Based Engine:** The installer is built on a robust OO architecture where each step is an encapsulated `Task` object. This makes the system highly scalable, maintainable, and easy to read.
- **Centralized Configuration:** All key variables, paths, and URLs are stored in a single `config.py` file for easy modification.
- **Declarative Workflow:** The main engine defines the installation as simple lists of task objects, making the entire workflow transparent and easy to modify.
- **High Testability:** The task-based design allows for individual components to be unit-tested in isolation, ensuring reliability.

**Debugging & Reliability**

- **Enhanced Debug Mode:** A `--debug` flag enables verbose `DEBUG` level logging to both the console and the log file, providing deep insight into the script's execution.
- **Comprehensive Logging:** All actions, command outputs, and errors are automatically logged to `fedora_setup.log`.
- **Robust Error Handling:** Captures and logs detailed `stdout` and `stderr` from failed shell commands and gracefully handles unexpected Python exceptions, preventing crashes and providing clear diagnostics.
- **Pre-flight Checks:** Verifies essential conditions like root privileges and internet connectivity before making any system changes.
- **Dry Run Simulation:** A `--dry-run` flag simulates the entire installation process, including the reboot-resume cycle, without making a single change to the system.

### **What This Program Does**

The primary purpose of this application is to completely automate the post-installation setup of a Fedora Linux system, transforming a minimal installation into a fully configured and personalized desktop environment centered around the Hyprland window manager.

The script performs a series of opinionated setup tasks in a structured order:

1. **System Preparation:** It begins by optimizing the DNF package manager and enabling crucial third-party repositories like RPM Fusion and various COPRs to access a wider range of software.
2. **Core Installation:** It installs a comprehensive list of system packages, including drivers (with special handling for NVIDIA), development tools, command-line utilities, and desktop applications. It also sets up Flatpak and installs a curated list of Flatpak applications.
3. **Build from Source:** It automatically downloads, builds, and installs specific software from source code, such as `grub-btrfs` for Btrfs snapshot integration and `materialyoucolor` for theming.
4. **Security Hardening:** It applies several system-wide security enhancements, such as hardening the SSH server, setting secure resource limits, and configuring a login banner.
5. **User Environment Setup:** It configures the user's environment by cloning a specific set of dotfiles for Hyprland, setting Zsh as the default shell, and configuring tools like Git and NPM.
6. **Desktop Service Integration:** Finally, it creates and enables the necessary `systemd` user services to ensure all components of the Hyprland desktop (like the status bar, notification daemon, and clipboard manager) start correctly on login.

By automating these steps, the script provides a repeatable, consistent, and efficient way to deploy a sophisticated desktop environment from scratch.

---

### **How to Use the Application**

The usage is unchanged.

1. **Prerequisites**: Ensure `python3.13` and `git` are available.

    ```bash
    sudo dnf install -y python3 git
    ```

2. **Download**: Create a `fedora_installer` directory and save all the Python files listed below inside it.

3. **Run the Script**: From the directory _containing_ the `fedora_installer` package, execute with `sudo`.
    - **Fully Automated Installation (Recommended):**
      This single command will start the process, automatically reboot, and continue until everything is finished.

      ```bash
      sudo python3.13 -m fedora_installer.install
      ```

    - **Verify with a Dry Run (Highly Recommended First Step):**
      Simulate the entire automated process, including the reboot and resume steps.

      ```bash
      sudo python3.13 -m fedora_installer.install --dry-run
      ```

    - **Enable Verbose Debugging:**
      For detailed insight, run any command with the `--debug` flag.

      ```bash
      sudo python3.13 -m fedora_installer.install --debug
      ```

    - **Running Specific Tasks (Manual Mode):**
      All flags still work independently for manual control without automatic reboots.

      ```bash
      # Example: Harden the system and then clean up packages
      sudo python3.13 -m fedora_installer.install --harden-system --cleanup
      ```

---

### **Project Structure**

The project structure is organized around a `tasks` package, promoting modularity and clean separation of concerns.

```
.
└── fedora_installer/
    ├── __init__.py
    ├── config.py
    ├── ui.py
    ├── utils.py
    ├── packages.py
    ├── tasks/
    │   ├── __init__.py
    │   ├── base_task.py
    │   ├── system_tasks.py
    │   ├── user_tasks.py
    │   ├── source_tasks.py
    │   ├── hardening_tasks.py
    │   └── desktop_tasks.py
    ├── resume_manager.py
    ├── engine.py
    └── install.py
```

---

### **The Python Application Files**

#### `fedora_installer/__init__.py`

```python
# fedora_installer/__init__.py
# This file intentionally left blank to mark the directory as a Python package.
```

#### `fedora_installer/config.py`

```python
# fedora_installer/config.py
"""
Centralized configuration for the Fedora setup script.
All paths, URLs, and key identifiers are defined here.
"""
import os
from pathlib import Path

# --- Core Paths and Files ---
LOG_FILE: Path = Path("fedora_setup.log")
STATE_FILE: Path = Path("/var/tmp/fedora_installer.state")
TEMP_BUILD_DIR: Path = Path("/tmp/fedora_installer_builds")

# --- User Information ---
# This relies on 'sudo' to set the SUDO_USER environment variable.
# The pre-flight check in the engine will fail if this is not set correctly.
SUDO_USER: str = os.environ.get("SUDO_USER", "root")
USER_HOME: Path = Path(f"/home/{SUDO_USER}")

# --- Repository URLs ---
RPMFUSION_FREE_URL = "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
RPMFUSION_NONFREE_URL = "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
DOTFILES_REPO_URL = "https://github.com/aahsnr/.hyprdots.git"
DOTFILES_DIR: Path = USER_HOME / ".hyprdots"

# --- Source Build URLs ---
GRUB_BTRFS_REPO_URL = "https://github.com/Antynea/grub-btrfs.git"
MATERIALYOUCOLOR_REPO_URL = "https://github.com/T-Dynamos/materialyoucolor-python.git"
CAELESTIA_CLI_REPO_URL = "https://github.com/caelestia-dots/cli.git"
CAELESTIA_SHELL_REPO_URL = "https://github.com/caelestia-dots/shell.git"
```

#### `fedora_installer/ui.py`

```python
# fedora_installer/ui.py
"""
Handles all user interface elements, including colored printing and logging setup.
"""
import logging
import sys

class Colors:
    HEADER, BLUE, GREEN, YELLOW, RED, ENDC, BOLD = "\033[95m", "\033[94m", "\033[92m", "\033[93m", "\033[91m", "\033[0m", "\033[1m"

class Icons:
    STEP, INFO, SUCCESS, WARNING, ERROR, PROMPT, FINISH, PACKAGE, DESKTOP, SECURITY, HARDWARE, DEBUG, BUILD, REBOOT = "⚙️", "ℹ️", "✅", "⚠️", "❌", "❓", "🎉", "📦", "🖥️", "🛡️", "🔩", "🐞", "🛠️", "🔄"

def setup_logging(debug: bool = False) -> None:
    """Configures logging to file and optionally to console for debug mode."""
    log_level = logging.DEBUG if debug else logging.INFO
    log_format = logging.Formatter("%(asctime)s [%(levelname)-8s] %(message)s")

    # File handler (always active)
    file_handler = logging.FileHandler("fedora_setup.log", mode="w", encoding="utf-8")
    file_handler.setFormatter(log_format)

    handlers = [file_handler]

    if debug:
        # Console handler (for debug mode)
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(log_format)
        handlers.append(console_handler)
        print(f"{Colors.YELLOW}{Icons.DEBUG} Debug mode enabled. Verbose logging is active.{Colors.ENDC}")

    logging.basicConfig(level=log_level, handlers=handlers)

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

def print_error(message: str, fatal: bool = False) -> None:
    print(f"{Colors.RED}{Icons.ERROR} {message}{Colors.ENDC}", file=sys.stderr)
    logging.error(message)
    if fatal:
        sys.exit(1)

def print_dry_run(message: str) -> None:
    print(f"{Colors.YELLOW}{Icons.DEBUG} [DRY RUN] {message}{Colors.ENDC}")
    logging.info(f"[DRY RUN] {message}")
```

#### `fedora_installer/utils.py`

```python
# fedora_installer/utils.py
"""
Core utility functions for executing commands, checking system state, and file operations.
"""
import logging
import socket
import subprocess
import shutil
from pathlib import Path
from .ui import print_info, print_error, print_dry_run

def execute_command(command: list[str], description: str, as_user: str | None = None, cwd: Path | None = None, dry_run: bool = False) -> bool:
    """Executes a shell command with robust logging and error handling."""
    if as_user:
        command = ["sudo", "-u", as_user] + command

    cmd_str = ' '.join(command)
    print_info(description)
    logging.debug(f"Executing command: {cmd_str} in CWD: {cwd or Path.cwd()}")

    if dry_run:
        print_dry_run(f"Would execute: {cmd_str}")
        return True

    try:
        process = subprocess.run(
            command, check=True, text=True, capture_output=True, encoding="utf-8", cwd=cwd
        )
        logging.debug(f"Command successful: {cmd_str}\nSTDOUT:\n{process.stdout.strip()}")
        return True
    except FileNotFoundError:
        print_error(f"Command not found: {command[0]}.")
        logging.error(f"Failed to execute command because '{command[0]}' was not found.")
        return False
    except subprocess.CalledProcessError as e:
        error_message = f"Command failed with exit code {e.returncode}: {cmd_str}"
        logging.error(f"{error_message}\nSTDOUT:\n{e.stdout.strip()}\nSTDERR:\n{e.stderr.strip()}")
        print_error(f"{error_message}\nError details logged to fedora_setup.log.")
        return False
    except Exception as e:
        print_error(f"An unexpected Python error occurred while running '{cmd_str}': {e}")
        logging.exception(f"Unexpected exception caught while running command: {cmd_str}")
        return False

def check_internet_connection() -> bool:
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=5)
        logging.debug("Internet connection check to 8.8.8.8:53 successful.")
        return True
    except OSError:
        logging.error("Internet connection check failed.")
        return False

def is_package_installed(package_name: str) -> bool:
    try:
        subprocess.run(["rpm", "-q", package_name], check=True, capture_output=True)
        logging.debug(f"Package '{package_name}' is installed.")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        logging.debug(f"Package '{package_name}' is not installed.")
        return False

def binary_exists(name: str) -> bool:
    exists = shutil.which(name) is not None
    logging.debug(f"Checking for binary '{name}': {'Found' if exists else 'Not found'}.")
    return exists

def is_copr_enabled(repo_name: str) -> bool:
    try:
        result = subprocess.run(["dnf", "repolist", "enabled"], check=True, capture_output=True, text=True)
        return repo_name in result.stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def write_file_idempotent(path: Path, content: str, dry_run: bool = False) -> bool:
    logging.debug(f"Checking idempotency for file: {path}")
    if path.exists() and path.read_text(encoding="utf-8") == content:
        print_info(f"Configuration file {path} is already up to date.")
        return True

    logging.debug(f"Content for {path} is new or has changed.")
    if dry_run:
        print_dry_run(f"Would write {len(content)} bytes to {path}.")
        logging.debug(f"[DRY RUN] File content for {path}:\n{content}")
        return True
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        logging.info(f"Successfully wrote configuration to {path}.")
        return True
    except IOError as e:
        print_error(f"Failed to write to file {path}: {e}")
        logging.exception(f"IOError while writing to {path}")
        return False
```

#### `fedora_installer/packages.py`

```python
# fedora_installer/packages.py
"""
This module centralizes all package lists for DNF, COPR, and Flatpak.
"""
from typing import List, Dict, Set

class PackageLists:
    """Provides categorized lists of packages for installation."""

    COPR_REPOS: Dict[str, str] = {
        "hyprland": "solopasha/hyprland", "zen-browser": "sneexy/zen-browser",
        "asus-linux": "lukenukem/asus-linux", "protonplus": "wehagy/protonplus",
        "lazygit": "dejan/lazygit", "starship": "atim/starship",
    }

    FLATPAK_APPS: List[str] = [
        "com.ticktick.TickTick", "org.onlyoffice.desktopeditors", "com.github.tchx84.Flatseal",
        "org.js.nuclear.Nuclear", "tv.kodi.Kodi", "com.bitwarden.desktop",
        "io.github.alainm23.planify", "com.ranfdev.DistroShelf", "com.dec05eba.gpu_screen_recorder",
    ]

    @staticmethod
    def _get_core_system() -> Set[str]:
        return {
            "acpid", "alsa-sof-firmware", "amd-gpu-firmware", "btrfs-progs", "chrony",
            "curl", "dnf-automatic", "dnf-plugins-core", "dnf-utils", "efibootmgr", "fwupd",
            "haveged", "intel-audio-firmware", "intel-gpu-firmware",
            "intel-vsc-firmware", "iwlwifi-dvm-firmware", "iwlwifi-mvm-firmware",
            "kernel", "kernel-core", "kernel-devel", "kernel-devel-matched", "kernel-headers",
            "kernel-modules", "kernel-modules-core", "kernel-modules-extra", "kmodtool",
            "lm_sensors", "mokutil", "NetworkManager-tui", "openssh", "plymouth",
            "plymouth-system-theme", "plymouth-theme-spinner", "power-profiles-daemon",
            "realtek-firmware", "rng-tools", "sysstat", "system-config-language", "tar",
            "usb_modeswitch", "bluez", "bluez-utils"
        }

    @staticmethod
    def _get_hyprland_desktop() -> Set[str]:
        return {
            "cliphist", "greetd", "grim", "hyprcursor", "hypridle", "hyprland",
            "hyprland-contrib", "hyprnome", "hyprpaper", "hyprpicker", "pyprland",
            "rofi-wayland", "slurp", "swappy", "swww", "tuigreet", "uwsm", "wf-recorder",
            "wl-clipboard", "xdg-desktop-portal-gnome", "xdg-desktop-portal-gtk",
            "xdg-desktop-portal-hyprland", "xorg-x11-server-Xwayland", "fuzzel"
        }

    @staticmethod
    def _get_desktop_apps_and_theming() -> Set[str]:
        return {
            "adw-gtk3-theme", "bibata-cursor-theme", "bleachbit", "deluge", "file-roller", "quickshell-git",
            "gnome-software", "imv", "kitty", "kvantum", "kvantum-qt5", "matugen", "maxima",
            "nwg-look", "papirus-icon-theme", "pavucontrol", "qt5ct", "qt6ct", "thunar",
            "thunar-archive-plugin", "thunar-media-tags-plugin", "thunar-volman", "tumbler",
            "transmission-qt", "wxMaxima", "xcur2png", "xournalpp", "zathura", "zathura-cb",
            "zathura-djvu", "zathura-pdf-poppler", "zathura-plugins-all", "zathura-ps", "zen-browser"
        }

    @staticmethod
    def _get_development_tools() -> Set[str]:
        return {
            "autoconf", "automake", "bison", "byacc", "cargo", "ccache", "cmake", "cscope", "ctags",
            "diffstat", "direnv", "emacs", "flex", "gcc", "gcc-c++", "git-delta", "git-lfs",
            "gmock", "gtest", "golang", "hatch", "koji", "lazygit", "libtool", "libvterm-devel", "make", "meson",
            "mock", "neovim", "nodejs", "npm", "openssl", "patchutils", "pkgconf", "python3-build",
            "python3-devel", "python3-installer", "python3-neovim", "python3-pip",
            "redhat-rpm-config", "rpm-build", "rpmdevtools", "rust", "tree-sitter-cli", "valgrind",
            "yarnpkg"
        }

    @staticmethod
    def _get_cli_utilities() -> Set[str]:
        return {
            "atuin", "brightnessctl", "btop", "cava", "ddcutil", "eza", "fastfetch",
            "fd-find", "fdupes", "file", "fish", "fzf", "jq", "less", "man-db", "man-pages",
            "procs", "ripgrep", "socat", "starship", "tealdeer", "the-fuck", "tmux", "trash-cli",
            "tree", "units", "unrar", "unzip", "wget", "xz", "zip", "zoxide", "zsh", "zstd"
        }

    @staticmethod
    def _get_media_and_graphics() -> Set[str]:
        return {
            "akmod-nvidia", "ffmpegthumbnailer", "glx-utils", "libavif", "libheif", "libva-utils",
            "libva-vdpau-driver", "libwebp", "mesa-vulkan-drivers", "nvidia-gpu-firmware",
            "nvtop", "pipewire", "pipewire-utils", "switcheroo-control", "vulkan-tools",
            "wireplumber", "xorg-x11-drv-nvidia-cuda", "xorg-x11-drv-nvidia-cuda-libs",
            "p7zip", "p7zip-plugins"
        }

    @staticmethod
    def _get_security_and_system_admin() -> Set[str]:
        return {
            "aide", "apparmor", "arpwatch", "audit", "checkpolicy", "copr-selinux", "cronie",
            "dkms", "exiftool", "fail2ban", "git-credential-libsecret", "gnome-keyring",
            "libsemanage", "libsepol", "libsepol-utils", "ltrace", "lynis", "mcstrans", "libsecret",
            "PackageKit-command-not-found", "perf", "podman", "policycoreutils", "policycoreutils-dbus",
            "policycoreutils-gui", "policycoreutils-python-utils", "policycoreutils-restorecond",
            "policycoreutils-sandbox", "poppler-utils", "powertop", "psacct", "seahorse", "secilc",
            "selint", "selinux-policy", "selinux-policy-sandbox", "selinux-policy-targeted",
            "sepolicy_analysis", "setools", "setools-console", "setools-gui", "setroubleshoot",
            "setroubleshoot-server", "snapper", "strace", "systemtap", "udica"
        }

    @staticmethod
    def _get_virtualization_and_containers() -> Set[str]:
        return {"distrobox", "lxc", "toolbox"}

    @staticmethod
    def _get_documentation_and_tex() -> Set[str]:
        return {
            "docbook-slides", "docbook-style-dsssl", "docbook-style-xsl", "docbook-utils",
            "docbook-utils-pdf", "docbook5-schemas", "docbook5-style-xsl", "doxygen",
            "groff-base", "linuxdoc-tools", "pandoc", "secilc-doc", "selinux-policy-doc",
            "texlive-scheme-basic", "xhtml1-dtds", "xmlto"
        }

    @staticmethod
    def _get_build_dependencies() -> Set[str]:
        return {
            "abseil-cpp-devel", "abseil-cpp-testing", "aquamarine-devel", "cairo-devel",
            "glaze-devel", "gsl-devel", "gtk-layer-shell-devel", "gtk3-devel", "hyprland-devel",
            "hyprlang", "hwdata-devel", "libavdevice-free-devel", "libavfilter-free-devel",
            "libavformat-free-devel", "libavutil-free-devel", "libdisplay-info-devel",
            "libdrm-devel", "libglvnd-devel", "libinput-devel", "libliftoff-devel",
            "libnotify-devel", "libpciaccess-devel", "libseat-devel", "libxcb-devel",
            "mesa-libgbm-devel", "policycoreutils-devel", "re2-devel", "selinux-policy-devel",
            "tomlplusplus-devel", "wayland-protocols-devel", "xcb-util-devel",
            "xcb-util-errors-devel", "xcb-util-renderutil-devel", "xcb-util-wm-devel",
            "xorg-x11-server-Xwayland-devel", "xisxwayland", "gsl", "glib2"
        }

    @classmethod
    def get_all_dnf(cls) -> List[str]:
        """Returns a sorted, unique list of all DNF packages from all categories."""
        all_packages = set.union(*[
            cls._get_core_system(), cls._get_hyprland_desktop(), cls._get_desktop_apps_and_theming(),
            cls._get_development_tools(), cls._get_cli_utilities(), cls._get_media_and_graphics(),
            cls._get_security_and_system_admin(), cls._get_virtualization_and_containers(),
            cls._get_documentation_and_tex(), cls._get_build_dependencies()
        ])
        return sorted(list(all_packages))
```

#### `fedora_installer/tasks/base_task.py`

```python
# fedora_installer/tasks/base_task.py
"""
Defines the abstract base class for all installer tasks.
"""
from abc import ABC, abstractmethod

class Task(ABC):
    """Abstract base class for a single, idempotent installation task."""
    def __init__(self, name: str, description: str):
        """
        Initializes a task.
        :param name: The unique name for state management (e.g., "Install DNF Packages").
        :param description: A user-facing description of what the task does.
        """
        self.name = name
        self.description = description

    @abstractmethod
    def execute(self, context: dict) -> bool:
        """
        Executes the task's primary logic.
        :param context: A dictionary containing shared state, like 'dry_run'.
        :return: True if the task was successful or already complete, False otherwise.
        """
        pass
```

#### `fedora_installer/tasks/system_tasks.py`

```python
# fedora_installer/tasks/system_tasks.py
"""
Contains all tasks related to system-wide package and repository management.
"""
import logging
from pathlib import Path
from .base_task import Task
from .. import utils, ui, packages, config

class ConfigureDnfTask(Task):
    """Configures DNF for optimal performance."""
    def __init__(self):
        super().__init__("Configure DNF", "Configuring DNF for optimal performance.")

    def execute(self, context: dict) -> bool:
        dnf_config_content = (
            "[main]\n"
            "gpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\n"
            "best=False\nskip_if_unavailable=True\nfastestmirror=True\n"
            "max_parallel_downloads=10\ndefaultyes=True\n"
        )
        path = Path("/etc/dnf/dnf.conf")
        return utils.write_file_idempotent(path, dnf_config_content, context.get('dry_run', False))

class SetupRepositoriesTask(Task):
    """Sets up RPM Fusion and all COPR repositories."""
    def __init__(self):
        super().__init__("Setup External Repositories", "Setting up external repositories (RPM Fusion, COPR).")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        all_success = True
        if not utils.is_package_installed("rpmfusion-free-release"):
            if not utils.execute_command(["dnf", "install", "-y", config.RPMFUSION_FREE_URL], "Installing RPM Fusion Free.", dry_run=dry_run): all_success = False
        else: ui.print_success("RPM Fusion Free is already installed.")
        if not utils.is_package_installed("rpmfusion-nonfree-release"):
            if not utils.execute_command(["dnf", "install", "-y", config.RPMFUSION_NONFREE_URL], "Installing RPM Fusion Non-Free.", dry_run=dry_run): all_success = False
        else: ui.print_success("RPM Fusion Non-Free is already installed.")
        for name, repo in packages.PackageLists.COPR_REPOS.items():
            if not utils.is_copr_enabled(name):
                if not utils.execute_command(["dnf", "copr", "enable", "-y", repo], f"Enabling COPR repository: {repo}", dry_run=dry_run): all_success = False
            else: ui.print_success(f"COPR repository '{repo}' is already enabled.")
        return all_success

class InstallDnfPackagesTask(Task):
    """Installs all categorized DNF packages."""
    def __init__(self):
        super().__init__("Install DNF Packages", "Installing all system packages via DNF.")

    def execute(self, context: dict) -> bool:
        package_list = packages.PackageLists.get_all_dnf()
        logging.debug(f"List of {len(package_list)} DNF packages to install: {package_list}")
        return utils.execute_command(["dnf", "install", "-y"] + package_list, f"Preparing to install {len(package_list)} DNF packages.", dry_run=context.get('dry_run', False))

class ConfigureNvidiaTask(Task):
    """Applies NVIDIA-specific driver configurations."""
    def __init__(self):
        super().__init__("Configure NVIDIA Drivers", "Applying NVIDIA-specific configurations.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        if not utils.is_package_installed("akmod-nvidia"):
            ui.print_warning("NVIDIA drivers not found. Skipping NVIDIA configuration.")
            return True
        services = ["nvidia-suspend.service", "nvidia-resume.service", "nvidia-hibernate.service"]
        if not utils.execute_command(["systemctl", "enable"] + services, "Enabling NVIDIA power management services.", dry_run=dry_run): return False
        if not utils.execute_command(["systemctl", "mask", "nvidia-fallback.service"], "Masking NVIDIA fallback service.", dry_run=dry_run): return False
        ui.print_warning("A reboot is required to build and load the NVIDIA kernel modules.")
        return True

class CleanupPackagesTask(Task):
    """Removes orphaned packages from the system."""
    def __init__(self):
        super().__init__("Remove Orphaned Packages", "Removing orphaned packages.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        if dry_run:
            ui.print_dry_run("Would run 'dnf autoremove'.")
            return True
        try:
            prompt = f"{ui.Colors.YELLOW}{ui.Icons.PROMPT} Do you want to remove all unused packages? [Y/n]: {ui.Colors.ENDC}"
            if input(prompt).lower().strip() in ['n', 'no']:
                ui.print_info("Skipping package cleanup.")
                return True
            return utils.execute_command(["dnf", "autoremove", "-y"], "Removing orphaned packages.")
        except (EOFError, KeyboardInterrupt):
            ui.print_info("\nSkipping package cleanup.")
            return True
```

#### `fedora_installer/tasks/user_tasks.py`

```python
# fedora_installer/tasks/user_tasks.py
"""
Contains all tasks related to user-specific setup and configuration.
"""
import logging
from pathlib import Path
from .base_task import Task
from .. import utils, ui, packages, config

class SetupFlatpaksTask(Task):
    """Installs Flatpak and user applications."""
    def __init__(self):
        super().__init__("Install Flatpak Apps", f"Setting up Flatpak and applications for user '{config.SUDO_USER}'.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        if not utils.is_package_installed("flatpak"):
            if not utils.execute_command(["dnf", "install", "-y", "flatpak"], "Installing Flatpak system-wide.", dry_run=dry_run): return False
        repo_cmd = ["flatpak", "remote-add", "--if-not-exists", "--user", "flathub", "https://dl.flathub.org/repo/flathub.flatpakrepo"]
        if not utils.execute_command(repo_cmd, "Adding Flathub repository (user).", as_user=config.SUDO_USER, dry_run=dry_run): return False

        apps = packages.PackageLists.FLATPAK_APPS
        logging.debug(f"List of {len(apps)} Flatpak applications to install: {apps}")
        install_cmd = ["flatpak", "install", "--user", "-y", "flathub"] + apps
        return utils.execute_command(install_cmd, f"Installing {len(apps)} Flatpak applications.", as_user=config.SUDO_USER, dry_run=dry_run)

class CloneDotfilesTask(Task):
    """Clones the Hyprland dotfiles repository."""
    def __init__(self):
        super().__init__("Clone Hyprland Dotfiles", f"Cloning Hyprland dotfiles from {config.DOTFILES_REPO_URL}.")

    def execute(self, context: dict) -> bool:
        if config.DOTFILES_DIR.exists():
            ui.print_warning(f"Dotfiles directory '{config.DOTFILES_DIR}' already exists. Skipping clone.")
            return True
        return utils.execute_command(["git", "clone", config.DOTFILES_REPO_URL, str(config.DOTFILES_DIR)], "Cloning dotfiles repository.", as_user=config.SUDO_USER, dry_run=context.get('dry_run', False))

class ConfigureShellTask(Task):
    """Sets Zsh as the default shell for the user."""
    def __init__(self):
        super().__init__("Set Zsh as Default Shell", f"Setting Zsh as the default shell for '{config.SUDO_USER}'.")

    def execute(self, context: dict) -> bool:
        zsh_path = "/usr/bin/zsh"
        return utils.execute_command(["chsh", "-s", zsh_path, config.SUDO_USER], f"Changing shell for '{config.SUDO_USER}'.", dry_run=context.get('dry_run', False))

class ConfigureGitTask(Task):
    """Configures global Git settings for the user."""
    def __init__(self):
        super().__init__("Configure Git", f"Configuring global Git settings for user '{config.SUDO_USER}'.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        configs = [
            (["git", "config", "--global", "user.name", "aahsnr"], "Configuring Git user name."),
            (["git", "config", "--global", "user.email", "ahsanur041@proton.me"], "Configuring Git user email."),
            (["git", "config", "--global", "credential.helper", "/usr/libexec/git-core/git-credential-libsecret"], "Configuring Git credential helper.")
        ]
        return all(utils.execute_command(cmd, desc, as_user=config.SUDO_USER, dry_run=dry_run) for cmd, desc in configs)

class ConfigureNpmTask(Task):
    """Configures the global NPM directory for the user."""
    def __init__(self):
        super().__init__("Configure NPM", f"Configuring NPM global directory for user '{config.SUDO_USER}'.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        npm_dir = config.USER_HOME / ".npm-global"
        if not dry_run: npm_dir.mkdir(exist_ok=True, parents=True)
        return utils.execute_command(["npm", "config", "set", "prefix", str(npm_dir)], "Setting NPM global prefix.", as_user=config.SUDO_USER, dry_run=dry_run)

class ConfigureScriptSymlinksTask(Task):
    """Creates symbolic links for custom scripts in /usr/local/bin."""
    def __init__(self):
        super().__init__("Configure Script Symlinks", "Creating symbolic links for custom scripts.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        scripts_dir = config.DOTFILES_DIR / "arch-scripts/bin"
        if not scripts_dir.is_dir():
            ui.print_warning(f"Dotfiles script directory not found: {scripts_dir}. Skipping symlinks.")
            return True
        success = True
        for script_path in scripts_dir.iterdir():
            if script_path.is_file():
                dest = Path("/usr/local/bin") / script_path.name
                if dest.exists() or dest.is_symlink():
                    logging.debug(f"Symlink destination {dest} already exists. Skipping.")
                    continue
                if not utils.execute_command(["ln", "-s", str(script_path), str(dest)], f"Linking '{script_path.name}' to '{dest}'", dry_run=dry_run):
                    success = False
        return success
```

#### `fedora_installer/tasks/source_tasks.py`

```python
# fedora_installer/tasks/source_tasks.py
"""
Contains all tasks for building and installing packages from source.
"""
import shutil
import logging
from pathlib import Path
from .base_task import Task
from .. import utils, ui, config

def _build_python_from_git(repo_url: str, final_binary_name: str, dry_run: bool = False) -> bool:
    """Helper function to clone, build, and install a Python wheel from a Git repo."""
    if utils.binary_exists(final_binary_name):
        ui.print_success(f"{final_binary_name} is already installed. Skipping build.")
        return True
    repo_name = Path(repo_url).stem
    clone_dir = config.TEMP_BUILD_DIR / repo_name
    if not dry_run:
        if clone_dir.exists(): shutil.rmtree(clone_dir)
        clone_dir.mkdir(parents=True, exist_ok=True)
    if not utils.execute_command(["git", "clone", repo_url, "."], f"Cloning {repo_name}", cwd=clone_dir, dry_run=dry_run): return False
    if not utils.execute_command(["python3", "-m", "build", "--wheel", "--no-isolation"], f"Building {repo_name}", cwd=clone_dir, dry_run=dry_run): return False
    if dry_run: return True
    try:
        wheel_file = next(clone_dir.joinpath("dist").glob("*.whl"))
        logging.debug(f"Found wheel file: {wheel_file}")
    except StopIteration:
        ui.print_error(f"Could not find a built wheel file for {repo_name}.")
        return False
    return utils.execute_command(["python3", "-m", "installer", str(wheel_file)], f"Installing {repo_name}", dry_run=dry_run)

class InstallGrubBtrfsTask(Task):
    """Builds and installs grub-btrfs from source."""
    def __init__(self):
        super().__init__("Install grub-btrfs", "Building grub-btrfs from source.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        install_script = Path("/etc/grub.d/41_snapshots-btrfs")
        if install_script.exists():
            ui.print_success("grub-btrfs appears to be already installed. Skipping.")
            return True
        clone_dir = config.TEMP_BUILD_DIR / "grub-btrfs"
        if not dry_run:
            if clone_dir.exists(): shutil.rmtree(clone_dir)
            clone_dir.mkdir(parents=True, exist_ok=True)
        if not utils.execute_command(["git", "clone", config.GRUB_BTRFS_REPO_URL, "."], "Cloning grub-btrfs", cwd=clone_dir, dry_run=dry_run): return False
        if not utils.execute_command(["./install.sh"], "Running grub-btrfs install script", cwd=clone_dir, dry_run=dry_run): return False
        ui.print_warning("grub-btrfs installed. You must now update your GRUB config.")
        ui.print_info("Run 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg' after this script finishes.")
        return True

class InstallMaterialYouColorTask(Task):
    """Builds and installs materialyoucolor from source."""
    def __init__(self):
        super().__init__("Install materialyoucolor", "Building materialyoucolor from source.")

    def execute(self, context: dict) -> bool:
        return _build_python_from_git(config.MATERIALYOUCOLOR_REPO_URL, "materialyoucolor", context.get('dry_run', False))

class InstallCaelestiaTask(Task):
    """Builds and installs Caelestia from source."""
    def __init__(self):
        super().__init__("Install Caelestia", "Building Caelestia from source.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        if utils.binary_exists("caelestia"):
            ui.print_success("Caelestia CLI is already installed. Skipping build.")
            return True
        deps = ["glib2-devel", "libqalculate-devel", "qt6-qtdeclarative-devel", "pipewire-devel", "aubio-devel", "hatch", "python3-hatch-vcs", "python3-pillow", "libnotify-devel"]
        if not utils.execute_command(["dnf", "install", "-y"] + deps, "Installing Caelestia build dependencies", dry_run=dry_run): return False
        if not _build_python_from_git(config.CAELESTIA_CLI_REPO_URL, "caelestia", dry_run): return False
        q_dir = config.USER_HOME / ".config/quickshell"
        shell_dir = q_dir / "caelestia"
        beat_detector_src = shell_dir / "assets/beat_detector.cpp"
        beat_detector_bin = q_dir / "beat_detector"
        final_bin_path = Path("/usr/lib/caelestia/beat_detector")
        if not utils.execute_command(["mkdir", "-p", str(q_dir)], "Creating Quickshell config directory", as_user=config.SUDO_USER, dry_run=dry_run): return False
        if not shell_dir.exists():
            if not utils.execute_command(["git", "clone", config.CAELESTIA_SHELL_REPO_URL, str(shell_dir)], "Cloning Caelestia shell config", as_user=config.SUDO_USER, dry_run=dry_run): return False
        if not final_bin_path.exists():
            compile_cmd = ["g++", "-std=c++17", "-o", str(beat_detector_bin), str(beat_detector_src), "-lpipewire-0.3", "-laubio"]
            if not utils.execute_command(compile_cmd, "Compiling beat_detector", as_user=config.SUDO_USER, dry_run=dry_run): return False
            if not utils.execute_command(["mkdir", "-p", str(final_bin_path.parent)], "Creating Caelestia lib directory", dry_run=dry_run): return False
            if not utils.execute_command(["mv", str(beat_detector_bin), str(final_bin_path)], "Installing beat_detector binary", dry_run=dry_run): return False
        else: ui.print_success("beat_detector binary is already installed.")
        return True

class CleanupBuildFilesTask(Task):
    """Cleans up temporary build directories."""
    def __init__(self):
        super().__init__("Cleanup Build Files", "Cleaning up temporary build files.")

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        if dry_run:
            ui.print_dry_run(f"Would remove directory: {config.TEMP_BUILD_DIR}")
            return True
        if config.TEMP_BUILD_DIR.exists():
            shutil.rmtree(config.TEMP_BUILD_DIR)
            logging.info(f"Removed temporary build directory: {config.TEMP_BUILD_DIR}")
        return True
```

#### `fedora_installer/tasks/hardening_tasks.py`

```python
# fedora_installer/tasks/hardening_tasks.py
"""
Contains all tasks for system-wide security and configuration hardening.
"""
from pathlib import Path
from .base_task import Task
from .. import utils

class ConfigureEnvironmentVariablesTask(Task):
    """Sets system-wide environment variables."""
    def __init__(self):
        super().__init__("Set Environment Variables", "Setting system-wide environment variables.")

    def execute(self, context: dict) -> bool:
        content = (
            '#!/bin/sh\n'
            'export EDITOR=${EDITOR:-/usr/bin/nano}\n'
            'export PAGER=${PAGER:-/usr/bin/less}\n'
            'export BROWSER="firefox"\n'
            'export PATH="$PATH:$HOME/.local/bin:$HOME/.npm-global/bin"\n'
        )
        path = Path("/etc/profile.d/99-custom-env.sh")
        return utils.write_file_idempotent(path, content, context.get('dry_run', False))

class ConfigureSecurityLimitsTask(Task):
    """Sets custom user resource limits."""
    def __init__(self):
        super().__init__("Set Security Limits", "Setting user resource limits.")

    def execute(self, context: dict) -> bool:
        content = (
            "# Custom security limits added by installer\n"
            "* soft nofile 65536\n"
            "* hard nofile 1048576\n"
        )
        path = Path("/etc/security/limits.d/99-custom-limits.conf")
        return utils.write_file_idempotent(path, content, context.get('dry_run', False))

class ConfigureLoginBannerTask(Task):
    """Sets a security login banner."""
    def __init__(self):
        super().__init__("Set Login Banner", "Setting security login banner.")

    def execute(self, context: dict) -> bool:
        content = (
            "--- WARNING ---\n"
            "This system is for authorized use only. Activity may be monitored.\n"
        )
        issue_path = Path("/etc/issue")
        issue_net_path = Path("/etc/issue.net")
        if not utils.write_file_idempotent(issue_path, content, context.get('dry_run', False)): return False
        return utils.write_file_idempotent(issue_net_path, content, context.get('dry_run', False))

class ConfigureSshdTask(Task):
    """Applies a hardened SSH server configuration."""
    def __init__(self):
        super().__init__("Harden SSH Daemon", "Applying hardened SSH server configuration.")

    def execute(self, context: dict) -> bool:
        content = (
            "Include /etc/ssh/sshd_config.d/*.conf\n"
            "PermitRootLogin no\n"
            "PasswordAuthentication no\n"
            "PubkeyAuthentication yes\n"
            "ChallengeResponseAuthentication no\n"
            "UsePAM yes\n"
            "X11Forwarding no\n"
            "PrintMotd no\n"
            "AcceptEnv LANG LC_*\n"
            "Subsystem sftp /usr/libexec/openssh/sftp-server\n"
            "MaxAuthTries 3\n"
        )
        path = Path("/etc/ssh/sshd_config.d/99-hardened.conf")
        return utils.write_file_idempotent(path, content, context.get('dry_run', False))
```

#### `fedora_installer/tasks/desktop_tasks.py`

```python
# fedora_installer/tasks/desktop_tasks.py
"""
Contains tasks for creating and enabling user desktop services.
"""
from .base_task import Task
from .. import utils, ui, config

def _get_pyprland_service_content(exec_path: str) -> str:
    return f"""[Unit]
Description=Pyprland - Hyprland IPC gateway
Documentation=https://github.com/hyprland-community/pyprland
PartOf=graphical-session.target
[Service]
ExecStart={exec_path}
Restart=on-failure
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=true
NoNewPrivileges=true
[Install]
WantedBy=graphical-session.target
"""

def _get_cliphist_service_content(exec_start: str, service_type: str) -> str:
    return f"""[Unit]
Description=Clipboard History Manager ({service_type})
Documentation=https://github.com/sentriz/cliphist
PartOf=graphical-session.target
[Service]
ExecStart={exec_start}
Restart=on-failure
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true
ReadWritePaths=%h/.local/share/cliphist/
[Install]
WantedBy=graphical-session.target
"""

class ConfigureUserServicesTask(Task):
    """Creates and enables all systemd user services for the desktop environment."""
    def __init__(self):
        super().__init__("Create and Enable User Services", "Creating and enabling systemd user services.")

    def _create_service_file(self, service_name: str, content: str, dry_run: bool = False) -> bool:
        service_dir = config.USER_HOME / ".config/systemd/user"
        service_path = service_dir / service_name
        return utils.write_file_idempotent(service_path, content, dry_run)

    def execute(self, context: dict) -> bool:
        dry_run = context.get('dry_run', False)
        all_success = True
        if utils.binary_exists("pypr"):
            content = _get_pyprland_service_content("/usr/bin/pypr")
            if not self._create_service_file("pyprland.service", content, dry_run): all_success = False
        if utils.binary_exists("wl-paste") and utils.binary_exists("cliphist"):
            text_cmd = "/usr/bin/wl-paste --watch /usr/bin/cliphist store"
            img_cmd = "/usr/bin/wl-paste --type image/png --watch /usr/bin/cliphist store"
            if not self._create_service_file("cliphist-text.service", _get_cliphist_service_content(text_cmd, "Text"), dry_run): all_success = False
            if not self._create_service_file("cliphist-image.service", _get_cliphist_service_content(img_cmd, "Image"), dry_run): all_success = False

        if not utils.execute_command(["systemctl", "--user", "daemon-reload"], "Reloading user systemd daemon.", as_user=config.SUDO_USER, dry_run=dry_run): return False

        services_to_enable = ["pipewire.service", "pipewire-pulse.service", "wireplumber.service", "hypridle.service", "hyprpaper.service", "pyprland.service", "cliphist-text.service", "cliphist-image.service"]
        enable_cmd = ["systemctl", "--user", "enable", "--now"] + services_to_enable
        if not utils.execute_command(enable_cmd, "Enabling and starting all user services.", as_user=config.SUDO_USER, dry_run=dry_run): all_success = False
        return all_success
```

#### `fedora_installer/resume_manager.py`

```python
# fedora_installer/resume_manager.py
"""
Manages the automatic reboot and resume functionality for the installer.
"""
import logging
import sys
from pathlib import Path
from .ui import Icons, print_info, print_warning
from .utils import write_file_idempotent, execute_command

SERVICE_FILE = Path("/etc/systemd/system/fedora-installer-resume.service")
PYTHON_EXEC = sys.executable
# This is the stable entry point for the application.
ENTRY_POINT_MODULE = "fedora_installer.install"

SERVICE_CONTENT = f"""[Unit]
Description=Resume Fedora Installer after reboot
After=network-online.target
Wants=network-online.target
[Service]
Type=oneshot
ExecStart={PYTHON_EXEC} -m {ENTRY_POINT_MODULE} --resume
ExecStartPost=/bin/rm -f {SERVICE_FILE}
[Install]
WantedBy=default.target
"""

def schedule_reboot_and_resume(dry_run: bool = False):
    """Creates and enables the resume service, then triggers a reboot."""
    print_warning(f"{Icons.REBOOT} System reboot is required to continue the installation.")
    logging.info("Scheduling reboot and creating systemd resume service.")
    if not write_file_idempotent(SERVICE_FILE, SERVICE_CONTENT, dry_run): return
    if not execute_command(["systemctl", "enable", str(SERVICE_FILE)], "Enabling resume service.", dry_run=dry_run): return
    print_info("The system will now reboot to apply core updates and continue the installation automatically.")
    if not execute_command(["systemctl", "reboot"], "Rebooting system.", dry_run=dry_run): return

def cleanup_resume_service(dry_run: bool = False):
    """Disables and removes the resume service file if it exists."""
    if SERVICE_FILE.exists():
        logging.info("Cleaning up systemd resume service.")
        execute_command(["systemctl", "disable", SERVICE_FILE.name], "Disabling resume service.", dry_run=dry_run)
        if not dry_run:
            try:
                SERVICE_FILE.unlink()
                logging.info(f"Successfully removed {SERVICE_FILE}")
            except OSError as e:
                print_warning(f"Failed to remove resume service file: {e}")
                logging.error(f"Error unlinking {SERVICE_FILE}: {e}")
```

#### `fedora_installer/engine.py`

```python
# fedora_installer/engine.py
"""
The engine orchestrates the entire setup process using a task-based system.
"""
import logging
from .ui import print_step, print_success, print_error, print_info
from .utils import check_internet_connection
from .config import SUDO_USER, STATE_FILE
from .tasks.base_task import Task
from .tasks import system_tasks, user_tasks, source_tasks, hardening_tasks, desktop_tasks

class SetupManager:
    """Orchestrates and executes a series of installation tasks."""
    def __init__(self, dry_run: bool = False, debug: bool = False):
        self.context = {'dry_run': dry_run, 'debug': debug}
        self.failed_tasks: list[str] = []
        self.completed_tasks: set[str] = set()

        self.pre_reboot_tasks: list[Task] = [
            system_tasks.ConfigureDnfTask(),
            system_tasks.SetupRepositoriesTask(),
            system_tasks.InstallDnfPackagesTask(),
            user_tasks.SetupFlatpaksTask(),
            system_tasks.ConfigureNvidiaTask(),
        ]
        self.post_reboot_tasks: list[Task] = [
            source_tasks.InstallGrubBtrfsTask(),
            source_tasks.InstallMaterialYouColorTask(),
            source_tasks.InstallCaelestiaTask(),
            source_tasks.CleanupBuildFilesTask(),
            hardening_tasks.ConfigureEnvironmentVariablesTask(),
            hardening_tasks.ConfigureSecurityLimitsTask(),
            hardening_tasks.ConfigureLoginBannerTask(),
            hardening_tasks.ConfigureSshdTask(),
            user_tasks.CloneDotfilesTask(),
            user_tasks.ConfigureShellTask(),
            user_tasks.ConfigureGitTask(),
            user_tasks.ConfigureNpmTask(),
            user_tasks.ConfigureScriptSymlinksTask(),
            desktop_tasks.ConfigureUserServicesTask(),
            system_tasks.CleanupPackagesTask(),
        ]

    def load_state(self):
        if STATE_FILE.exists():
            print_info("Found state file. Loading progress...")
            self.completed_tasks = set(STATE_FILE.read_text().splitlines())
            logging.info(f"Loaded {len(self.completed_tasks)} completed tasks from state file.")
        else:
            print_info("No state file found. Starting a fresh run.")

    def save_state(self):
        if not self.context['dry_run']:
            STATE_FILE.write_text("\n".join(sorted(list(self.completed_tasks))))
            logging.debug(f"Saved {len(self.completed_tasks)} tasks to state file.")

    def clear_state(self):
        if not self.context['dry_run'] and STATE_FILE.exists():
            STATE_FILE.unlink()
            logging.info("Cleared state file for a fresh run or successful completion.")

    def _run_task(self, task: Task) -> bool:
        """Wrapper to run a single task, handle state, and track failures."""
        if task.name in self.completed_tasks:
            print_success(f"Task '{task.name}' already completed. Skipping.")
            return True

        print_info(f"Executing Task: {task.name}...")
        logging.info(f"--- Starting task: {task.name} ---")
        logging.info(f"Task Description: {task.description}")

        try:
            success = task.execute(self.context)
        except Exception:
            logging.exception(f"An unexpected Python exception occurred during task: '{task.name}'")
            success = False

        if not success:
            self.failed_tasks.append(task.name)
            print_error(f"Task '{task.name}' failed.")
            logging.error(f"--- Task Failed: {task.name} ---")
            return False
        else:
            self.completed_tasks.add(task.name)
            self.save_state()
            print_success(f"Task '{task.name}' completed successfully.")
            logging.info(f"--- Task Succeeded: {task.name} ---")
            return True

    def run_pre_flight_checks(self):
        print_step("Running Pre-flight Checks")
        if not check_internet_connection(): print_error("No internet connection. Please connect and try again.", fatal=True)
        if SUDO_USER == "root": print_error("This script must be run with 'sudo', not as the root user directly. Aborting.", fatal=True)
        print_success(f"Checks passed. Internet is active. Running for user: {SUDO_USER}")

    def run_tasks(self, tasks_to_run: list[Task]) -> bool:
        """Executes a list of tasks sequentially."""
        for task in tasks_to_run:
            if not self._run_task(task):
                return False
        return True
```

#### `fedora_installer/install.py`

```python
# fedora_installer/install.py
"""
Main entry point for the Fedora installer script.
Parses arguments and orchestrates the SetupManager.
"""
import argparse
import sys
import os
import logging
from typing import List, Dict
from .engine import SetupManager
from .ui import Colors, Icons, print_error, print_step, print_success, print_warning, setup_logging, print_dry_run, print_info
from . import resume_manager
from .tasks.base_task import Task
from .tasks import system_tasks, user_tasks, source_tasks, hardening_tasks, desktop_tasks

def check_root():
    if os.geteuid() != 0:
        print_error("This script requires root privileges. Please run with 'sudo'.", fatal=True)

def print_summary_and_confirm(dry_run: bool):
    print_step("Full Installation Plan Summary")
    summary = f"""
This script will perform a full, opinionated setup of a Fedora Hyprland desktop.
It is designed to be fully automated, including a system reboot.

{Colors.HEADER}Execution Plan:{Colors.ENDC}
{Colors.BLUE}Phase 1 (Pre-Reboot):{Colors.ENDC}
   - Configure DNF, enable external repositories.
   - Install all core system packages, drivers, and applications.
   - The system will {Colors.YELLOW}automatically reboot{Colors.ENDC} after this phase.
{Colors.BLUE}Phase 2 (Post-Reboot):{Colors.ENDC}
   - The script will {Colors.YELLOW}resume automatically{Colors.ENDC} after login.
   - Build and install packages from source.
   - Apply system-wide security hardening.
   - Configure user settings (dotfiles, shell, Git, NPM).
   - Create and enable all desktop services.
   - Clean up any orphaned packages.
"""
    print(summary)
    if dry_run:
        print_dry_run("This is a dry run. The system will not actually reboot.")
        return
    try:
        prompt = f"{Colors.YELLOW}{Icons.PROMPT} Do you want to begin the automated installation? [y/N]: {Colors.ENDC}"
        if input(prompt).lower().strip() != 'y':
            print_info("Aborting at user request."); sys.exit(0)
    except (EOFError, KeyboardInterrupt):
        print_info("\nNo input received. Aborting."); sys.exit(0)

def main() -> None:
    parser = argparse.ArgumentParser(description=f"{Colors.BOLD}--- Fedora Hyprland Setup Script ---{Colors.ENDC}", epilog="Running without flags triggers the fully automated installation.", formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--resume", action="store_true", help=argparse.SUPPRESS)

    task_group = parser.add_argument_group('Manual Task Flags', 'Run specific parts of the setup. Disables automatic reboot.')
    task_group.add_argument("--setup-repos", action="store_true", help="Configure DNF and external repositories.")
    task_group.add_argument("--install-packages", action="store_true", help="Install all DNF and Flatpak packages.")
    task_group.add_argument("--build-from-source", action="store_true", help="Build packages from source.")
    task_group.add_argument("--harden-system", action="store_true", help="Apply system security hardening.")
    task_group.add_argument("--configure-hardware", action="store_true", help="Apply hardware configurations (e.g., NVIDIA).")
    task_group.add_argument("--configure-user", action="store_true", help="Apply user settings (Shell, Git, Dotfiles).")
    task_group.add_argument("--setup-hyprland", action="store_true", help="Create and enable Hyprland user services.")
    task_group.add_argument("--cleanup", action="store_true", help="Remove orphaned packages.")

    options_group = parser.add_argument_group('Options')
    options_group.add_argument("--dry-run", action="store_true", help="Simulate the run without making any system changes.")
    options_group.add_argument("--debug", action="store_true", help="Enable verbose debug logging to console and file.")
    args = parser.parse_args()

    check_root()
    setup_logging(debug=args.debug)

    manager = SetupManager(dry_run=args.dry_run, debug=args.debug)
    manager.run_pre_flight_checks()

    # Map command-line flags to their corresponding task objects for cleaner logic
    flag_to_tasks_map: Dict[str, List[Task]] = {
        "setup_repos": [system_tasks.ConfigureDnfTask(), system_tasks.SetupRepositoriesTask()],
        "install_packages": [system_tasks.InstallDnfPackagesTask(), user_tasks.SetupFlatpaksTask()],
        "build_from_source": [source_tasks.InstallGrubBtrfsTask(), source_tasks.InstallMaterialYouColorTask(), source_tasks.InstallCaelestiaTask(), source_tasks.CleanupBuildFilesTask()],
        "harden_system": [hardening_tasks.ConfigureEnvironmentVariablesTask(), hardening_tasks.ConfigureSecurityLimitsTask(), hardening_tasks.ConfigureLoginBannerTask(), hardening_tasks.ConfigureSshdTask()],
        "configure_hardware": [system_tasks.ConfigureNvidiaTask()],
        "configure_user": [user_tasks.CloneDotfilesTask(), user_tasks.ConfigureShellTask(), user_tasks.ConfigureGitTask(), user_tasks.ConfigureNpmTask(), user_tasks.ConfigureScriptSymlinksTask()],
        "setup_hyprland": [desktop_tasks.ConfigureUserServicesTask()],
        "cleanup": [system_tasks.CleanupPackagesTask()],
    }

    manual_tasks_to_run: List[Task] = []
    for flag, tasks in flag_to_tasks_map.items():
        if getattr(args, flag, False):
            manual_tasks_to_run.extend(tasks)

    if manual_tasks_to_run:
        print_info("Running in manual mode. Automatic reboot is disabled.")
        manager.run_tasks(manual_tasks_to_run)
    else:
        # --- AUTOMATED MODE ---
        if args.resume:
            print_info(f"{Icons.REBOOT} Resuming installation after reboot...")
            manager.load_state()
        else:
            print_summary_and_confirm(args.dry_run)
            manager.clear_state()

        if not args.resume: # Phase 1
            print_step("Executing Pre-Reboot Tasks")
            if not manager.run_tasks(manager.pre_reboot_tasks):
                print_error("Pre-reboot phase failed. Aborting.", fatal=True)
            resume_manager.schedule_reboot_and_resume(args.dry_run)
            if not args.dry_run: sys.exit(0)

        # Phase 2
        print_step("Executing Post-Reboot Tasks")
        if not manager.run_tasks(manager.post_reboot_tasks):
            print_error("Post-reboot phase failed. Please check logs.", fatal=True)
        manager.clear_state()
        resume_manager.cleanup_resume_service(args.dry_run)

    print_step(f"{Icons.FINISH} Run Complete!")
    if not manager.failed_tasks:
        print_success("All requested tasks finished successfully!")
    else:
        print_warning(f"Process finished with {len(manager.failed_tasks)} error(s):")
        for failure in manager.failed_tasks: print(f"  - {failure}")
        print_warning(f"Please review the log file ('fedora_setup.log') for details."); sys.exit(1)

    if not manual_tasks_to_run or args.configure_hardware:
        print_warning("A final reboot is recommended to ensure all changes are applied.")
    sys.exit(0)

if __name__ == "__main__":
    main()
```
