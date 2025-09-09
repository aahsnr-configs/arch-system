{
  description =
    "An aggressively-optimized Python development environment using Clang and PGO";

  # Flake inputs: specify dependencies like nixpkgs
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  # Flake outputs: define what the flake provides
  outputs = { nixpkgs, ... }:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate outputs for each system
      forAllSystems = function:
        nixpkgs.lib.genAttrs supportedSystems (system: function system);
    in {
      # Development shell for each supported system
      devShells = forAllSystems (system:
        let
          # Import nixpkgs for the specific system
          pkgs = import nixpkgs { inherit system; };
          optimizedPython = pkgs.python313.override {
            stdenv = pkgs.clangStdenv;
            enableLTO = true;
            enableOptimizations = true;
          };

          # Python environment with a curated list of packages
          pythonEnv = optimizedPython.withPackages (ps:
            with ps; [
              # Jupyter ecosystem
              jupyter
              jupyterlab
              notebook
              ipython
              ipykernel
              ipywidgets
              nbconvert
              nbformat
              jupytext

              # Core scientific computing
              numpy
              scipy
              pandas
              matplotlib
              seaborn
              plotly

              # Data manipulation
              h5py
              openpyxl
              pyarrow
              polars

              # Development tools
              pip
              setuptools
              wheel
              pytest
              ruff
              bandit

              # Visualization
              pillow
              imageio
              bokeh

              # Performance libraries
              numba
              cython

              # Database connectivity
              psycopg2
              sqlalchemy

              # Web and utilities
              requests
              beautifulsoup4
              lxml
              tqdm
              click
              pydantic

              # Statistical analysis
              statsmodels
              sympy

              # Additional useful packages
              rich
              networkx

              # Scientific libraries
              scikit-learn
            ]);
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              optimizedPython
              pythonEnv

              # Provide clang in the shell for pip to use
              llvmPackages.clang

              # Essential system dependencies
              pkg-config
              libffi
              openssl
              zlib

              # Development tools
              git
              curl
              nix-index

              # Graphics libraries for matplotlib/plotting
              cairo
              pango
              gdk-pixbuf
              gobject-introspection
              fontconfig
              freetype

              # Mathematical libraries
              blas
              lapack
              openblas
              gfortran

              # Database libraries
              postgresql
              sqlite

              # Compression libraries
              bzip2
              xz
              lz4
              zstd

              # SSL certificates
              cacert

              # Performance libraries
              jemalloc
            ];

            # Native compilation flags passed to Nix builds
            NIX_CFLAGS_COMPILE =
              "-O3 -pipe -march=native -flto=thin -fno-math-errno -fno-signed-zeros -fno-trapping-math -fcf-protection -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-protector-strong -fstack-clash-protection -fplugin=LLVMPolly.so -mllvm=-polly -mllvm=-polly-vectorizer=stripmine -mllvm=-polly-omp-backend=LLVM -mllvm=-polly-parallel -mllvm=-polly-num-threads=9 -mllvm=-polly-scheduling=dynamic";
            NIX_CXXFLAGS_COMPILE =
              "-O3 -pipe -march=native -flto=thin -fno-math-errno -fno-signed-zeros -fno-trapping-math -fcf-protection -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-protector-strong -fstack-clash-protection -fplugin=LLVMPolly.so -mllvm=-polly -mllvm=-polly-vectorizer=stripmine -mllvm=-polly-omp-backend=LLVM -mllvm=-polly-parallel -mllvm=-polly-num-threads=9 -mllvm=-polly-scheduling=dynamic";
            NIX_LDFLAGS = "-Wl,-O1 -Wl,--as-needed";

            # Environment variables for any manual compilations inside the shell
            CFLAGS =
              "-O3 -pipe -march=native -flto=thin -fno-math-errno -fno-signed-zeros -fno-trapping-math -fcf-protection -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-protector-strong -fstack-clash-protection -fplugin=LLVMPolly.so -mllvm=-polly -mllvm=-polly-vectorizer=stripmine -mllvm=-polly-omp-backend=LLVM -mllvm=-polly-parallel -mllvm=-polly-num-threads=9 -mllvm=-polly-scheduling=dynamic";
            CXXFLAGS =
              "-O3 -pipe -march=native -flto=thin -fno-math-errno -fno-signed-zeros -fno-trapping-math -fcf-protection -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -fstack-protector-strong -fstack-clash-protection -fplugin=LLVMPolly.so -mllvm=-polly -mllvm=-polly-vectorizer=stripmine -mllvm=-polly-omp-backend=LLVM -mllvm=-polly-parallel -mllvm=-polly-num-threads=9 -mllvm=-polly-scheduling=dynamic";
            LDFLAGS = "-fuse-ld=lld -Wl,-O2 -Wl,--as-needed";

            # Python-specific compilation flags
            CPPFLAGS = "-I${optimizedPython}/include/python3.13";

            # Shell environment setup
            shellHook = ''
              echo "🚀 Aggressively-Optimized Python $(python --version | cut -d' ' -f2) Environment (Clang + PGO)"
              echo "🔧 Native compilation flags: -march=native -O3"

              # CPU information
              echo "🖥️  CPU Information:"
              if command -v lscpu >/dev/null 2>&1; then
                  echo "   $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
              elif [[ "$OSTYPE" == "darwin"* ]]; then
                  echo "   $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'macOS system')"
              fi
              echo ""

              # Set thread counts for parallel libraries
              export OPENBLAS_NUM_THREADS=''${OPENBLAS_NUM_THREADS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}
              export MKL_NUM_THREADS=''${MKL_NUM_THREADS:-$OPENBLAS_NUM_THREADS}
              export NUMEXPR_NUM_THREADS=''${NUMEXPR_NUM_THREADS:-$OPENBLAS_NUM_THREADS}
              export OMP_NUM_THREADS=''${OMP_NUM_THREADS:-$OPENBLAS_NUM_THREADS}
              export BLIS_NUM_THREADS=''${BLIS_NUM_THREADS:-$OPENBLAS_NUM_THREADS}

              # Use jemalloc for memory allocation performance
              if [[ -f "${pkgs.jemalloc}/lib/libjemalloc.so" ]]; then
                  export LD_PRELOAD="''${LD_PRELOAD:+$LD_PRELOAD:}${pkgs.jemalloc}/lib/libjemalloc.so"
                  export MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:30000,muzzy_decay_ms:30000"
              fi

              # Python performance optimizations
              export PYTHONDONTWRITEBYTECODE=1
              export PYTHONUNBUFFERED=1
              export PYTHONPATH="$PWD:$PYTHONPATH"

              # Ensure pip uses Clang and our compilation flags for native extensions
              export CC="clang"
              export CXX="clang++"

              # Jupyter configuration
              export JUPYTER_PATH="$PWD/.jupyter:$JUPYTER_PATH"
              export JUPYTER_CONFIG_DIR="$PWD/.jupyter"
              mkdir -p .jupyter

              # Install IPython kernel with optimization info
              if ! jupyter kernelspec list 2>/dev/null | grep -q "python3-native-clang"; then
                  python -m ipykernel install --user --name=python3-native-clang --display-name="Python 3 (Native Clang)" 2>/dev/null || true
              fi

              # Display active compilation environment
              echo "🔧 Active Compilation Environment:"
              echo "   CC: $(which clang 2>/dev/null || echo 'clang (from nixpkgs)')"
              echo "   CFLAGS: $CFLAGS"
              echo "   Threads: $OPENBLAS_NUM_THREADS cores"
              if [[ -n "''${LD_PRELOAD:-}" ]]; then
                  echo "   Memory: jemalloc enabled"
              fi
              echo ""

              echo "💡 Tip: Any pip-installed packages will be compiled with Clang and -march=native!"
              echo "🚀 Environment ready!"
            '';

            # Library paths for native-compiled extensions
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
              pkgs.libffi
              pkgs.openssl
              pkgs.blas
              pkgs.lapack
              pkgs.openblas
              pkgs.gfortran.cc.lib
              pkgs.jemalloc
            ];

            # PKG_CONFIG_PATH for building native extensions
            PKG_CONFIG_PATH =
              pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
                pkgs.libffi
                pkgs.openssl
                pkgs.zlib
                pkgs.openblas
              ];
          };
        });
    };
}
