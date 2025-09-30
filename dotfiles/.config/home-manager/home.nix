{ ... }:
{
  home = {
    username = "ahsan";
    homeDirectory = "/home/ahsan";
    stateVersion = "25.11";
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];

  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  imports = [
    # ./atuin
    # ./bat
    # ./btop
    ./catppuccin
    ./dev
    # ./eza
    # ./fd-find
    # ./fish
    # ./fzf
    ./git
    ./keyring
    ./lazygit
    # ./pay-respects
    # ./pkgs
    # ./ripgrep
    ./scripts
    # ./starship
    ./systemd
    # ./texlive
    ./theming
    # ./tmux
    # ./yazi
    # ./zoxide
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnfreePredicate = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
