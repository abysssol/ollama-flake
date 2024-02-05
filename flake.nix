{
  description =
    "ollama: Get up and running with Llama 2, Mistral, and other large language models locally";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    ollama = {
      url = "git+https://github.com/jmorganca/ollama?submodules=1";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, gomod2nix, ollama, ... }:
    (utils.lib.eachDefaultSystem (system:
      let
        pname = "ollama";
        version = "0.1.23-dev";

        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib rocmPackages;

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

        makeWrapper = wrapperLibs: ''
          mv "$out/bin/${pname}" "$out/bin/.${pname}-unwrapped"
          makeWrapper "$out/bin/.${pname}-unwrapped" "$out/bin/${pname}" \
            --inherit-argv0 \
            --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath wrapperLibs}"
        '';
        buildModes = {
          cpu = { };

          rocm = {
            buildInputs = [
              rocmPackages.hipblas
              rocmPackages.rocblas
              rocmPackages.clr
              rocmPackages.rocsolver
              rocmPackages.rocsparse
              pkgs.libdrm
            ];
            postFixup = makeWrapper [ rocmPackages.rocm-smi ];
            ROCM_PATH = "${rocmPath}";
            CLBlast_DIR = "${pkgs.clblast}/lib/cmake/CLBlast";
          };
        };

        buildOllama = mode:
          gomod2nix.legacyPackages.${system}.buildGoApplication (buildModes.${mode} // {
            inherit pname version system;

            src = ollama;
            modules = ./gomod2nix.toml;

            nativeBuildInputs = [
              pkgs.cmake
              pkgs.makeWrapper
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
          default = self.packages.${system}.cpu;
          cpu = buildOllama "cpu";
          rocm = buildOllama "rocm";
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ gomod2nixGenerate ];
        };
      }));
}
