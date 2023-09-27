{ gcc11Stdenv
, cmake
, cudaPackages
, addOpenGLRunpath
, python310
, python310Packages }:
let
  buildDependencies = [
    cmake
    cudaPackages.cudatoolkit
    addOpenGLRunpath
  ];
  cppDependencies = [ python310 python310Packages.torch ];
  projectName = "NNPOps";
in gcc11Stdenv.mkDerivation {
  name = projectName;
  version =
    "0.6"; # Version based of https://github.com/conda-forge/nnpops-feedstock
  src = ./.;
  nativeBuildInputs = buildDependencies;
  buildInputs = cppDependencies;
  preConfigure = ''
    export CUDA_HOME=${cudaPackages.cudatoolkit}
    export CUDA_LIB=${cudaPackages.cudatoolkit.lib}
    export PYTHON_INSTALL_PATH=$out/${python310.sitePackages}
  '';
  propagatedBuildInputs = [ cudaPackages.cudatoolkit ];
}
