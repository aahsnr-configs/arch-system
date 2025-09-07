# arch_installer/user_config.py
import os
from .config import USER_HOME
from .ui import Icons, print_info, print_warning
from .utils import execute_command


def configure_caelestia() -> bool:
    print_info(f"{Icons.DESKTOP} Configuring Caelestia Desktop Shell.")
    config_dir = os.path.join(USER_HOME, ".config", "quickshell")
    if not os.path.exists(config_dir):
        if not execute_command(
            ["git", "clone", "https://github.com/caelestia-dots/shell.git", config_dir],
            "Cloning Caelestia config.",
        ):
            return False
    source_file = os.path.join(config_dir, "cxx", "beat_detector.cpp")
    if not os.path.exists(source_file):
        print_warning("Caelestia source not found, skipping compilation.")
        return True
    output_file = os.path.join(config_dir, "beat_detector")
    cmd = [
        "g++",
        "-std=c++17",
        "-Wall",
        "-Wextra",
        "-o",
        output_file,
        source_file,
        "-lpipewire-0.3",
        "-laubio",
    ]
    if not execute_command(cmd, "Compiling Caelestia utility.", cwd=config_dir):
        return False
    dest_dir = "/usr/lib/caelestia"
    return execute_command(
        ["sudo", "mkdir", "-p", dest_dir], f"Creating directory '{dest_dir}'."
    ) and execute_command(
        ["sudo", "mv", output_file, os.path.join(dest_dir, "beat_detector")],
        "Installing binary.",
    )


def configure_git() -> bool:
    print_info("Configuring global Git settings.")
    configs = [
        (
            ["git", "config", "--global", "user.name", "aahsnr"],
            "Configuring Git user name.",
        ),
        (
            ["git", "config", "--global", "user.email", "ahsanur041@proton.me"],
            "Configuring Git user email.",
        ),
        (
            [
                "git",
                "config",
                "--global",
                "credential.helper",
                "/usr/lib/git-core/git-credential-libsecret",
            ],
            "Configuring Git credential helper.",
        ),
    ]
    return all(execute_command(cmd, desc) for cmd, desc in configs)


def configure_npm() -> bool:
    print_info("Configuring NPM global directory.")
    npm_dir = os.path.join(USER_HOME, ".npm-global")
    os.makedirs(npm_dir, exist_ok=True)
    return execute_command(
        ["npm", "config", "set", "prefix", npm_dir], "Setting NPM global prefix."
    )
