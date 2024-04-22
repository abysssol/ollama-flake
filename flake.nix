{
  description =
    "ollama: Get up and running with Llama 2, Mistral, and other large language models locally";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unfree, ... }:
    let
      inherit (nixpkgs) lib;

      forAllSystems = systems: function:
        lib.genAttrs systems (system:
          function
            nixpkgs.legacyPackages.${system}
            nixpkgs-unfree.legacyPackages.${system});

      buildOllama = pkgs: overrides: pkgs.callPackage ./build-ollama.nix overrides;

      unixPackages = (forAllSystems lib.platforms.unix (pkgs: _: {
        default = buildOllama pkgs { };
      }));

      linuxPackages = (forAllSystems lib.platforms.linux (pkgs: pkgsUnfree: {
        default = buildOllama pkgsUnfree { };
        rocm = buildOllama pkgs { acceleration = "rocm"; };
        cuda = buildOllama pkgsUnfree { acceleration = "cuda"; };
        cpu = buildOllama pkgs { acceleration = false; };
      }));
    in
    {
      packages = unixPackages // linuxPackages;
    };
}
