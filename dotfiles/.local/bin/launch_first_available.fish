if test (count $argv) -eq 0
    echo "Usage: (status filename) \"command1\" [\"command2 with-args\" ...]" >&2
    exit 1
end

for cmd_with_args in $argv
    if test -z "$cmd_with_args"
        continue
    end

    set -l command_name (string split -n -m 1 ' ' -- "$cmd_with_args")[1]

    if command -v "$command_name" &>/dev/null
        echo "Found command: '$command_name'. Launching..."
        eval "$cmd_with_args" &
        exit 0
    end
end

echo "Error: None of the specified commands were found." >&2
exit 1
