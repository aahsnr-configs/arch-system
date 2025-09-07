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
        if not execute_command(
            ["sudo", "pacman", "-S", "--needed", "--noconfirm", "awk"],
            "Ensuring 'awk' is available.",
        ):
            return False
        try:
            pacman_proc = subprocess.Popen(
                ["pacman", "-Q"], stdout=subprocess.PIPE, text=True
            )
            awk_proc = subprocess.Popen(
                ["awk", "{print $1}"],
                stdin=pacman_proc.stdout,
                stdout=subprocess.PIPE,
                text=True,
            )
            if pacman_proc.stdout:
                pacman_proc.stdout.close()
            package_list, _ = awk_proc.communicate()
            if awk_proc.returncode != 0:
                raise subprocess.CalledProcessError(awk_proc.returncode, "awk")
            output_file_path = os.path.join(USER_HOME, "pre-cleaned.txt")
            with open(output_file_path, "w", encoding="utf-8") as f:
                f.write(package_list)
            print_success(f"Saved initial package list to '{output_file_path}'")
            return True
        except (IOError, FileNotFoundError, subprocess.CalledProcessError) as e:
            print_error(f"Failed to audit packages: {e}")
            return False

    def run_bootstrap_checks(self, dotfiles_url: str) -> bool:
        print_step("Running Bootstrap Checks")
        checks = {
            "Must not be run as root": lambda: os.geteuid() != 0,
            "Internet connection available": check_internet_connection,
            "`git` command installed": lambda: shutil.which("git") is not None,
        }
        if dotfiles_url.startswith("git@"):
            print_info("SSH URL detected. Will check for SSH client.")
            checks["`ssh` command for SSH cloning"] = (
                lambda: shutil.which("ssh") is not None
            )
        for desc, check_func in checks.items():
            if not check_func():
                print_error(f"Bootstrap check failed: {desc}.")
                return False
            print_success(f"{desc}: OK")
        if dotfiles_url.startswith("git@"):
            print_warning(
                "Ensure your SSH keys are configured correctly to clone via SSH."
            )
        if os.path.isdir(DOTFILES_DIR):
            print_warning(
                f"Dotfiles directory '{DOTFILES_DIR}' exists. Skipping clone."
            )
        elif not execute_command(
            ["git", "clone", dotfiles_url, DOTFILES_DIR], "Cloning dotfiles repository."
        ):
            return False
        return True

    def ensure_yay_installed(self) -> bool:
        if shutil.which("yay"):
            print_success("'yay' is already installed.")
            return True
        print_step(f"{Icons.PACKAGE} Installing AUR Helper (yay)")
        if not execute_command(
            ["sudo", "pacman", "-S", "--needed", "--noconfirm", "base-devel", "git"],
            "Installing build dependencies.",
        ):
            return False
        with tempfile.TemporaryDirectory() as tmpdir:
            if not execute_command(
                ["git", "clone", "https://aur.archlinux.org/yay-bin.git", tmpdir],
                "Cloning 'yay-bin' repo.",
            ):
                return False
            if not execute_command(
                ["makepkg", "-si", "--noconfirm"],
                "Building and installing 'yay'.",
                cwd=tmpdir,
            ):
                return False
        if shutil.which("yay"):
            print_success("'yay' has been successfully installed.")
            return True
        print_error("Installation failed. 'yay' command not found.")
        return False

    def run_package_installation(self, extra_packages: list) -> bool:
        print_step("Installing System Packages")
        packages_to_install = PackageLists.get_all()
        if extra_packages:
            packages_to_install = sorted(
                list(set(packages_to_install).union(extra_packages))
            )
        print_info(f"Found {len(packages_to_install)} unique packages to install.")
        return execute_command(
            ["yay", "-S", "--needed", "--noconfirm"] + packages_to_install,
            "Installing all packages.",
        )

    def prompt_for_asus_setup(self) -> Tuple[list, list]:
        print_step("Asus ROG Laptop Configuration (Optional)")
        prompt = f"{Icons.PROMPT} Run Asus-specific setup (G14/ROG)? [y/N]: "
        try:
            if input(prompt).lower().strip() != "y":
                print_info("Skipping Asus setup.")
                return [], []
        except (EOFError, KeyboardInterrupt):
            print_info("\nSkipping Asus setup.")
            return [], []
        print_info("Proceeding with Asus setup...")
        key_id = "8F654886F17D497FEFE3DB448B15A6B0E9A3FA35"
        if not execute_command(
            ["sudo", "pacman-key", "--recv-keys", key_id], "Receiving g14 repo key."
        ) or not execute_command(
            ["sudo", "pacman-key", "--lsign-key", key_id], "Signing g14 repo key."
        ):
            return [], []
        try:
            with open("/etc/pacman.conf", "r+", encoding="utf-8") as f:
                if "[g14]" not in f.read():
                    f.write("\n[g14]\nServer = https://arch.asus-linux.org\n")
                    print_success("Added [g14] repo.")
        except IOError as e:
            print_error(f"Could not access /etc/pacman.conf: {e}")
            return [], []
        execute_command(["sudo", "pacman", "-Syyu"], "Synchronizing package databases.")
        return ["asusctl", "supergfxctl", "rog-control-center"], [
            "supergfxd.service",
            "switcheroo-control.service",
        ]
