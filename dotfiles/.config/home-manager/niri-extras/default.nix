{
  inputs,
  pkgs,
  ...
}:
let
  inherit (inputs.nfsm-flake.packages.${pkgs.stdenv.hostPlatform.system}) nfsm nfsm-cli;
in
{

  home.packages = [
    nfsm
    nfsm-cli
    inputs.niri-switch.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
