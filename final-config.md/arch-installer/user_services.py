# arch_installer/user_services.py
import os
import shutil
from .config import USER_HOME
from .ui import Icons, print_error, print_info, print_step
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
        _create_service_file(
            "pyprland.service", _get_pyprland_service_content(pypr_path)
        )
    else:
        print_error("'pypr' not found, skipping service creation.")

    if wl_paste_path and cliphist_path:
        _create_service_file(
            "cliphist-text.service",
            _get_cliphist_service_content(
                f"{wl_paste_path} --watch {cliphist_path} store", "Text"
            ),
        )
        _create_service_file(
            "cliphist-image.service",
            _get_cliphist_service_content(
                f"{wl_paste_path} --type image/png --watch {cliphist_path} store",
                "Image",
            ),
        )
    else:
        print_error("'wl-paste' or 'cliphist' not found, skipping service creation.")

    # 2. Reload the systemd daemon to recognize the new files
    if not execute_command(
        ["systemctl", "--user", "daemon-reload"], "Reloading user systemd daemon."
    ):
        return False

    # 3. Enable all required user services (both custom and pre-packaged)
    print_info("Enabling user services.")
    services_to_enable = {
        "hypridle.service",
        "hyprpaper.service",
        "hyprpolkitagent.service",
        "hyprsunset.service",
        "pipewire.service",
        "pipewire.socket",
        "pipewire-pulse.service",
        "pipewire-pulse.socket",
        "uwsm.service",
        "wireplumber.service",
        "pyprland.service",
        "cliphist-text.service",
        "cliphist-image.service",
    }
    return execute_command(
        ["systemctl", "--user", "enable"] + sorted(list(services_to_enable)),
        "Enabling all user systemd services.",
    )
