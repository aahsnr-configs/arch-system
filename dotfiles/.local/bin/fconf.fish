set config_dirs "$HOME" "$HOME/.config"

set selected (fd --type f --hidden . $config_dirs | fzf \
    --height "60%" --layout "reverse" --border "rounded" \
    --prompt="Edit Config > " --no-multi \
    --preview 'bat --style=numbers --color=always {}')

if test -n "$selected"
    $EDITOR "$selected"
end
