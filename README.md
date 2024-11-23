# Ollama Nix Flake

This flake has been mostly abandoned, and won't receive consistent updates.

A flake for the latest release of [ollama](https://github.com/jmorganca/ollama).
It's purpose is to build the most recent version supporting new models until
the version in [nixpkgs](https://github.com/nixos/nixpkgs) is updated.

### Contents
- [Install](#install)
  - [Version](#version)
  - [Backend](#backend)
- [Update](#update)
- [Remove](#remove)
- [License](#license)


## Install

You need to have nix flakes enabled;
if you don't, see the [nixos wiki](https://nixos.wiki/wiki/Flakes)
for information on flakes and enabling them.

Install ollama to user profile:
``` shell
nix profile install github:abysssol/ollama-flake
```

Create a temporary shell with ollama:
``` shell
nix shell github:abysssol/ollama-flake
```

Use as an input in another flake:
``` nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    ollama.url = "github:abysssol/ollama-flake/5";
    #ollama.inputs.nixpkgs.follows = "nixpkgs"; # this could break the build unless using unstable nixpkgs
  };

  outputs = { nixpkgs, ollama, ... }:
    let
      system = abort "system needs to be set";
      # to access the rocm package of the ollama flake:
      ollama-rocm = ollama.packages.${system}.rocm;
      #ollama-rocm = inputs'.ollama.packages.rocm; # with flake-parts

      pkgs = nixpkgs.legacyPackages.${system};
      # you can override package inputs like with nixpkgs
      ollama-cuda = ollama.packages.${system}.cuda.override { cudaGcc = pkgs.gcc11; };
    in
    {
      # output attributes go here
    };
};
```

### Version

You can specify a version by appending `/<version>` after the main url,
where `<version>` is any branch or tag.
The version branches will only be updated in a backward compatible way, no breaking changes
(see [semantic versioning](https://semver.org)).

The versions used *are not* the same as upstream ollama: they are specific to this repository.
However, a new major version will be used whenever upstream ollama makes a breaking release.

Append `/5` to follow branch `5` which tracks version 5.y.z of the repo:
``` shell
nix profile install github:abysssol/ollama-flake/5
```

Use an unchanging tagged version:
``` shell
nix profile install github:abysssol/ollama-flake/3.5.0
```

Alternate packages can be specified as usual.
From version 5, install the `cpu` package, which is built to only run on CPU:
``` shell
nix profile install github:abysssol/ollama-flake/5#cpu
```

Other versions may be available:
``` shell
nix profile install github:abysssol/ollama-flake/1
nix profile install github:abysssol/ollama-flake/1.7.0
```

### Backend

Multiple packages are available for the different computation backends supported by ollama on linux.
On other platforms (eg darwin), only the default package is available.
On darwin, gpu acceleration via metal should work by default.

The available options:
- `cpu`: fallback CPU implementation
  ``` shell
  nix profile install github:abysssol/ollama-flake#cpu
  ```
- `rocm`: supported by most modern AMD GPUs
  ``` shell
  nix profile install github:abysssol/ollama-flake#rocm
  ```
- `cuda`: supported by most modern NVIDIA GPUs; uses unfree licensed libraries
  ``` shell
  nix profile install github:abysssol/ollama-flake#cuda
  ```

The default build may be for cpu, but may be for rocm or cuda if
one of `nixpkgs.config.rocmSupport` or `nixpkgs.config.cudaSupport` is enabled:
``` shell
# both of these are the default package, and are equivalent expressions
nix profile install github:abysssol/ollama-flake
nix profile install github:abysssol/ollama-flake#default
```


## Update

Find the index of the package to update:
``` shell
nix profile list
```

Update the package at `index`:
``` shell
nix profile upgrade $index
```

If nix is hesitant to download updates, force nix to download new files with `--refresh`:
``` shell
nix profile upgrade --refresh $index
```


## Remove

Find the index of the package to remove:
``` shell
nix profile list
```

Remove the package at `index`:
``` shell
nix profile remove $index
```


## License

This software is dedicated to the public domain under the [Creative Commons Zero](
https://creativecommons.org/publicdomain/zero/1.0).
Read the CC0 in the [LICENSE file](./LICENSE) or [online](
https://creativecommons.org/publicdomain/zero/1.0/legalcode).

### Contribution

Any contribution submitted for inclusion in the project is subject to the [CC0](./LICENSE);
that is, it is released into the public domain and all copyright to it is relinquished.
