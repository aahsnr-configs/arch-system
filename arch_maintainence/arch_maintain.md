## The Complete Arch Linux Administrator's Toolkit

This is a comprehensive suite of five scripts and a centralized helper library designed for the robust, automated maintenance of an Arch Linux system. It codifies expert recommendations from the Arch Wiki, focusing on security, integrity, and proactive maintenance. Each script is self-contained for ease of use and can be automated with the provided systemd units.

### 1. The New Script: `system-audit.sh`

This script is a powerful diagnostic tool that performs advanced checks that are critical for long-term stability and security. It's designed to be run periodically (e.g., monthly) to catch potential issues before they become problems.

```bash
#!/usr/bin/env bash
# ==============================================================================
#          FILE: system-audit.sh
#
#         USAGE: sudo ./system-audit.sh [-h|--help]
#
#   DESCRIPTION: Performs an advanced audit of system integrity, security,
#                and health based on Arch Linux community best practices.
#
#        AUTHOR: An Arch Wiki Contributor
# ==============================================================================
set -euo pipefail

# ==============================================================================
#                               CONFIGURATION
# ==============================================================================
LOG_FILE="/var/log/arch-maintenance.log"
MAINTENANCE_USER="${SUDO_USER:-$(whoami)}"

# The target size for the systemd journal after vacuuming.
# Suffixes like K, M, G are supported.
JOURNAL_VACUUM_SIZE="100M"
# ==============================================================================

# --- Source Helpers & Run Main ---
source /usr/local/bin/arch-maintenance-helpers

main() {
    log_msg "INFO" "Audit script started by ${MAINTENANCE_USER}."
    check_root
    info "${I_SHIELD} Starting Arch Linux System Audit..."
    echo

    # --- Run Audit Functions ---
    audit_journal_size
    audit_ssd_trim
    audit_package_integrity
    audit_open_ports

    log_msg "INFO" "Audit script finished successfully."
    success "${I_PARTY} System audit process completed!"
}

show_help() {
    echo "Usage: $(basename "$0") [-h|--help]"
    echo "  Performs an advanced audit of system integrity, security, and health."
    echo
    echo "  This script will:"
    echo "    1. Check systemd journal size and offer to vacuum it."
    echo "    2. Check if fstrim.timer is active for SSDs and offer a one-time trim."
    echo "    3. Verify the integrity of all installed packages."
    echo "    4. List all open network listening ports for security review."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

main "$@"
```

---

### 2. The Complete Script Toolkit

Here are the other four core scripts. They are all self-contained and ready to use.

#### **`system-update.sh`**

Performs a safe and comprehensive system update.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#                               CONFIGURATION
# ==============================================================================
LOG_FILE="/var/log/arch-maintenance.log"
AUR_HELPER="yay"
ENABLE_MIRROR_REFRESH=true
ENABLE_AUR_UPDATE=true
ARCH_NEWS_CHECK_DAYS=30
MAINTENANCE_USER="${SUDO_USER:-$(whoami)}"
# ==============================================================================

source /usr/local/bin/arch-maintenance-helpers

main() {
    log_msg "INFO" "Update script started by ${MAINTENANCE_USER}."
    check_root; check_internet; check_pacman_lock
    check_arch_news
    prompt "Proceed with the system update? [y/N]: "
    if [[ ! "${response,,}" =~ ^(y|yes)$ ]]; then
        log_msg "INFO" "User aborted update." && info "Update aborted." && exit 0
    fi
    update_keyring
    [[ "$ENABLE_MIRROR_REFRESH" == "true" ]] && refresh_mirrors
    update_packages
    [[ "$ENABLE_AUR_UPDATE" == "true" ]] && update_aur
    check_pacnew_files
    check_reboot_required
    log_msg "INFO" "Update script finished successfully."
    success "${I_PARTY} System update process completed!"
}
main "$@"
```

#### **`system-cleanup.sh`**

Removes orphaned packages and clears caches to free up disk space.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#                               CONFIGURATION
# ==============================================================================
LOG_FILE="/var/log/arch-maintenance.log"
MAINTENANCE_USER="${SUDO_USER:-$(whoami)}"
# ==============================================================================

source /usr/local/bin/arch-maintenance-helpers

main() {
    log_msg "INFO" "Cleanup script started by ${MAINTENANCE_USER}."
    check_root
    remove_orphans
    clean_pacman_cache
    clean_user_cache
    log_msg "INFO" "Cleanup script finished successfully."
    success "${I_PARTY} System cleanup process completed!"
}
main "$@"
```

#### **`system-health-check.sh`**

Performs routine checks on services, disk usage, and hardware health.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#                               CONFIGURATION
# ==============================================================================
LOG_FILE="/var/log/arch-maintenance.log"
MAINTENANCE_USER="${SUDO_USER:-$(whoami)}"
FS_USAGE_THRESHOLD=90
# ==============================================================================

source /usr/local/bin/arch-maintenance-helpers

main() {
    log_msg "INFO" "Health check script started by ${MAINTENANCE_USER}."
    check_root
    check_failed_services
    check_journal_errors
    check_fs_usage
    check_disk_health
    log_msg "INFO" "Health check script finished successfully."
    success "${I_PARTY} System health check completed!"
}
main "$@"
```

#### **`system-backup.sh`**

Creates a robust, versioned backup of critical system files and user data.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#                               CONFIGURATION
# ==============================================================================
LOG_FILE="/var/log/arch-maintenance.log"
MAINTENANCE_USER="${SUDO_USER:-$(whoami)}"
# IMPORTANT: You MUST change this path to your backup destination.
BACKUP_TARGET_DIR="/path/to/your/backups"
BACKUP_ROTATION_COUNT=3
HOME_BACKUP_EXCLUDE=(
    ".cache" "Downloads" ".gradle" ".m2" ".npm" ".Trash" "go/pkg" "*.tmp"
)
# ==============================================================================

source /usr/local/bin/arch-maintenance-helpers

main() {
    log_msg "INFO" "Backup script started by ${MAINTENANCE_USER}."
    check_root
    check_backup_target
    local timestamp
    timestamp=$(date +"%Y-%m-%d_%H%M%S")
    local current_backup_dir="${BACKUP_TARGET_DIR}/backup_${timestamp}"
    info "Creating new backup set at: ${current_backup_dir}"
    mkdir -p "$current_backup_dir"
    backup_packages "$current_backup_dir"
    backup_etc "$current_backup_dir"
    backup_home "$current_backup_dir"
    rotate_backups
    log_msg "INFO" "Backup script finished successfully."
    success "${I_PARTY} System backup process completed!"
}
main "$@"
```

---

### 3. The Centralized Helper Library

All the above scripts depend on this library. It contains all the shared functions, variables, and logic, preventing code duplication.

**Create this file at `/usr/local/bin/arch-maintenance-helpers`**

```bash
#!/usr/bin/env bash
# ==============================================================================
#           HELPER LIBRARY FOR THE ARCH LINUX ADMINISTRATOR'S TOOLKIT
# ==============================================================================
set -euo pipefail

# --- Colors and Icons ---
C_INFO='\033[0;34m'; C_SUCCESS='\033[0;32m'; C_WARN='\033[1;33m';
C_ERROR='\033[0;31m'; C_PROMPT='\033[0;36m'; C_RESET='\033[0m';
I_INFO="ℹ️"; I_SUCCESS="✅"; I_WARN="⚠️"; I_ERROR="❌"; I_PROMPT="❓";
I_ROCKET="🚀"; I_SATELLITE="🛰️"; I_LOCK="🔒"; I_KEY="🔑"; I_GLOBE="🌍";
I_BOX="📦"; I_PACMAN="👻"; I_CONFIG="⚙️"; I_REBOOT="🔄"; I_PARTY="🎉";
I_TRASH="🗑️"; I_BROOM="🧹"; I_GHOST="👻"; I_FOLDER="📁"; I_HEALTH="❤️";
I_SERVICE="⚙️"; I_JOURNAL="📋"; I_DISK="💾"; I_SAVE="💾";
I_NEWS="📰"; I_LINK="🔗"; I_SHIELD="🛡️"; I_NETWORK="🌐";

# --- Logging and Output Functions ---
log_msg() {
    local level=$1 message=$2 datetime
    datetime=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$datetime] [$level] $message" | sudo tee -a "$LOG_FILE" > /dev/null
}
info() { echo -e "${C_INFO}${I_INFO}  [INFO]${C_RESET} $1"; }
success() { echo -e "${C_SUCCESS}${I_SUCCESS}  [SUCCESS]${C_RESET} $1"; }
warn() { echo -e "${C_WARN}${I_WARN}  [WARNING]${C_RESET} $1"; }
error() { echo -e "${C_ERROR}${I_ERROR}  [ERROR]${C_RESET} $1"; }
prompt() { read -r -p "$(echo -e "${C_PROMPT}${I_PROMPT}  [PROMPT]${C_RESET} $1")" response; }

# --- Common Prerequisite Checks ---
check_root() {
    if [[ "$EUID" -eq 0 ]]; then
        error "This script must not be run as root. Run it as your normal user with 'sudo'."
        log_msg "ERROR" "Script aborted: ran as root."
        exit 1
    fi
    if ! sudo -n true 2>/dev/null; then
        error "Sudo permissions are required. You may be prompted for a password."
    fi
    if ! sudo touch "$LOG_FILE"; then
        error "Cannot write to log file $LOG_FILE. Check sudo permissions."
        exit 1
    fi
}

check_internet() {
    info "${I_SATELLITE} Checking for internet connectivity..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        error "No internet connection." && log_msg "ERROR" "Aborted: no internet." && exit 1
    fi
    success "Internet connection is active."
}

check_pacman_lock() {
    info "${I_LOCK} Checking for pacman lock file..."
    if [ -f /var/lib/pacman/db.lck ]; then
        error "Pacman lock file found!" && log_msg "ERROR" "Aborted: pacman lock." && exit 1
    fi
    success "No pacman lock file found."
}

# --- Update Script Functions ---
check_arch_news() {
    info "${I_NEWS} Checking for recent Arch Linux news..."
    local news_feed
    news_feed=$(curl -s "https://archlinux.org/feeds/news/" | xmlstarlet sel -t -m "//item" -v "concat(pubDate, ' ', title)" -n 2>/dev/null || echo "XML_PARSE_ERROR")
    if [[ "$news_feed" == "XML_PARSE_ERROR" ]]; then
        warn "Could not parse Arch News. Is 'xmlstarlet' installed?" && return
    fi
    local cutoff_date has_recent_news=0
    cutoff_date=$(date -d "-$ARCH_NEWS_CHECK_DAYS days" +%s)
    while read -r line; do
        local pub_date_str news_date title
        pub_date_str=$(echo "$line" | awk '{print $2, $3, $4}')
        news_date=$(date -d "$pub_date_str" +%s)
        title=$(echo "$line" | cut -d' ' -f6-)
        if [[ "$news_date" -ge "$cutoff_date" ]]; then
            [[ $has_recent_news -eq 0 ]] && warn "Recent news may require manual intervention:"
            echo -e "  - $(date -d "$pub_date_str" '+%Y-%m-%d'): ${C_WARN}${title}${C_RESET}"
            has_recent_news=1
        fi
    done <<< "$news_feed"
    [[ $has_recent_news -eq 0 ]] && success "No critical news in the last $ARCH_NEWS_CHECK_DAYS days."
}
update_keyring(){ info "${I_KEY} Updating archlinux-keyring..." && sudo pacman -S --noconfirm --needed archlinux-keyring; }
refresh_mirrors(){ info "${I_GLOBE} Refreshing mirrors..." && sudo reflector --quiet --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && success "Mirrorlist refreshed."; }
update_packages(){ info "${I_PACMAN} Updating official packages..." && sudo pacman -Syu; }
update_aur(){
    if ! command -v "$AUR_HELPER" &> /dev/null; then
        warn "AUR helper '$AUR_HELPER' not found." && return
    fi
    info "${I_BOX} Updating AUR packages..."
    sudo -u "$MAINTENANCE_USER" "$AUR_HELPER" -Sua
}
check_pacnew_files(){
    info "${I_CONFIG} Checking for .pacnew files..."
    if find /etc -name "*.pacnew" | read -r; then
        warn "Found .pacnew files. Use 'pacdiff' to merge."
    else
        success "No .pacnew files found."
    fi
}
check_reboot_required(){
    info "${I_REBOOT} Checking if a reboot is required..."
    [[ -f /var/run/reboot-required ]] && warn "Reboot is required." || success "No reboot flag found."
}

# --- Cleanup Script Functions ---
remove_orphans(){
    info "${I_GHOST} Checking for orphaned packages..."
    local orphans=$(pacman -Qtdq || true)
    if [ -z "$orphans" ]; then success "No orphaned packages found." && return; fi
    warn "Found orphaned packages."
    prompt "Do you want to remove them? [y/N]: "
    [[ "${response,,}" =~ ^(y|yes)$ ]] && sudo pacman -Rns $orphans
}
clean_pacman_cache(){
    info "${I_BROOM} Cleaning pacman cache..."
    prompt "Clean pacman cache (removes uninstalled package versions)? [y/N]: "
    [[ "${response,,}" =~ ^(y|yes)$ ]] && sudo paccache -r
}
clean_user_cache(){
    info "${I_FOLDER} Cleaning user cache..."
    local cache_dir="/home/$MAINTENANCE_USER/.cache"
    if [ ! -d "$cache_dir" ]; then info "Cache directory not found." && return; fi
    local cache_size=$(du -sh "$cache_dir" | awk '{print $1}')
    prompt "Your cache is $cache_size. Do you want to clear it? [y/N]: "
    [[ "${response,,}" =~ ^(y|yes)$ ]] && find "$cache_dir" -mindepth 1 -delete
}

# --- Health Check Script Functions ---
check_failed_services(){
    info "${I_SERVICE} Checking for failed systemd services..."
    ! systemctl --failed --quiet && success "No failed services." || (error "Found failed services:" && systemctl --failed --no-pager)
}
check_journal_errors(){
    info "${I_JOURNAL} Checking journal for errors..."
    ! journalctl -p 3 -b --quiet && success "No critical errors in journal." || warn "Errors found in journal. Review with 'journalctl -p 3 -b'."
}
check_fs_usage(){
    info "${I_DISK} Checking filesystem usage..."
    df -P --output=pcent,target | tail -n +2 | while read -r pcent target; do
        local usage=${pcent//\%/}
        [[ "$usage" -ge "$FS_USAGE_THRESHOLD" ]] && error "Filesystem at '$target' is at ${pcent}!"
    done
}
check_disk_health(){
    info "${I_DISK} Checking disk S.M.A.R.T. health..."
    if ! command -v smartctl &> /dev/null; then return; fi
    for disk in $(lsblk -d -o NAME,TYPE | grep 'disk' | awk '{print "/dev/"$1}'); do
        if sudo smartctl -i "$disk" | grep -q "SMART support is: Available - Enabled"; then
            ! sudo smartctl -H "$disk" | grep -q "test result: PASSED" && error "${disk} S.M.A.R.T. check: FAILED"
        fi
    done
}

# --- Audit Script Functions ---
audit_journal_size() {
    info "${I_JOURNAL} Auditing Systemd Journal size..."
    local current_size=$(journalctl --disk-usage | awk '{print $NF}')
    success "Current journal on-disk size is: ${current_size}"
    prompt "Vacuum journal to ${JOURNAL_VACUUM_SIZE}? [y/N]: "
    if [[ "${response,,}" =~ ^(y|yes)$ ]]; then
        info "Vacuuming journal..."
        sudo journalctl --vacuum-size="$JOURNAL_VACUUM_SIZE"
        local new_size=$(journalctl --disk-usage | awk '{print $NF}')
        success "Journal vacuumed. New size: ${new_size}"
    fi; echo
}
audit_ssd_trim() {
    info "${I_DISK} Auditing SSD TRIM status..."
    if [ "$(cat /sys/block/"$(lsblk -no pkname /)"/queue/rotational)" -eq 0 ]; then
        if systemctl is-enabled --quiet fstrim.timer; then
            success "'fstrim.timer' is enabled. No action needed."
        else
            warn "'fstrim.timer' is not enabled. Periodic TRIM is recommended."
            prompt "Perform a one-time TRIM on '/'? [y/N]: "
            [[ "${response,,}" =~ ^(y|yes)$ ]] && sudo fstrim -v /
        fi
    else
        info "Root filesystem is not on an SSD. TRIM is not applicable."
    fi; echo
}
audit_package_integrity() {
    info "${I_SHIELD} Auditing package integrity with 'pacman -Qkk'..."
    local issues=$(sudo pacman -Qkk 2>&1 | grep -v ', 0 missing files'$ || true)
    if [ -z "$issues" ]; then
        success "All packages passed the integrity check."
    else
        error "Package integrity issues were found! (modified/missing files)"
        echo "----------------------------------------------------------------------"
        echo "$issues"
        echo "----------------------------------------------------------------------"
        info "Re-install affected packages to restore original files, e.g., 'sudo pacman -S <package>'"
    fi; echo
}
audit_open_ports() {
    info "${I_NETWORK} Auditing open network listening ports..."
    if ! command -v ss &> /dev/null; then warn "'ss' not found ('iproute2' package)." && return; fi
    success "Found the following listening services:"
    echo "----------------------------------------------------------------------"
    ss -tulpn
    echo "----------------------------------------------------------------------"
    info "Review this list for any unexpected services."; echo
}

# --- Backup Script Functions ---
check_backup_target() {
    info "${I_SAVE} Verifying backup target directory..."
    if [[ "$BACKUP_TARGET_DIR" == "/path/to/your/backups" ]]; then
        error "Default backup path is not set! Please edit the script." && exit 1
    fi
    if [ ! -d "$BACKUP_TARGET_DIR" ]; then error "Backup target not found." && exit 1; fi
    if [ ! -w "$BACKUP_TARGET_DIR" ]; then error "Backup target not writable." && exit 1; fi
}
backup_packages() {
    local backup_dir=$1; info "Backing up package lists..."
    pacman -Qqe > "${backup_dir}/packages.list"
    pacman -Qqm > "${backup_dir}/packages_aur.list"
}
backup_etc() {
    local backup_dir=$1; info "Backing up /etc directory..."
    sudo rsync -aAX --delete /etc/ "${backup_dir}/etc/"
}
backup_home() {
    local backup_dir=$1; info "Backing up home directory..."
    local exclude_opts=()
    for item in "${HOME_BACKUP_EXCLUDE[@]}"; do exclude_opts+=(--exclude="$item"); done
    rsync -aAX --delete "${exclude_opts[@]}" "/home/$MAINTENANCE_USER/" "${backup_dir}/home/"
}
rotate_backups() {
    info "Rotating backups..."
    local backup_count=$(find "$BACKUP_TARGET_DIR" -maxdepth 1 -type d -name 'backup_*' | wc -l)
    if [ "$backup_count" -gt "$BACKUP_ROTATION_COUNT" ]; then
        local to_delete=$((backup_count - BACKUP_ROTATION_COUNT))
        warn "Deleting $to_delete oldest backup(s)..."
        find "$BACKUP_TARGET_DIR" -maxdepth 1 -type d -name 'backup_*' | sort | head -n "$to_delete" | xargs -r rm -rf
    fi
}
```

---

### 4. Automation and Logging with Systemd

To automate these scripts, create the following `systemd` unit files in `/etc/systemd/system/`.

#### **Systemd Unit Files**

- `/etc/systemd/system/arch-maintenance@.service`: A single, templated service file for all scripts.

  ```ini
  [Unit]
  Description=Run Arch Linux Maintenance Script: %i

  [Service]
  Type=oneshot
  # The %i will be replaced by the script name (e.g., "system-update")
  ExecStart=/usr/bin/flock -n /tmp/arch-maintenance.lock /usr/local/bin/%i.sh
  ```

- `/etc/systemd/system/arch-update.timer`: Runs weekly.

```ini
[Unit]
Description=Run weekly Arch Linux system update

[Timer]
OnCalendar=Sun 04:00:00
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

- `/etc/systemd/system/arch-backup.timer`: Runs daily.

  ```ini
  [Unit]
  Description=Run daily Arch Linux system backup

  [Timer]
  OnCalendar=daily
  RandomizedDelaySec=30m
  Persistent=true

  [Install]
  WantedBy=timers.target
  ```

- `/etc/systemd/system/arch-audit.timer`: Runs on the 15th of every month.

```ini
[Unit]
Description=Run monthly Arch Linux system audit

[Timer]
OnCalendar=*-*-15 05:00:00
RandomizedDelaySec=2h
Persistent=true

[Install]
WantedBy=timers.target
```

#### **How to Use and Monitor**

1.  **Placement:** Place all `.sh` scripts and the helper library in `/usr/local/bin/` and make them executable:

    ```sh
    sudo chmod +x /usr/local/bin/system-*.sh /usr/local/bin/arch-maintenance-helpers
    ```

    Place the systemd files in `/etc/systemd/system/`.

2.  **Configuration:** Edit the configuration block at the top of each script. **Crucially, you must change `BACKUP_TARGET_DIR` in `system-backup.sh`**.

3.  **Enable Timers:** Enable the timers. They will automatically start the corresponding `arch-maintenance@script-name.service`.

    ```sh
    sudo systemctl daemon-reload
    sudo systemctl enable --now arch-update.timer
    sudo systemctl enable --now arch-backup.timer
    sudo systemctl enable --now arch-audit.timer
    ```

4.  **Monitoring:**
    - **Check Timers:** `systemctl list-timers 'arch-*'`
    - **View Logs:** `tail -f /var/log/arch-maintenance.log`
    - **Check Service Status:** `journalctl -u arch-maintenance@system-audit.service`
