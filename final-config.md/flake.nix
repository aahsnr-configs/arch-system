{
  description = "A high-performance Python development environment with LTO and PGO";

  inputs = {nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";};

  outputs = {
    self,
    nixpkgs,
  }: let
    # Define supported systems
    supportedSystems = ["x86_64-linux"];

    # Helper function to generate outputs for each supported system
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    # The development shell for each system
    devShells = forAllSystems (system: let
      # Import nixpkgs for the specific system
      pkgs = import nixpkgs {inherit system;};

      # Create a Python interpreter with Link-Time Optimization (LTO) and
      # Profile-Guided Optimization (PGO) enabled for maximum performance.
      # `enableOptimizations` is the flag that enables PGO.
      optimizedPython = pkgs.python313.override {
        enableLTO = true;
        enableOptimizations = true;
      };

      # Create a complete Python environment using the optimized interpreter.
      # This single derivation will contain the interpreter and all packages.
      pythonEnv = optimizedPython.withPackages (ps:
        with ps; [
          pip
          wheel
          setuptools
          ruff
          mypy
          bandit
          debugpy
          pytest
          pytest-cov
          jupyterlab
          ipython
          numpy
          pandas
          matplotlib
        ]);
    in {
      # This is the default shell activated by `nix develop`
      default = pkgs.mkShell {
        # The only input needed is the self-contained Python environment.
        # Nix automatically makes all executables (python, pip, ruff, etc.)
        # available in the shell's PATH.
        buildInputs = [pythonEnv pkgs.pyright];

        # A welcoming message for when the shell is activated
        shellHook = ''
          echo "Welcome to the Optimized Python Environment!"
          echo "Python version: $(python --version)"
          echo "Available tools: python, pip, ruff, mypy, pytest, jupyterlab, ipython"
        '';
      };
    });
  };
}
