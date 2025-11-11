set selected (fd --type f --hidden --follow --exclude .git . | fzf \
    --height "80%" --layout "reverse" --info "inline" --border "rounded" \
    --preview 'bat --style=numbers --color=always --line-range :500 {}' \
    --query="$argv[1]" --select-1 --exit-0 --no-multi)

if test -n "$selected"
    $EDITOR "$selected"
end
