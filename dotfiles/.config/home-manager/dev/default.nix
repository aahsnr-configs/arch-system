# ~/.config/home-manager/dev/default.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    deadnix
    nixd
    nixfmt
    nixpkgs-fmt
    statix
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # not needed
    #enableFishIntegration = true;
    config.global.hide_env_diff = true;
  };
}
