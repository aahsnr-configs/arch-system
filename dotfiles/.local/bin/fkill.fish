set pid (ps -ef | sed 1d | grep -v "$0" | fzf --height "40%" --layout "reverse" --no-multi | awk '{print $2}')

if test -n "$pid"
    set process_name (ps -p "$pid" -o comm=)
    read --nchars 1 --prompt-str "Are you sure you want to kill process $pid ($process_name)? [y/N] " reply
    echo
    if string match -qr '^[Yy]$' -- "$reply"
        kill -9 "$pid"
        echo "Process $pid ($process_name) killed."
    else
        echo "Kill operation aborted."
    end
end
