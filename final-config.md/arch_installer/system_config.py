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
        with tempfile.NamedTemporaryFile(
            mode="w", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(content)
            tmp_path = tmp.name
        target = "/etc/profile.d/variables.sh"
        return (
            execute_command(
                ["sudo", "mv", tmp_path, target], f"Moving script to '{target}'"
            )
            and execute_command(
                ["sudo", "chown", "root:root", target],
                f"Setting ownership for {target}",
            )
            and execute_command(
                ["sudo", "chmod", "755", target], f"Setting permissions for {target}"
            )
        )
    except Exception as e:
        print_error(f"Failed to write environment variables script: {e}")
        return False


def configure_security_limits() -> bool:
    print_info(
        f"{Icons.SECURITY} Setting user resource limits in /etc/security/limits.conf."
    )
    content = _get_limits_conf_content()
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(content + "\n")
            tmp_path = tmp.name
        target = "/etc/security/limits.conf"
        return (
            execute_command(
                ["sudo", "mv", tmp_path, target], f"Moving config to '{target}'"
            )
            and execute_command(
                ["sudo", "chown", "root:root", target],
                f"Setting ownership for {target}",
            )
            and execute_command(
                ["sudo", "chmod", "644", target], f"Setting permissions for {target}"
            )
        )
    except Exception as e:
        print_error(f"Failed to write security limits: {e}")
        return False


def configure_login_banners() -> bool:
    print_info(f"{Icons.SECURITY} Setting security login banner.")
    content = _get_login_banner_content()
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(content.strip() + "\n")
            tmp_path = tmp.name
        issue_ok = (
            execute_command(
                ["sudo", "mv", tmp_path, "/etc/issue"], "Moving banner to '/etc/issue'"
            )
            and execute_command(
                ["sudo", "chown", "root:root", "/etc/issue"], "Setting ownership"
            )
            and execute_command(
                ["sudo", "chmod", "644", "/etc/issue"], "Setting permissions"
            )
        )
        if not issue_ok:
            return False
        return (
            execute_command(
                ["sudo", "cp", "/etc/issue", "/etc/issue.net"],
                "Copying banner to '/etc/issue.net'",
            )
            and execute_command(
                ["sudo", "chown", "root:root", "/etc/issue.net"], "Setting ownership"
            )
            and execute_command(
                ["sudo", "chmod", "644", "/etc/issue.net"], "Setting permissions"
            )
        )
    except Exception as e:
        print_error(f"Failed to write login banners: {e}")
        return False


def configure_sshd() -> bool:
    print_info(f"{Icons.SECURITY} Applying hardened SSH server configuration.")
    content = _get_sshd_config_content()
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", delete=False, encoding="utf-8"
        ) as tmp:
            tmp.write(content)
            tmp_path = tmp.name
        target = "/etc/ssh/sshd_config"
        return (
            execute_command(
                ["sudo", "mv", tmp_path, target], f"Moving config to '{target}'"
            )
            and execute_command(
                ["sudo", "chown", "root:root", target], "Setting ownership"
            )
            and execute_command(["sudo", "chmod", "644", target], "Setting permissions")
        )
    except Exception as e:
        print_error(f"Failed to write SSH config: {e}")
        return False


def configure_symlinks() -> bool:
    print_info("Creating system-wide symbolic links for custom scripts.")
    base_dir = os.path.join(DOTFILES_DIR, "arch-scripts", "bin")
    if not os.path.isdir(base_dir):
        print_error(f"Dotfiles script directory not found: {base_dir}")
        return False
    success = True
    for script in [
        "cliphist-rofi",
        "hyprlauncher",
        "hyprrunner",
        "hyprterm",
        "hyprtheme",
    ]:
        src, dest = os.path.join(base_dir, script), f"/usr/local/bin/{script}"
        if os.path.lexists(dest) or not os.path.exists(src):
            continue
        if not execute_command(
            ["sudo", "ln", "-s", src, dest], f"Linking '{script}' to '{dest}'"
        ):
            success = False
    return success


def configure_system_services(extra_services: List[str]) -> bool:
    print_info("Enabling system-wide services.")
    services = {
        "acpid.service",
        "apparmor.service",
        "auditd.service",
        "chronyd.service",
        "cockpit.socket",
        "grub-btrfsd.service",
        "haveged.service",
        "lxd.service",
        "NetworkManager.service",
        "piavpn.service",
        "rngd.service",
        "sshd.service",
        "sysstat.service",
        "power-profiles-daemon.service",
    }
    services.update(extra_services)
    return execute_command(
        ["sudo", "systemctl", "enable"] + sorted(list(services)),
        "Enabling systemd services.",
    )


def configure_shell() -> bool:
    print_info("Setting Zsh as the default shell.")
    zsh_path = shutil.which("zsh")
    if zsh_path:
        return execute_command(
            ["sudo", "chsh", "-s", zsh_path, CURRENT_USER],
            f"Changing shell for '{CURRENT_USER}' to Zsh.",
        )
    print_error("Zsh not found, cannot set as default shell.")
    return False


def cleanup_orphan_packages() -> bool:
    print_info("Checking for orphan packages...")
    try:
        proc = subprocess.run(
            ["pacman", "-Qdtq"], capture_output=True, text=True, check=False
        )
        if proc.returncode != 0 and not proc.stdout.strip():
            print_success("No orphan packages found.")
            return True
        orphans = [line for line in proc.stdout.strip().split("\n") if line]
        if not orphans:
            print_success("No orphan packages found.")
            return True
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        print_error(f"Failed to query orphan packages: {e}")
        return False
    print_warning(f"Found {len(orphans)} orphan package(s):")
    for orphan in orphans:
        print(f"  - {orphan}")
    try:
        prompt = f"{Colors.YELLOW}{Icons.PROMPT} Do you want to remove them? [Y/n]: {Colors.ENDC}"
        if input(prompt).lower().strip() not in ["n", "no"]:
            return execute_command(
                ["sudo", "pacman", "-Rns"] + orphans, "Removing orphan packages."
            )
        print_info("Skipping removal of orphan packages.")
    except (EOFError, KeyboardInterrupt):
        print_info("\nSkipping removal of orphan packages.")
    return True
