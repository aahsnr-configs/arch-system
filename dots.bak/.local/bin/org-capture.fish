#!/usr/bin/env fish

# Open an org-capture popup frame from the shell. This opens a temporary emacs
# daemon if emacs isn't already running.
#
# Usage: org-capture [-k KEY] [MESSAGE]
# Examples:
#   org-capture -k n "To the mind that is still, the whole universe surrenders."

function cleanup
    emacsclient --eval '(let (kill-emacs-hook) (kill-emacs))'
end

# If emacs isn't running, we start a temporary daemon, solely for this window.
if not emacsclient --suppress-output --eval nil 2>/dev/null
    echo "No Emacs daemon/server is available! Starting one..."
    emacs --daemon
    trap cleanup EXIT
    trap cleanup INT
    trap cleanup TERM
end

# org-capture key mapped to argument flags
set -l key nil
argparse 'h/help' 'k/key=' -- $argv
or begin
    echo "Usage: org-capture [-k KEY] [MESSAGE]" >&2
    exit 1
end

if set -q _flag_key
    set key "\"$_flag_key\""
end

# use remaining args, else read from stdin if passed a single dash
set -l str
if test (count $argv) -eq 1 -a "$argv[1]" = "-"
    set str (cat)
else
    set str (string join " " -- $argv)
end

# Fix incompatible terminals that cause odd 'not a valid terminal' errors
if test "$TERM" = "footclient"
    set -x TERM xterm-256color
end

# Non-daemon servers flicker a lot if frames are created from terminal, so we do
# it internally instead.
emacsclient -a "" \
    -e "(+org-capture/open-frame \"$str\" $key)"
