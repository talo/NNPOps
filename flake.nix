{
  description = "High-performance operations for neural network potentials";

  # Flake inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05"; # also valid: "nixpkgs"
  };

  # Flake outputs
  outputs = { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs =
          import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };
      });

    in
    {
      # Development environment output
      devShells = forAllSystems ({ pkgs }: {
        built = pkgs.mkShell {
          packages = [
            (pkgs.python3.withPackages
              (pkgs: [
                self.packages.x86_64-linux.nnpops-python
                ]
              )
            )
          ];

          shellHook = "
          echo 'You are in a nix shell'
          ";
        };
        default = pkgs.mkShell {
          # The Nix packages provided in the environment
          packages = with pkgs; [
            direnv # For setting nix enviroment
            gcc12 # The GNU Compiler Collection
            cmake
            cudaPackages.cudatoolkit
            # Other libraries
            python3
            python310Packages.torch
          ];
          shellHook = "
          echo 'You are in a nix shell'
          export LD_LIBRARY_PATH=${pkgs.cudaPackages.cudatoolkit.lib}/lib:$LD_LIBRARY_PATH
          export CUDA_HOME=${pkgs.cudaPackages.cudatoolkit}
          export CUDA_LIB=${pkgs.cudaPackages.cudatoolkit.lib}
          ";
        };
      });

      packages = forAllSystems ({ pkgs }: {
        nnpops-python = pkgs.python310Packages.toPythonModule self.packages.x86_64-linux.default;
        default =
          let
            buildDependencies = with pkgs ; [
              cmake
              cudaPackages.cudatoolkit
              addOpenGLRunpath
            ];
            cppDependencies = with pkgs; [
              python3
              python310Packages.torch
            ];
            projectName = "nnpops";
          in
          pkgs.gcc11Stdenv.mkDerivation {
            name = projectName;
            version = "0.6"; # Version based of https://github.com/conda-forge/nnpops-feedstock
            src = ./.;
            nativeBuildInputs = buildDependencies;
            buildInputs = cppDependencies;
            preConfigure = ''
              export CUDA_HOME=${pkgs.cudaPackages.cudatoolkit}
              export CUDA_LIB=${pkgs.cudaPackages.cudatoolkit.lib}
              export PYTHON_INSTALL_PATH=$out/${pkgs.python3.sitePackages}
            '';
            propagatedBuildInputs = [
              pkgs.cudaPackages.cudatoolkit
            ];
          };
      });
    };
}