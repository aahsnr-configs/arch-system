# Adding to PATH
set -e fish_user_paths
set -U fish_user_paths $HOME/.cargo/bin $HOME/go/bin $HOME/.bun/bin $HOME/.local/bin $HOME/.config/emacs/bin $HOME/.npm-global/bin $HOME/.local/share/flatpak/exports/bin $fish_user_paths

# EXPORT
set TERMINAL kitty
set EDITOR nvim
set VISUAL "emacsclient -c -a emacs"
set PAGER "bat --paging=always --style=plain"

# "nvim" as manpager
set -x MANPAGER "nvim +Man!"

# SET EITHER DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
    # fish_default_key_bindings
    fish_vi_key_bindings
end

# Function for org-agenda
function org-search -d "send a search string to org-mode"
    set -l output (/usr/bin/emacsclient -a "" -e "(message \"%s\" (mapconcat #'substring-no-properties \
        (mapcar #'org-link-display-format \
        (org-ql-query \
        :select #'org-get-heading \
        :from  (org-agenda-files) \
        :where (org-ql--query-string-to-sexp \"$argv\"))) \
        \"
    \"))")
    printf $output
end

# Make su launch fish
function su
    command su --shell=/usr/bin/fish $argv
end

# Aliases
alias cat='bat --paging=never'
alias du='dust'
alias eza='eza --icons auto --git --group-directories-first --header'
alias fd='fd --hidden --no-ignore --absolute-path'
alias gg='lazygit'
alias grep='rg'
alias hm-switch='home-manager switch'
alias la='eza -a'
alias ll='eza -l'
alias lla='eza -la'
alias ls='eza'
alias lt='eza --tree'
alias nixs='nix-shell -p'
alias rmi='sudo rm -rf'
alias sctl='systemctl'
alias sctle='sudo systemctl enable'
alias sctls='sudo systemctl start'
alias vi='nvim'

# Options
set fish_greeting
set -g fish_key_bindings fish_vi_key_bindings

# Bind 'jk' to escape insert mode
bind -M insert jk 'set fish_bind_mode default; commandline -f repaint'

# Setup fzf
fzf --fish | source
set FZF_DEFAULT_OPTS "--layout=reverse --exact --border=bold --border=rounded --margin=3% --color=dark"

# Configure fzf previews for files (bat) and directories (eza)
set -x FZF_PREVIEW_COMMAND '
if test -f {};
  bat --color=always --style=numbers --line-range :500 {};
else;
  eza --tree --level=2 {};
 end'

# More Tools
zoxide init fish | source
starship init fish | source
pay-respects fish --alias | source
atuin init fish | source
direnv hook fish | source
