{ pkgs, ... }:

let
  # A helper function to package a shell script and add it to the user's path.
  mkScript = name: text: pkgs.writeShellScriptBin name text;

  # A helper function for fish scripts.
  # This uses writeTextFile to allow for a custom shebang, as
  # writeShellApplication does not support interpreters other than bash.
  mkFishScript =
    name: text:
    pkgs.writeTextFile {
      inherit name;
      # The full script text, including the shebang line.
      text = "#!${pkgs.fish}/bin/fish\n" + text;
      # This makes the output file executable.
      executable = true;
      # The script will be placed in `bin/` inside the store path.
      destination = "/bin/${name}";
    };

in
{
  # A list of packages to be installed into the user environment.
  home.packages = [
    # --- Arch Linux Maintenance Scripts ---

    (mkScript "arch-maintain-update" ''
      #!/usr/bin/env bash
      #
      # Description: Safely updates an Arch Linux system.
      # Synchronizes package databases and upgrades all packages.
      #
      set -euo pipefail

      main() {
          if [[ $EUID -ne 0 ]]; then
             echo "Error: This script must be run as root." >&2
             echo "Please use 'sudo arch-maintain-update'" >&2
             exit 1
          fi

          echo "This script will synchronize pacman databases and perform a full system upgrade (pacman -Syu)."
          echo ""

          read -p "Do you want to proceed with the system update? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Update cancelled by user."
              exit 1
          fi

          echo "-> Starting system update..."
          pacman -Syu
          echo ""
          echo "✅ System update complete."
      }

      main
    '')

    (mkScript "arch-maintain-clean" ''
      #!/usr/bin/env bash
      #
      # Description: Cleans up the system by removing orphans and old package caches.
      #
      set -euo pipefail

      main() {
          if [[ $EUID -ne 0 ]]; then
             echo "Error: This script must be run as root." >&2
             echo "Please use 'sudo arch-maintain-clean'" >&2
             exit 1
          fi

          echo "This script will perform the following cleaning actions:"
          echo "  1. Remove all orphaned packages (dependencies no longer required)."
          echo "  2. Clean the pacman cache, keeping the most recent version of each package."
          echo ""

          read -p "Do you want to proceed with cleaning the system? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Cleaning process cancelled by user."
              exit 1
          fi

          # Remove orphaned packages
          echo "-> Checking for orphaned packages..."
          # The `|| true` prevents the script from exiting if no orphans are found
          if pacman -Qtdq &>/dev/null; then
              echo "Orphans found. Proceeding with removal..."
              pacman -Rns "$(pacman -Qtdq)"
          else
              echo "No orphaned packages to remove."
          fi
          echo ""

          # Clean package cache
          echo "-> Cleaning pacman cache..."
          echo "This will remove all package versions except for the most recent one."
          paccache -rk1
          echo ""
          echo "✅ System cleaning complete."
      }

      main
    '')

    (mkScript "arch-maintain-check-services" ''
      #!/usr/bin/env bash
      #
      # Description: Checks for any failed systemd services.
      #
      set -euo pipefail

      main() {
          echo "This script will check for any failed systemd services (system-level)."
          echo ""

          read -p "Do you want to proceed? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Operation cancelled by user."
              exit 1
          fi

          echo "-> Checking for failed services..."
          # Use an if statement to provide a clearer message
          if ! systemctl --failed --no-legend --no-pager | grep .; then
              echo "✅ No failed systemd services found."
          else
              echo "❗️ Found failed systemd services:"
              systemctl --failed --no-pager
          fi
      }

      main
    '')

    (mkScript "arch-maintain-all" ''
      #!/usr/bin/env bash
      #
      # Description: Runs a full weekly maintenance routine for Arch Linux.
      #
      set -euo pipefail

      main() {
          if [[ $EUID -ne 0 ]]; then
             echo "Error: This script must be run as root." >&2
             echo "Please use 'sudo arch-maintain-all'" >&2
             exit 1
          fi

          echo "This script will run a full maintenance routine in the following order:"
          echo "  1. Update System (arch-maintain-update)"
          echo "  2. Clean System (arch-maintain-clean)"
          echo "  3. Check Services (arch-maintain-check-services)"
          echo ""
          echo "You will be prompted to confirm each major step."
          echo ""

          read -p "Do you want to start the full maintenance routine? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Maintenance routine cancelled."
              exit 1
          fi

          echo "--- Starting Step 1: System Update ---"
          arch-maintain-update
          echo "--------------------------------------"
          echo ""

          echo "--- Starting Step 2: System Clean ---"
          arch-maintain-clean
          echo "-------------------------------------"
          echo ""

          echo "--- Starting Step 3: Check Services ---"
          arch-maintain-check-services
          echo "---------------------------------------"
          echo ""

          echo "✅ Full maintenance routine complete."
      }

      main
    '')

    # --- General Purpose Scripts ---

    (mkScript "safe-rm" ''
      #!/usr/bin/env bash
      set -euo pipefail
      readonly TRASH_DIR="$HOME/.local/share/trash/files"

      main() {
          if [ "$#" -eq 0 ]; then
              echo "Error: No files or directories specified." >&2
              echo "Usage: $0 <file1> [<file2> ...]" >&2
              exit 1
          fi

          local targets=()
          for item in "$@"; do
              if [ ! -e "$item" ]; then
                  echo "Warning: '$item' not found, skipping." >&2
                  continue
              fi

              mkdir -p "$TRASH_DIR"
              if [ "$(realpath -- "$item")" == "$(realpath -- "$TRASH_DIR")" ]; then
                  echo "Warning: Cannot move the trash directory into itself. Skipping '$item'." >&2
                  continue
              fi
              targets+=("$item")
          done

          if [ ''${#targets[@]} -eq 0 ]; then
              echo "No valid files or directories to move to trash."
              exit 0
          fi

          echo "The following items will be moved to the trash:"
          printf "  - %s\n" "''${targets[@]}"
          echo "Trash location: $TRASH_DIR"
          echo ""

          read -p "Are you sure you want to continue? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Operation cancelled by user."
              exit 1
          fi

          echo "Moving items to trash..."
          for item in "''${targets[@]}"; do
              local trashed_name
              trashed_name="$(basename "$item")-$(date +%s)-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 5)"
              echo " - '$item' -> '$trashed_name'"
              mv -- "$item" "$TRASH_DIR/$trashed_name"
          done

          echo ""
          echo "✅ Operation complete."
          echo "To restore, check the trash directory: $TRASH_DIR"
      }

      main "$@"
    '')

    (mkScript "nuke-nvim" ''
      #!/usr/bin/env bash
      set -euo pipefail

      readonly NVIM_DIRS=(
          "$HOME/.config/nvim"
          "$HOME/.local/state/nvim"
          "$HOME/.local/share/nvim"
      )

      main() {
          echo "This script will permanently delete the following Neovim directories:"
          for dir in "''${NVIM_DIRS[@]}"; do
              echo "  - ''${dir}"
          done
          echo ""

          read -p "Are you sure you want to continue? (Y/n): " -r REPLY
          echo ""

          if [[ -n "$REPLY" ]]; then
              echo "Operation cancelled by user."
              exit 1
          fi

          echo ""
          echo "Starting removal process..."

          for dir in "''${NVIM_DIRS[@]}"; do
              if [ -d "$dir" ]; then
                  echo "Removing ''${dir}..."
                  rm -rf "$dir"
              else
                  echo "Directory ''${dir} not found, skipping."
              fi
          done

          echo ""
          echo "Successfully removed Neovim directories."
      }

      main
    '')

    (mkScript "setup-github-keys" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "Setting up SSH keys for multiple GitHub accounts..."
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh

      generate_key() {
          local key_name="$1"
          local email="$2"
          local key_path="$HOME/.ssh/id_rsa_$key_name"

          if [[ ! -f "$key_path" ]]; then
              echo "Generating RSA 4096 SSH key for '$key_name'..."
              ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path" -N ""
              chmod 600 "$key_path"
              chmod 644 "$key_path.pub"
              echo "-> Generated key: $key_path"
          else
              echo "-> Key for '$key_name' already exists: $key_path"
          fi
      }

      generate_key "aahsnr_configs" "ahsanur041@proton.me"
      generate_key "aahsnr_personal" "ahsanur041@gmail.com"
      generate_key "aahsnr_work" "aahsnr041@proton.me"
      generate_key "aahsnr_common" "ahsan.05rahman@gmail.com"

      echo ""
      echo "✅ Setup complete!"
      echo ""
      echo "Next Steps:"
      echo "1. Add the public keys to your respective GitHub accounts:"
      echo "   - Configs:  cat ~/.ssh/id_rsa_aahsnr_configs.pub"
      echo "   - Personal: cat ~/.ssh/id_rsa_aahsnr_personal.pub"
      echo "   - Work:     cat ~/.ssh/id_rsa_aahsnr_work.pub"
      echo "   - Common:   cat ~/.ssh/id_rsa_aahsnr_common.pub"
      echo ""
      echo "2. Authenticate each account with the GitHub CLI (run these one by one):"
      echo "   gh auth login --hostname github.com"
      echo "   (You will need to do this for each of your accounts)"
      echo ""
      echo "3. Test your SSH connections:"
      echo "   ssh -T git@github.com-aahsnr-configs"
      echo "   ssh -T git@github.com-aahsnr-personal"
      echo "   ssh -T git@github.com-aahsnr-work"
      echo "   ssh -T git@github.com-aahsnr-common"
      echo ""
      echo "4. Create your project directories:"
      echo "   mkdir -p ~/Git/configs ~/Git/personal ~/Git/work ~/Git/common"
    '')

    (mkScript "launch_first_available" ''
      #!/usr/bin/env bash
      for cmd in "$@"; do
          [[ -z "$cmd" ]] && continue
          eval "command -v ''${cmd%% *}" >/dev/null 2&>1 || continue
          eval "$cmd" &
          exit
      done
    '')

    (mkScript "fuzzel-emoji" ''
      #!/bin/bash
      set -euo pipefail

      MODE="''${1:-type}"

      # The emoji data is stored in a variable and piped directly to fuzzel.
      DATA="
      😀 grinning face face smile happy joy :D grin
      😃 grinning face with big eyes face happy joy haha :D :) smile funny
      😄 grinning face with smiling eyes face happy joy funny haha laugh like :D :) smile
      😁 beaming face with smiling eyes face happy smile joy kawaii
      😆 grinning squinting face happy joy lol satisfied haha face glad XD laugh
      😅 grinning face with sweat face hot happy laugh sweat smile relief
      🤣 rolling on the floor laughing face rolling floor laughing lol haha rofl
      😂 face with tears of joy face cry tears weep happy happytears haha
      🙂 slightly smiling face face smile
      🙃 upside down face face flipped silly smile
      😉 winking face face happy mischievous secret ;) smile eye
      😊 smiling face with smiling eyes face smile happy flushed crush embarrassed shy joy
      😇 smiling face with halo face angel heaven halo
      🥰 smiling face with hearts face love like affection valentines infatuation crush hearts adore
      😍 smiling face with heart eyes face love like affection valentines infatuation crush heart
      🤩 star struck face smile starry eyes grinning
      😘 face blowing a kiss face love like affection valentines infatuation kiss
      😗 kissing face love like face 3 valentines infatuation kiss
      ☺️ smiling face face blush massage happiness
      😚 kissing face with closed eyes face love like affection valentines infatuation kiss
      😙 kissing face with smiling eyes face affection valentines infatuation kiss
      😋 face savoring food happy joy tongue smile face silly yummy nom delicious savouring
      😛 face with tongue face prank childish playful mischievous smile tongue
      😜 winking face with tongue face prank childish playful mischievous smile wink tongue
      🤪 zany face face goofy crazy
      😝 squinting face with tongue face prank playful mischievous smile tongue
      🤑 money mouth face face rich dollar money
      🤗 hugging face face smile hug
      🤭 face with hand over mouth face whoops shock surprise
      🤫 shushing face face quiet shhh
      🤔 thinking face face hmmm think consider
      🤐 zipper mouth face face sealed zipper secret
      🤨 face with raised eyebrow face distrust scepticism disapproval disbelief surprise
      😐 neutral face indifference meh :| neutral
      😑 expressionless face face indifferent - - meh deadpan
      😶 face without mouth face hellokitty
      😏 smirking face face smile mean prank smug sarcasm
      😒 unamused face indifference bored straight face serious sarcasm unimpressed skeptical dubious side eye
      🙄 face with rolling eyes face eyeroll frustrated
      😬 grimacing face face grimace teeth
      🤥 lying face face lie pinocchio
      😌 relieved face face relaxed phew massage happiness
      😔 pensive face face sad depressed upset
      😪 sleepy face face tired rest nap
      🤤 drooling face face
      😴 sleeping face face tired sleepy night zzz
      😷 face with medical mask face sick ill disease
      🤒 face with thermometer sick temperature thermometer cold fever
      🤕 face with head bandage injured clumsy bandage hurt
      🤢 nauseated face face vomit gross green sick throw up ill
      🤮 face vomiting face sick
      🤧 sneezing face face gesundheit sneeze sick allergy
      🥵 hot face face feverish heat red sweating
      🥶 cold face face blue freezing frozen frostbite icicles
      🥴 woozy face face dizzy intoxicated tipsy wavy
      😵 dizzy face spent unconscious xox dizzy
      🤯 exploding head face shocked mind blown
      🤠 cowboy hat face face cowgirl hat
      🥳 partying face face celebration woohoo
      😎 smiling face with sunglasses face cool smile summer beach sunglass
      🤓 nerd face face nerdy geek dork
      🧐 face with monocle face stuffy wealthy
      😕 confused face face indifference huh weird hmmm :/
      😟 worried face face concern nervous :(
      🙁 slightly frowning face face frowning disappointed sad upset
      ☹️ frowning face face sad upset frown
      😮 face with open mouth face surprise impressed wow whoa :O
      😯 hushed face face woo shh
      😲 astonished face face xox surprised poisoned
      😳 flushed face face blush shy flattered sex
      🥺 pleading face face begging mercy
      😦 frowning face with open mouth face aw what
      😧 anguished face face stunned nervous
      😨 fearful face face scared terrified nervous oops huh
      😰 anxious face with sweat face nervous sweat
      😥 sad but relieved face face phew sweat nervous
      😢 crying face face tears sad depressed upset :'(
      😭 loudly crying face face cry tears sad upset depressed sob
      😱 face screaming in fear face munch scared omg
      😖 confounded face face confused sick unwell oops :S
      😣 persevering face face sick no upset oops
      😞 disappointed face face sad upset depressed :(
      😓 downcast face with sweat face hot sad tired exercise
      😩 weary face face tired sleepy sad frustrated upset
      😫 tired face sick whine upset frustrated
      🥱 yawning face tired sleepy
      😤 face with steam from nose face gas phew proud pride
      😡 pouting face angry mad hate despise
      😠 angry face mad face annoyed frustrated
      🤬 face with symbols on mouth face swearing cursing cssing profanity expletive
      😈 smiling face with horns devil horns
      👿 angry face with horns devil angry horns
      💀 skull dead skeleton creepy death
      ☠️ skull and crossbones poison danger deadly scary death pirate evil
      💩 pile of poo hankey shitface fail turd shit
      🤡 clown face face
      👹 ogre monster red mask halloween scary creepy devil demon japanese ogre
      👺 goblin red evil mask monster scary creepy japanese goblin
      👻 ghost halloween spooky scary
      👽 alien UFO paul weird outer space
      👾 alien monster game arcade play
      🤖 robot computer machine bot
      😺 grinning cat animal cats happy smile
      😸 grinning cat with smiling eyes animal cats smile
      😹 cat with tears of joy animal cats haha happy tears
      😻 smiling cat with heart eyes animal love like affection cats valentines heart
      😼 cat with wry smile animal cats smirk
      😽 kissing cat animal cats kiss
      🙀 weary cat animal cats munch scared scream
      😿 crying cat animal tears weep sad cats upset cry
      😾 pouting cat animal cats
      🙈 see no evil monkey monkey animal nature haha
      🙉 hear no evil monkey animal monkey nature
      🙊 speak no evil monkey monkey animal nature omg
      💋 kiss mark face lips love like affection valentines
      💌 love letter email like affection envelope valentines
      💘 heart with arrow love like heart affection valentines
      💝 heart with ribbon love valentines
      💖 sparkling heart love like affection valentines
      💗 growing heart like love affection valentines pink
      💓 beating heart love like affection valentines pink heart
      💞 revolving hearts love like affection valentines
      💕 two hearts love like affection valentines heart
      💟 heart decoration purple-square love like
      ❣️ heart exclamation decoration love
      💔 broken heart sad sorry break heart heartbreak
      ❤️ red heart love like valentines
      🧡 orange heart love like affection valentines
      💛 yellow heart love like affection valentines
      💚 green heart love like affection valentines
      💙 blue heart love like affection valentines
      💜 purple heart love like affection valentines
      🤎 brown heart coffee
      🖤 black heart evil
      🤍 white heart pure
      "

      # Trim leading whitespace from the DATA variable before piping to fuzzel
      emoji="$(echo -e "''${DATA}" | sed 's/^[ \t]*//' | fuzzel --match-mode fzf --dmenu | cut -d ' ' -f 1 | tr -d '\n')"

      # Exit gracefully if fuzzel was cancelled and no emoji was selected
      if [[ -z "''${emoji}" ]]; then
          exit 0
      fi

      case "$MODE" in
          type)
              wtype "''${emoji}" || wl-copy "''${emoji}"
              ;;
          copy)
              wl-copy "''${emoji}"
              ;;
          both)
              wtype "''${emoji}" || true
              wl-copy "''${emoji}"
              ;;
          *)
              echo "Usage: $0 [type|copy|both]"
              exit 1
              ;;
      esac
    '')

    (mkFishScript "wsaction" ''
      if test "$argv[1]" = '-g'
       set group
       set -e $argv[1]
      end

      if test (count $argv) -ne 2
       echo 'Wrong number of arguments. Usage: ./wsaction.fish [-g] <dispatcher> <workspace>'
       exit 1
      end

      set -l active_ws (hyprctl activeworkspace -j | jq -r '.id')

      if set -q group
       # Move to group
       hyprctl dispatch $argv[1] (math "($argv[2] - 1) * 10 + $active_ws % 10")
      else
       # Move to ws in group
       hyprctl dispatch $argv[1] (math "floor(($active_ws - 1) / 10) * 10 + $argv[2]")
      end
    '')
  ];
}
