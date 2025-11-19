#!/bin/bash
# setup-github-multi-account.sh
#
# Sets up multiple GitHub accounts using unique SSH keys and Git's conditional includes.
# This script is FULLY IDEMPOTENT: Running it multiple times produces the same result.
# It safely removes old managed SSH keys and configs, then regenerates everything fresh.
#
# KEY FEATURES:
# - Uses ED25519 keys (modern standard, more secure & faster than RSA)
# - Uses core.sshCommand instead of URL rewriting (cleaner approach)
# - Proper includeIf syntax with trailing slashes
# - Comprehensive error handling and validation
# - Safe deletion and regeneration of SSH keys
# - Color-coded output for better readability

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# Pipefail: catch errors in pipes.
set -euo pipefail

# --- Configuration Variables ---
# Define accounts: [key_suffix]="email@address"
declare -A ACCOUNTS
ACCOUNTS["configs"]="ahsanur041@proton.me"
ACCOUNTS["personal"]="ahsanur041@gmail.com"
ACCOUNTS["work"]="aahsnr041@proton.me"
ACCOUNTS["common"]="ahsan.05rahman@gmail.com"

# Base name for the SSH key files and Git user names
KEY_BASE_NAME="aahsnr"
GIT_REPO_BASE="$HOME/git-repos"
SSH_CONFIG_FILE="$HOME/.ssh/config"
GIT_CONFIG_FILE="$HOME/.gitconfig"

# SSH Key algorithm - ED25519 is the modern standard (more secure and faster than RSA)
SSH_KEY_TYPE="ed25519"

# Markers for the managed SSH block (used for safe cleanup)
SSH_MARKER_START="# --- START: GH Multi-Account Config Managed by setup-github-multi-account.sh ---"
SSH_MARKER_END="# --- END: GH Multi-Account Config Managed by setup-github-multi-account.sh ---"

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Utility Functions ---

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

print_section() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}========================================${NC}"
}

# Function to check for required commands
check_prerequisites() {
  print_section "Checking Prerequisites"

  local missing_tools=()

  for cmd in ssh-keygen git gh; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_tools+=("$cmd")
    else
      print_success "$cmd is installed"
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    echo ""
    echo "Installation instructions:"
    echo "  - Arch Linux: sudo pacman -S openssh git github-cli"
    echo "  - Ubuntu/Debian: sudo apt install openssh-client git gh"
    echo "  - macOS: brew install git gh"
    exit 1
  fi

  print_success "All prerequisites are installed"
}

# Function to safely remove old SSH keys managed by this script
cleanup_old_ssh_keys() {
  print_info "Removing old SSH keys for managed accounts..."
  local keys_removed=0

  for account_name in "${!ACCOUNTS[@]}"; do
    local key_path="$HOME/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_${account_name}"
    local pub_key_path="${key_path}.pub"

    # Remove private key
    if [[ -f "$key_path" ]]; then
      rm -f "$key_path"
      print_success "Removed old private key: $key_path"
      ((keys_removed++))
    fi

    # Remove public key
    if [[ -f "$pub_key_path" ]]; then
      rm -f "$pub_key_path"
      print_success "Removed old public key: $pub_key_path"
      ((keys_removed++))
    fi

    # Remove key from SSH agent if it's loaded
    ssh-add -d "$key_path" 2>/dev/null || true
  done

  if [[ $keys_removed -eq 0 ]]; then
    print_info "No old SSH keys found to remove"
  else
    print_success "Removed $keys_removed old SSH key file(s)"
  fi
}

# Function to safely remove managed configurations
cleanup_old_configs() {
  print_section "Cleaning Up Old Configurations"

  # 1. Clean up managed SSH blocks using markers
  if [[ -f "$SSH_CONFIG_FILE" ]] && grep -q "$SSH_MARKER_START" "$SSH_CONFIG_FILE"; then
    print_info "Removing old SSH config block from $SSH_CONFIG_FILE..."
    # Use sed to delete lines between the start and end markers (inclusive)
    # Create backup before modifying
    cp "$SSH_CONFIG_FILE" "${SSH_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

    # macOS (BSD sed) requires different syntax than Linux (GNU sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/$SSH_MARKER_START/,/$SSH_MARKER_END/d" "$SSH_CONFIG_FILE"
    else
      sed -i "/$SSH_MARKER_START/,/$SSH_MARKER_END/d" "$SSH_CONFIG_FILE"
    fi

    print_success "Removed old SSH configuration"
  fi

  # 2. Remove old SSH keys (idempotent key deletion)
  cleanup_old_ssh_keys

  # 3. Clean up managed Git settings
  print_info "Removing old global Git settings..."
  git config --global --unset user.name 2>/dev/null || true
  git config --global --unset user.email 2>/dev/null || true
  git config --global --unset init.defaultBranch 2>/dev/null || true

  # Remove URL rewrites if they exist (safer method)
  local url_keys
  url_keys=$(git config --global --get-regexp '^url\..*\.insteadof' 2>/dev/null | cut -d' ' -f1 || true)
  for key in $url_keys; do
    git config --global --unset "$key" 2>/dev/null || true
  done

  # 4. Clean up conditional includes and config files
  for account_name in "${!ACCOUNTS[@]}"; do
    local config_path="$HOME/.gitconfig-${account_name}"
    local repo_path="$GIT_REPO_BASE/${account_name}/"

    # Remove the includeIf entry (correct syntax: unset the path, not remove-section)
    # The includeIf section format is: includeIf.gitdir:<path>.path
    git config --global --unset "includeIf.gitdir:${repo_path}.path" 2>/dev/null || true

    # Remove the account-specific config file
    if [[ -f "$config_path" ]]; then
      rm -f "$config_path"
      print_success "Removed conditional Git config file: $config_path"
    fi
  done

  print_success "Cleanup complete - ready for fresh setup"
}

# Function to generate fresh ED25519 SSH keys (always regenerates)
generate_key() {
  local account_name="$1"
  local email="$2"
  local key_path="$HOME/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_${account_name}"

  print_info "Generating fresh ED25519 SSH key for '$account_name' (Comment: $email)..."

  # Generate new key (this will overwrite if it somehow exists, ensuring idempotency)
  ssh-keygen -t "${SSH_KEY_TYPE}" -C "$email" -f "$key_path" -N "" >/dev/null 2>&1

  # Set secure permissions
  chmod 600 "$key_path"
  chmod 644 "$key_path.pub"

  print_success "Generated new key: $key_path"
}

# Function to set up the main .gitconfig and conditional include files
setup_git_config() {
  print_section "Setting Up Git Configuration"

  # Set a default account (configs)
  local DEFAULT_ACCOUNT="configs"

  # Set global defaults
  git config --global user.name "${KEY_BASE_NAME}-${DEFAULT_ACCOUNT}"
  git config --global user.email "${ACCOUNTS[${DEFAULT_ACCOUNT}]}"
  git config --global init.defaultBranch "main"
  print_success "Set global default Git user to '${DEFAULT_ACCOUNT}' account"

  # Create base repository directories (idempotent - mkdir -p won't fail if exists)
  mkdir -p "$GIT_REPO_BASE"/{configs,personal,work,common}
  print_success "Created/verified base repository directories"

  # Create account-specific config files with conditional includes
  for account_name in "${!ACCOUNTS[@]}"; do
    local config_path="$HOME/.gitconfig-${account_name}"
    local repo_path="$GIT_REPO_BASE/${account_name}/"
    local git_user_name="${KEY_BASE_NAME}-${account_name}"
    local git_email="${ACCOUNTS[$account_name]}"
    local key_path="$HOME/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_${account_name}"

    # Create the account-specific config file (overwrites if exists - idempotent)
    cat >"$config_path" <<EOF
[user]
  name = ${git_user_name}
  email = ${git_email}
[core]
  sshCommand = ssh -i ${key_path} -o IdentitiesOnly=yes
EOF

    print_success "Created Git config file: $config_path"

    # Add the includeIf block to the main .gitconfig
    # CRITICAL: The path MUST end with a trailing slash for recursive directory matching
    # Without the slash, it only matches that exact path
    git config --global "includeIf.gitdir:${repo_path}.path" "$config_path"
    print_success "Added includeIf condition for '${repo_path}'"
  done

  print_success "Git configuration complete"
}

# Function to append SSH configuration block to ~/.ssh/config
setup_ssh_config() {
  print_section "Setting Up SSH Configuration"

  # Create .ssh directory and config file if they don't exist (idempotent)
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$SSH_CONFIG_FILE"
  chmod 600 "$SSH_CONFIG_FILE"

  # Use a temporary file to build the new config content
  local TEMP_SSH_CONFIG
  TEMP_SSH_CONFIG=$(mktemp)

  # Add the start marker
  echo "$SSH_MARKER_START" >>"$TEMP_SSH_CONFIG"
  echo "" >>"$TEMP_SSH_CONFIG"

  # Loop through accounts to configure SSH blocks
  for account_name in "${!ACCOUNTS[@]}"; do
    local key_path="~/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_${account_name}"
    local host_alias="github.com-${KEY_BASE_NAME}-${account_name}"

    cat <<-EOF_SSH_BLOCK >>"$TEMP_SSH_CONFIG"
# GitHub account: ${account_name} (${ACCOUNTS[$account_name]})
Host ${host_alias}
  HostName github.com
  User git
  IdentityFile ${key_path}
  IdentitiesOnly yes
  AddKeysToAgent yes

EOF_SSH_BLOCK
  done

  # Add the end marker
  echo "$SSH_MARKER_END" >>"$TEMP_SSH_CONFIG"

  # Append the new managed block to the actual SSH config file
  cat "$TEMP_SSH_CONFIG" >>"$SSH_CONFIG_FILE"
  rm "$TEMP_SSH_CONFIG" # Clean up temporary file

  print_success "SSH configuration block added to $SSH_CONFIG_FILE"
}

# Function to configure GitHub CLI
setup_gh_config() {
  print_section "Configuring GitHub CLI"

  # gh configuration (these commands are idempotent by nature)
  gh config set git_protocol ssh 2>/dev/null || print_warning "Could not set gh git_protocol (might need authentication first)"
  gh config set editor nvim 2>/dev/null || print_warning "Could not set gh editor (might need authentication first)"

  # Set aliases for easy account switching (idempotent - overwrites existing)
  for account_name in "${!ACCOUNTS[@]}"; do
    gh alias set "auth-${account_name}" "auth switch --hostname github.com --user ${KEY_BASE_NAME}-${account_name}" 2>/dev/null || true
    print_success "Created alias: gh auth-${account_name}"
  done

  print_success "GitHub CLI configuration complete"
}

# Function to display next steps
show_next_steps() {
  echo ""
  print_section "✓ Multi-Account Setup Complete!"
  echo ""
  echo -e "${YELLOW}IMPORTANT: Manual Steps Required${NC}"
  echo ""
  echo -e "${GREEN}Step 1:${NC} Start SSH Agent and Add Keys"
  echo -e "   ${BLUE}eval \"\$(ssh-agent -s)\"${NC}"
  echo -e "   ${BLUE}ssh-add ~/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_*${NC}"
  echo ""
  echo -e "${GREEN}Step 2:${NC} Add Public Keys to GitHub Accounts"
  echo "   Copy each public key and add to corresponding GitHub account:"
  echo "   (GitHub → Settings → SSH and GPG keys → New SSH key)"
  echo ""
  for account_name in "${!ACCOUNTS[@]}"; do
    echo -e "   ${CYAN}${account_name}:${NC} ${BLUE}cat ~/.ssh/id_${SSH_KEY_TYPE}_${KEY_BASE_NAME}_${account_name}.pub${NC}"
  done
  echo ""
  echo -e "${GREEN}Step 3:${NC} Authenticate GitHub CLI for Each Account"
  echo -e "   ${BLUE}gh auth login --hostname github.com${NC}"
  echo "   (Run this 4 times, once for each account via browser flow)"
  echo ""
  echo -e "${GREEN}Step 4:${NC} Test SSH Connections"
  for account_name in "${!ACCOUNTS[@]}"; do
    echo -e "   ${BLUE}ssh -T git@github.com-${KEY_BASE_NAME}-${account_name}${NC}"
  done
  echo ""
  echo "   Expected: 'Hi ${KEY_BASE_NAME}-<account>! You've successfully authenticated...'"
  echo ""
  print_section "Usage Instructions"
  echo ""
  echo "Clone repositories into their respective directories:"
  echo ""
  echo -e "   ${BLUE}cd $GIT_REPO_BASE/personal${NC}"
  echo -e "   ${BLUE}git clone git@github.com:USERNAME/REPO.git${NC}"
  echo ""
  echo "Git will automatically use the correct identity and SSH key!"
  echo ""
  echo -e "${YELLOW}CRITICAL:${NC} You MUST be inside a git repository for includeIf to work."
  echo "The config only applies when you're in an initialized git repo."
  echo ""
  echo "Verify your configuration in any repository:"
  echo -e "   ${BLUE}cd $GIT_REPO_BASE/personal/some-repo${NC}"
  echo -e "   ${BLUE}git config user.name${NC}    # Should show account-specific name"
  echo -e "   ${BLUE}git config user.email${NC}   # Should show account-specific email"
  echo -e "   ${BLUE}git config core.sshCommand${NC}  # Should show account-specific key"
  echo ""
  print_section "Troubleshooting"
  echo ""
  echo "If you get 'Permission denied (publickey)' errors:"
  echo -e "   1. Verify SSH agent is running: ${BLUE}ssh-add -l${NC}"
  echo -e "   2. Test with verbose output: ${BLUE}ssh -vT git@github.com-${KEY_BASE_NAME}-<account>${NC}"
  echo "   3. Verify public key is added to correct GitHub account"
  echo ""
  echo "If commits show wrong user:"
  echo "   1. Ensure you're INSIDE a git repository (not just the parent directory)"
  echo "   2. Ensure you're in correct directory ($GIT_REPO_BASE/<account>/)"
  echo -e "   3. Check config loading: ${BLUE}git config --list --show-origin | grep user${NC}"
  echo -e "   4. Verify includeIf paths: ${BLUE}git config --list --show-origin | grep includeIf${NC}"
  echo ""
  echo "To re-run this setup (fully idempotent):"
  echo -e "   ${BLUE}bash $(basename "$0")${NC}"
  echo "   This will safely remove and regenerate all managed keys/configs"
  echo ""
  print_section "Script Completed Successfully"
  echo ""
}

# --- Main Script Execution ---

echo ""
print_section "GitHub Multi-Account Setup (Idempotent)"
echo -e "${CYAN}This script will safely remove and regenerate all SSH keys and configurations${NC}"
echo ""

# Phase 1: Prerequisites
check_prerequisites

# Phase 2: Complete Cleanup (removes old keys and configs)
cleanup_old_configs

# Phase 3: Fresh SSH Key Generation
print_section "Generating Fresh SSH Keys"
for account_name in "${!ACCOUNTS[@]}"; do
  generate_key "$account_name" "${ACCOUNTS[$account_name]}"
done

# Phase 4: Configuration Setup
setup_ssh_config
setup_git_config
setup_gh_config

# Phase 5: Display next steps
show_next_steps
