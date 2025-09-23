{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
    aggressiveResize = true;
    baseIndex = 1;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    shortcut = "a";
    terminal = "screen-256color";
    extraConfig = ''set -ga terminal-overrides ",*256col*:Tc"'';
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.vim-tmux-navigator
      tmuxPlugins.yank
      tmuxPlugins.resurrect
      tmuxPlugins.continuum
    ];
  };

  programs.tmate = {
    enable = true;
    extraConfig = ''
      set -g mouse on
      set -g default-terminal "screen-256color"
    '';
  };

  home.packages = [
    # Open tmux for current project.
    (pkgs.writeShellApplication {
      name = "pux";
      runtimeInputs = [ pkgs.tmux ];
      text = ''
        PRJ="$(zoxide query -i)"
        echo "Launching tmux for $PRJ"
        set -x
        cd "$PRJ" && \
          exec tmux -S "$PRJ".tmux attach
      '';
    })
  ];
}
