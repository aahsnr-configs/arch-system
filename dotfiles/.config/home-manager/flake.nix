{
  description = "Home Manager configuration of ahsan";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    systems.url = "github:nix-systems/default-linux";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = {
    nixpkgs,
    home-manager,
    yazi,
    rust-overlay,
    catppuccin,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    homeConfigurations."ahsan" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {inherit system;};
      extraSpecialArgs = {
        inherit inputs;
        inherit yazi;
        inherit rust-overlay;
        inherit catppuccin;
      };

      # Specify your home configuration modules here, for example,
      # the path to your home.nix.
      modules = [./home.nix catppuccin.homeModules.catppuccin];
    };
  };
}
