# arch_installer/utils.py
import logging
import os
import socket
import subprocess
from .ui import print_info, print_error


def execute_command(
    command: list[str], description: str, cwd: str | None = None
) -> bool:
    print_info(description)
    logging.info(f"Executing command: {' '.join(command)} in '{cwd or os.getcwd()}'")
    try:
        with subprocess.Popen(command, text=True, encoding="utf-8", cwd=cwd) as process:
            process.wait()
            if process.returncode != 0:
                raise subprocess.CalledProcessError(process.returncode, command)
        return True
    except (FileNotFoundError, subprocess.CalledProcessError, KeyboardInterrupt) as e:
        error_type = (
            "Command not found"
            if isinstance(e, FileNotFoundError)
            else "Process interrupted"
            if isinstance(e, KeyboardInterrupt)
            else "Command failed"
        )
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
