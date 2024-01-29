{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";

    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    llama-cpp = {
      url = "github:ggerganov/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    ollama = {
      url = "github:jmorganca/ollama";
      flake = false;
    };
  };

  outputs = { nixpkgs, utils, gomod2nix, llama-cpp, ollama, ... }:
    (utils.lib.eachDefaultSystem (system:
      let
        name = "ollama";
        version = "0.1.17-dev";
        pkgs = nixpkgs.legacyPackages.${system};
        buildOllama = api:
          gomod2nix.legacyPackages.${system}.buildGoApplication {
            inherit system;
            name = "${name}-${version}";

            src = ollama;
            pwd = ./.;

            patches = [
              ./disable-gqa.patch
              ./set-llamacpp-path.patch
            ];
            postPatch = ''
              substituteInPlace llm/llama.go \
                --subst-var-by llamaCppServer "${llama-cpp.packages.${system}.${api}}/bin/llama-server"
            '';
            ldflags = [
              "-s"
              "-w"
              "-X=github.com/jmorganca/ollama/version.Version=0.0.0"
              "-X=github.com/jmorganca/ollama/server.mode=release"
            ];
          };
      in
      {
        packages = {
          default = buildOllama "opencl";
          openblas = buildOllama "default";
          opencl = buildOllama "opencl";
          cuda = buildOllama "cuda";
          rocm = buildOllama "rocm";
        };

        devShells.default = pkgs.mkShell {
          NIX_PATH = "nixpkgs=${nixpkgs}";
          OLLAMA_PATH = ollama;
          nativeBuildInputs = [
            gomod2nix.packages.${system}.default
            (gomod2nix.legacyPackages.${system}.mkGoEnv { pwd = ollama; })
          ];
        };
      }));
}
