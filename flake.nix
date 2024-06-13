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

      forAllSystems = systems: buildPackages:
        lib.genAttrs systems (system:
          buildPackages nixpkgs-unfree.legacyPackages.${system});

      buildPackages = systems: packageOverrides:
        forAllSystems systems (pkgs:
          builtins.mapAttrs
            (_: pkgs.callPackage ./package.nix)
            (packageOverrides pkgs));

      unixPackages = buildPackages lib.platforms.unix (pkgs: {
        default = { };
      });

      linuxPackages = buildPackages lib.platforms.linux (pkgs: {
        default = { };
        rocm = { acceleration = "rocm"; };
        cuda = { acceleration = "cuda"; };
        cpu = { acceleration = false; };
      });
    in
    {
      packages = unixPackages // linuxPackages;
    };
}
