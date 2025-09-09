#!/usr/bin/env python3.13
# -*- coding: utf-8 -*-

"""
This script provides a complete, end-to-end setup for a personalized Emacs
distribution on a Fedora-based system.

It performs the following sequence of operations:
1.  Cleans up any previous Emacs configurations and processes.
2.  Installs all necessary system dependencies for building and running Emacs.
3.  Downloads, builds, and installs the specified version of GNU Emacs from source.
4.  Clones the user's personal Emacs configuration from GitHub.
5.  Performs the initial setup of the configuration by tangling the org file
    and starting the Emacs daemon while logging all output.
6.  Cleans up the Emacs source and build files.
"""

import subprocess
import time
import os
import shutil
from pathlib import Path
from typing import final, Final
from datetime import datetime

# --- Configuration ---
EMACS_VERSION: Final[str] = "30.2"
EMACS_CONFIG_REPO: Final[str] = "git@github.com:aahsnr/emacs.git"

# --- Derived Configuration ---
TARBALL_NAME: Final[str] = f"emacs-{EMACS_VERSION}.tar.xz"
SOURCE_DIR_NAME: Final[str] = f"emacs-{EMACS_VERSION}"
DOWNLOAD_URL: Final[str] = f"https://gnu.mirror.constant.com/emacs/{TARBALL_NAME}"
CONFIGURE_ARGS: Final[list[str]] = [
    "--sysconfdir=/etc",
    "--prefix=/usr",
    "--libexecdir=/usr/lib",
    "--localstatedir=/var",
    "--disable-build-details",
    "--with-cairo",
    "--with-harfbuzz",
    "--with-libsystemd",
    "--with-modules",
    "--with-native-compilation",
    "--with-tree-sitter",
    "--with-pgtk",
    "--with-mailutils",
]
MAKE_JOBS: Final[int] = os.cpu_count() or 1


# --- Style and Symbols for Rich Terminal Output ---
@final
class Style:
    RESET: Final[str] = "\033[0m"
    BOLD: Final[str] = "\033[1m"
    RED: Final[str] = "\033[31m"
    GREEN: Final[str] = "\033[32m"
    YELLOW: Final[str] = "\033[33m"
    BLUE: Final[str] = "\033[34m"


INFO_SYMBOL: Final[str] = "ℹ️"
SUCCESS_SYMBOL: Final[str] = "✅"
ERROR_SYMBOL: Final[str] = "❌"
GEAR_SYMBOL: Final[str] = "⚙️"
DOWNLOAD_SYMBOL: Final[str] = "📥"
CLEANUP_SYMBOL: Final[str] = "🧹"
CLONE_SYMBOL: Final[str] = "📦"


def run_command(
    command: list[str],
    cwd: Path,
    use_sudo: bool = False,
    env: dict[str, str] | None = None,
    check: bool = True,
):
    """Executes a shell command with real-time output and robust error handling."""
    if use_sudo:
        command = ["sudo"] + command

    command_str = " ".join(command)
    print(
        f"{Style.YELLOW}{GEAR_SYMBOL} Running: {Style.BOLD}{command_str}{Style.RESET} in '{cwd}'"
    )

    try:
        process = subprocess.Popen(
            command,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        if process.stdout:
            for line in iter(process.stdout.readline, ""):
                print(line, end="")
        _ = process.wait()
        if check and process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, command)
    except FileNotFoundError:
        print(
            f"{Style.RED}{ERROR_SYMBOL} Error: Command not found: {command[0]}{Style.RESET}"
        )
        exit(1)
    except subprocess.CalledProcessError as e:
        print(
            f"\n{Style.RED}{ERROR_SYMBOL} An error occurred while executing: {command_str}{Style.RESET}"
        )
        print(f"{Style.RED}Return code: {e.returncode}{Style.RESET}")
        exit(1)


def initial_cleanup(home_dir: Path):
    """Removes old configurations and kills any running Emacs instances."""
    print(
        f"\n{Style.BLUE}{CLEANUP_SYMBOL} Performing initial system cleanup...{Style.RESET}"
    )
    emacs_d_path = home_dir / ".emacs.d"
    emacs_config_path = home_dir / ".config" / "emacs"

    for path in [emacs_d_path, emacs_config_path]:
        if path.exists():
            print(f"Removing existing directory: {path}")
            shutil.rmtree(path, ignore_errors=True)

    print("Checking for running Emacs instances...")
    run_command(
        ["systemctl", "--user", "stop", "emacs.service"], cwd=home_dir, check=False
    )
    run_command(["killall", "emacs"], cwd=home_dir, check=False)
    time.sleep(1)


def install_system_dependencies(home_dir: Path):
    """Installs all necessary build and runtime dependencies via dnf."""
    print(f"\n{Style.BLUE}{INFO_SYMBOL} Installing system dependencies...{Style.RESET}")
    print(f"{Style.YELLOW}You may be prompted for your password.{Style.RESET}")

    print("Installing Emacs build dependencies...")
    run_command(["dnf", "build-dep", "-y", "emacs"], cwd=home_dir, use_sudo=True)

    print("\nInstalling additional required packages (git, zeromq-devel)...")
    additional_deps = ["git", "zeromq-devel"]
    run_command(["dnf", "install", "-y"] + additional_deps, cwd=home_dir, use_sudo=True)


def build_and_install_emacs(home_dir: Path, tarball_path: Path, source_dir: Path):
    """Orchestrates the download, build, and installation of Emacs."""
    print(
        f"\n{Style.BLUE}{DOWNLOAD_SYMBOL} Downloading and extracting Emacs {EMACS_VERSION}...{Style.RESET}"
    )
    if not tarball_path.exists():
        run_command(["wget", DOWNLOAD_URL], cwd=home_dir)
    else:
        print(
            f"{Style.YELLOW}{INFO_SYMBOL} Tarball already exists. Skipping download.{Style.RESET}"
        )

    if source_dir.exists():
        shutil.rmtree(source_dir)
    run_command(["tar", "-xvf", str(tarball_path)], cwd=home_dir)

    print(f"\n{Style.BLUE}{GEAR_SYMBOL} Configuring and building Emacs...{Style.RESET}")
    compiler_env = os.environ.copy()
    compiler_env["CC"] = "/usr/bin/gcc"
    compiler_env["CXX"] = "/usr/bin/gcc"
    run_command(["./configure"] + CONFIGURE_ARGS, cwd=source_dir, env=compiler_env)
    run_command(["make", "bootstrap", f"-j{MAKE_JOBS}"], cwd=source_dir)

    print(f"\n{Style.BLUE}{INFO_SYMBOL} Installing Emacs...{Style.RESET}")
    run_command(["make", "install"], cwd=source_dir, use_sudo=True)


def clone_emacs_config(emacs_config_dir: Path):
    """Clones the personal Emacs configuration from GitHub."""
    print(
        f"\n{Style.BLUE}{CLONE_SYMBOL} Cloning personal Emacs configuration...{Style.RESET}"
    )
    run_command(
        [
            "git",
            "clone",
            "--recurse-submodules",
            EMACS_CONFIG_REPO,
            str(emacs_config_dir),
        ],
        cwd=emacs_config_dir.parent,
    )


def setup_emacs_config(emacs_config_dir: Path):
    """Tangles the Org file and starts the Emacs daemon, logging output."""
    print(
        f"\n{Style.BLUE}{GEAR_SYMBOL} Performing first-time setup for Emacs configuration...{Style.RESET}"
    )
    log_dir = emacs_config_dir / "log"
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d_%I-%M%p")
    log_file = log_dir / f"emacs-run_{timestamp}.log"

    print("\n--- Emacs First Run & Logging ---")
    print("Tangling 'config.org' and starting the daemon.")
    print(f"All startup output will be logged to:\n  {log_file}")
    print(f'\nTo monitor progress, run in another terminal:\n  tail -f "{log_file}"')

    print("\nTangling config.org into init.el...")
    tangle_command = [
        "emacs",
        "--batch",
        "--eval",
        "(require 'org)",
        "--eval",
        '(org-babel-tangle-file "config.org")',  # Corrected filename
    ]
    run_command(tangle_command, cwd=emacs_config_dir)

    print("Starting Emacs daemon in the background...")
    try:
        with open(log_file, "w") as log_f:
            # Assign Popen result to '_' to signal it's intentionally unused
            _ = subprocess.Popen(
                ["emacs", "--daemon"], cwd=emacs_config_dir, stdout=log_f, stderr=log_f
            )
    except Exception as e:
        print(
            f"{Style.RED}{ERROR_SYMBOL} Failed to start Emacs daemon: {e}{Style.RESET}"
        )
        exit(1)


def cleanup_build_files(tarball_path: Path, source_dir: Path):
    """Removes the downloaded tarball and extracted source directory."""
    print(f"\n{Style.BLUE}{CLEANUP_SYMBOL} Cleaning up build files...{Style.RESET}")
    try:
        if tarball_path.exists():
            tarball_path.unlink()
            print(f"Removed: {tarball_path}")
        if source_dir.exists():
            shutil.rmtree(source_dir)
            print(f"Removed: {source_dir}")
    except OSError as e:
        print(f"{Style.RED}{ERROR_SYMBOL} Error during cleanup: {e}{Style.RESET}")


def main():
    """Main function to orchestrate the entire setup process."""
    print(f"{Style.GREEN}{Style.BOLD}--- Complete Emacs Setup Script ---{Style.RESET}")
    time.sleep(2)

    home_dir = Path.home()
    source_dir = home_dir / SOURCE_DIR_NAME
    tarball_path = home_dir / TARBALL_NAME
    emacs_config_dir = home_dir / ".config" / "emacs"

    initial_cleanup(home_dir)
    install_system_dependencies(home_dir)
    build_and_install_emacs(home_dir, tarball_path, source_dir)
    clone_emacs_config(emacs_config_dir)
    setup_emacs_config(emacs_config_dir)
    cleanup_build_files(tarball_path, source_dir)

    print(
        f"\n{Style.GREEN}{Style.BOLD}{SUCCESS_SYMBOL} Emacs setup is complete!{Style.RESET}"
    )
    print("The Emacs daemon has been started in the background.")
    print("You can now connect to it using 'emacsclient -c -a emacs'.")


if __name__ == "__main__":
    if os.geteuid() == 0:
        print(
            f"{Style.RED}This script should not be run as root. It will use 'sudo' when needed.{Style.RESET}"
        )
        exit(1)
    main()
