# arch_installer/install.py
import argparse
import sys
import os
from .config import CURRENT_USER, DOTFILES_DIR
from .engine import SetupManager
from .ui import (
    Colors,
    Icons,
    print_error,
    print_info,
    print_step,
    print_success,
    print_warning,
    setup_logging,
)
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
        if input(prompt).lower().strip() in ["n", "no"]:
            print_info("Aborting at user request.")
            sys.exit(0)
    except (EOFError, KeyboardInterrupt):
        print_info("\nNo input received. Aborting.")
        sys.exit(0)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="A modular installer for a personalized Arch Linux setup.",
        epilog="If no flags are provided, a full installation is attempted, which requires --dotfiles-url.",
    )
    parser.add_argument(
        "--dotfiles-url", help="HTTPS or SSH URL of the dotfiles repository."
    )
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Run pre-flight checks and clone dotfiles.",
    )
    parser.add_argument(
        "--install-packages",
        action="store_true",
        help="Install yay and all system packages.",
    )
    parser.add_argument(
        "--configure-system",
        action="store_true",
        help="Apply all system-wide configurations.",
    )
    parser.add_argument(
        "--configure-user",
        action="store_true",
        help="Apply all user-specific configurations.",
    )
    parser.add_argument(
        "--cleanup", action="store_true", help="Remove orphan packages."
    )
    args = parser.parse_args()

    setup_logging()
    print(
        f"{Colors.BOLD}--- Arch Linux Setup Script (Modular Version) ---{Colors.ENDC}"
    )

    manager = SetupManager()
    failed_tasks = []

    task_flags_provided = any(
        [
            args.bootstrap,
            args.install_packages,
            args.configure_system,
            args.configure_user,
            args.cleanup,
        ]
    )

    if not task_flags_provided:
        if not args.dotfiles_url:
            parser.error(
                "The --dotfiles-url argument is required for a full installation."
            )
        print_summary_and_confirm(args.dotfiles_url)

        if not manager.run_pre_cleanup_step() or not manager.run_bootstrap_checks(
            args.dotfiles_url
        ):
            print_error("Preliminary checks failed. Aborting.")
            sys.exit(1)

        print_step("Acquiring Administrator Privileges")
        if not execute_command(["sudo", "-v"], "Caching sudo credentials."):
            print_error("Could not acquire sudo privileges. Aborting.")
            sys.exit(1)

        if not manager.ensure_yay_installed():
            print_error("'yay' installation failed. Aborting.")
            sys.exit(1)

        asus_packages, asus_services = manager.prompt_for_asus_setup()
        if not manager.run_package_installation(asus_packages):
            print_error("Package installation failed. Aborting.")
            sys.exit(1)

        for config_func, name in [
            (
                system_config.configure_environment_variables,
                "Set environment variables",
            ),
            (system_config.configure_security_limits, "Set security limits"),
            (system_config.configure_login_banners, "Set login banners"),
            (system_config.configure_sshd, "Configure SSH daemon"),
            (system_config.configure_symlinks, "Create system symlinks"),
            (
                lambda: system_config.configure_system_services(asus_services),
                "Enable system services",
            ),
            (system_config.configure_shell, "Change default shell"),
            (user_config.configure_caelestia, "Configure Caelestia"),
            (user_services.configure_all_user_services, "Configure user services"),
            (user_config.configure_git, "Configure Git"),
            (user_config.configure_npm, "Configure NPM"),
        ]:
            if not config_func():
                failed_tasks.append(name)

        if not system_config.cleanup_orphan_packages():
            failed_tasks.append("Clean up orphan packages")
    else:
        if any(
            [
                args.install_packages,
                args.configure_system,
                args.cleanup,
                args.configure_user,
            ]
        ):
            print_step("Acquiring Administrator Privileges")
            if not execute_command(
                ["sudo", "-v"], "Caching sudo credentials for requested tasks."
            ):
                print_error("Could not acquire sudo privileges. Aborting.")
                sys.exit(1)

        if args.bootstrap:
            if not args.dotfiles_url:
                parser.error("--bootstrap requires --dotfiles-url.")
            if not manager.run_bootstrap_checks(args.dotfiles_url):
                failed_tasks.append("Bootstrap")

        if args.install_packages:
            if manager.ensure_yay_installed():
                asus_pkgs, _ = manager.prompt_for_asus_setup()
                if not manager.run_package_installation(asus_pkgs):
                    failed_tasks.append("Package Installation")
            else:
                failed_tasks.append("Install yay")

        if args.configure_system:
            print_step("Applying System-Wide Configurations")
            if not os.path.isdir(DOTFILES_DIR):
                print_warning("Dotfiles directory not found. Some configs may fail.")
            for func, name in [
                (
                    system_config.configure_environment_variables,
                    "Set environment variables",
                ),
                (system_config.configure_security_limits, "Set security limits"),
                (system_config.configure_login_banners, "Set login banners"),
                (system_config.configure_sshd, "Configure SSH daemon"),
                (system_config.configure_symlinks, "Create system symlinks"),
                (
                    lambda: system_config.configure_system_services([]),
                    "Enable system services",
                ),
                (system_config.configure_shell, "Change default shell"),
            ]:
                if not func():
                    failed_tasks.append(name)

        if args.configure_user:
            print_step("Applying User-Specific Configurations")
            if not os.path.isdir(DOTFILES_DIR):
                print_warning("Dotfiles directory not found. Some configs may fail.")
            for func, name in [
                (user_config.configure_caelestia, "Configure Caelestia"),
                (user_services.configure_all_user_services, "Configure user services"),
                (user_config.configure_git, "Configure Git"),
                (user_config.configure_npm, "Configure NPM"),
            ]:
                if not func():
                    failed_tasks.append(name)

        if args.cleanup:
            print_step("Running Final System Cleanup")
            if not system_config.cleanup_orphan_packages():
                failed_tasks.append("Clean up orphan packages")

    print_step(f"{Icons.FINISH} Run Complete!")
    if not failed_tasks:
        print_success("All requested tasks finished successfully!")
    else:
        print_warning(f"Process finished with {len(failed_tasks)} error(s):")
        for failure in failed_tasks:
            print(f"  - {failure}")
        print_warning("Please review the output and the log file for details.")
        sys.exit(1)

    print(
        f"\n{Colors.BLUE}{Icons.INFO} A reboot may be needed to apply all changes.{Colors.ENDC}"
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
