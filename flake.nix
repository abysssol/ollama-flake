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

      unixPackages = (forAllSystems lib.platforms.unix (pkgs: _:
        let
          cpu = pkgs.callPackage ./build-ollama.nix { enableRocm = false; enableCuda = false; };
        in
        {
          default = cpu;
          inherit cpu;
        }));

      linuxPackages = (forAllSystems lib.platforms.linux (pkgs: pkgsUnfree:
        let
          gpu = pkgsUnfree.callPackage ./build-ollama.nix { };
        in
        {
          default = gpu;
          inherit gpu;
          rocm = pkgs.callPackage ./build-ollama.nix { enableCuda = false; };
          cuda = pkgsUnfree.callPackage ./build-ollama.nix { enableRocm = false; };
          cpu = pkgs.callPackage ./build-ollama.nix { enableRocm = false; enableCuda = false; };
        }));
    in
    {
      packages = unixPackages // linuxPackages;
    };
}
