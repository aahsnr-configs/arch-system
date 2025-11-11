if not set -q argv[1]
    echo "Usage: se <search_pattern>"
    exit 1
end

set selection (rg --line-number --no-heading --smart-case "$argv[1]" | fzf \
    --height "80%" --layout "reverse" --info "inline" --border "rounded" \
    --delimiter ':' --no-multi \
    --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')

if test -n "$selection"
    set file (echo "$selection" | cut -d: -f1)
    set line_num (echo "$selection" | cut -d: -f2)
    $EDITOR "$file" "+$line_num"
end
