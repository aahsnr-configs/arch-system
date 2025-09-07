# arch_installer/config.py
import os

LOG_FILE: str = "arch_setup.log"
USER_HOME: str = os.path.expanduser("~")
CURRENT_USER: str = os.getlogin()
DOTFILES_DIR: str = os.path.join(USER_HOME, ".dots")
