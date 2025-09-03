# arch_installer/ui.py
import logging
import sys
from .config import LOG_FILE


class Colors:
    HEADER, BLUE, GREEN, YELLOW, RED, ENDC, BOLD = (
        "\033[95m",
        "\033[94m",
        "\033[92m",
        "\033[93m",
        "\033[91m",
        "\033[0m",
        "\033[1m",
    )


class Icons:
    STEP, INFO, SUCCESS, WARNING, ERROR, PROMPT, FINISH, PACKAGE, DESKTOP, SECURITY = (
        "⚙️",
        "ℹ️",
        "✅",
        "⚠️",
        "❌",
        "❓",
        "🎉",
        "📦",
        "🖥️",
        "🛡️",
    )


def setup_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.FileHandler(LOG_FILE, mode="w", encoding="utf-8")],
    )


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
