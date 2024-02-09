{
  description =
    "ollama: Get up and running with Llama 2, Mistral, and other large language models locally";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    ollama = {
      url = "git+https://github.com/jmorganca/ollama?ref=refs/tags/v0.1.24&submodules=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unfree, utils, gomod2nix, ollama, ... }:
    (utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "i686-linux"
    ]
      (system:
        let
          pname = "ollama";
          version = "0.1.24";

          pkgs = nixpkgs.legacyPackages.${system};
          pkgsUnfree = nixpkgs-unfree.legacyPackages.${system};
          inherit (pkgs) lib rocmPackages;
          inherit (pkgsUnfree) cudaPackages linuxPackages;

          rocmClang = pkgs.linkFarm "rocm-clang" {
            llvm = rocmPackages.llvm.clang;
          };
          rocmPath = pkgs.buildEnv {
            name = "rocm-llvm";
            paths = [
              rocmClang
              rocmPackages.rocm-device-libs
            ];
          };

          cudaToolkit = pkgs.buildEnv {
            name = "cuda-toolkit";
            ignoreCollisions = true;
            paths = [
              cudaPackages.cudatoolkit
              cudaPackages.cuda_cudart
            ];
          };

          makeWrapper = wrapperLibs: ''
            mv "$out/bin/${pname}" "$out/bin/.${pname}-unwrapped"
            makeWrapper "$out/bin/.${pname}-unwrapped" "$out/bin/${pname}" \
              --inherit-argv0 \
              --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath wrapperLibs}"
          '';
          rocmLibs = [ rocmPackages.rocm-smi ];
          cudaLibs = [ linuxPackages.nvidia_x11 ];
          rocmVars = {
            ROCM_PATH = rocmPath;
            CLBlast_DIR = "${pkgs.clblast}/lib/cmake/CLBlast";
          };
          cudaVars = {
            CUDA_LIB_DIR = "${cudaToolkit}/lib";
            CUDACXX = "${cudaToolkit}/bin/nvcc";
            CUDAToolkit_ROOT = cudaToolkit;
          };
          buildModes = {
            cpu = { };

            gpu = {
              buildInputs = buildModes.rocm.buildInputs ++ buildModes.cuda.buildInputs;
              postFixup = makeWrapper (rocmLibs ++ cudaLibs);
            } // rocmVars // cudaVars;

            rocm = {
              buildInputs = [
                rocmPackages.hipblas
                rocmPackages.rocblas
                rocmPackages.clr
                rocmPackages.rocsolver
                rocmPackages.rocsparse
                pkgs.libdrm
              ];
              postFixup = makeWrapper rocmLibs;
            } // rocmVars;

            cuda = {
              buildInputs = [ cudaPackages.cuda_cudart ];
              postFixup = makeWrapper cudaLibs;
            } // cudaVars;
          };

          buildOllama = mode:
            gomod2nix.legacyPackages.${system}.buildGoApplication (buildModes.${mode} // {
              inherit pname version system;

              src = ollama;
              modules = ./gomod2nix.toml;

              nativeBuildInputs = [
                pkgs.cmake
                pkgs.makeWrapper
                pkgs.gcc12
              ];
              patches = [
                ./patch/disable-git-patching.patch
                ./patch/move-cache.patch
                ./patch/server-shutdown.patch
                ./patch/shutdown-utils.patch
              ];
              postPatch = ''
                substituteInPlace llm/generate/gen_linux.sh \
                  --subst-var-by cmakelistsPatch '${./patch/cmake-include.patch}'
              '';
              preBuild = ''
                export GOCACHE="$TMP/.cache/go-build"
                go generate ./...
              '';
              ldflags = [
                "-s"
                "-w"
                "-X=github.com/jmorganca/ollama/version.Version=0.0.0"
                "-X=github.com/jmorganca/ollama/server.mode=release"
              ];
            });

          gomod2nixGenerate = pkgs.writeShellScriptBin "gomod2nix-generate" ''
            exec ${gomod2nix.packages.${system}.default}/bin/gomod2nix generate --dir ${ollama} --outdir .
          '';
        in
        {
          packages = {
            default = self.packages.${system}.gpu;
            gpu = buildOllama "gpu";
            rocm = buildOllama "rocm";
            cuda = buildOllama "cuda";
            cpu = buildOllama "cpu";
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [ gomod2nixGenerate ];
          };
        }));
}
