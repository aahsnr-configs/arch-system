fd --hidden --follow --exclude .git | fzf --height "80%" --layout "reverse" --border "rounded" \
    --preview-window "right:50%:wrap" \
    --preview '
        set file_path "{}"
        if test -d "$file_path"
            eza --color=always --tree --level=2 "$file_path" \
            || tree -C -L 2 "$file_path" \
            || ls -lF --color=always "$file_path"
        else if string match --quiet "image/*" -- (file --mime --brief "$file_path")
            chafa --size (tput cols)x(tput lines) "$file_path"
        else
            bat --style=numbers --color=always "$file_path"
        end
    '
