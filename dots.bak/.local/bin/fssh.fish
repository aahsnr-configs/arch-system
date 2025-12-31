if not test -f "$HOME/.ssh/config"
    echo "SSH config file not found at ~/.ssh/config"
    exit 1
end

set host (grep '^Host ' "$HOME/.ssh/config" | awk '{print $2}' | grep -v '*' | fzf \
    --height "20%" --layout "reverse" --border "rounded" \
    --prompt="SSH to > " --no-multi)

if test -n "$host"
    ssh "$host"
end
