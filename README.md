# Ollama Nix Flake

A flake following the `main` branch of [ollama](https://github.com/jmorganca/ollama).
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

    ollama = {
      url = "github:abysssol/ollama-flake";
      # this could potentially break the build
      # if ollama doesn't build, try removing this
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ### to access the rocm package of the ollama flake:
  # ollama.packages.${system}.rocm
  # inputs'.ollama.packages.rocm # with flake-parts

  # ### you can override package inputs like with nixpkgs
  # ollama.packages.${system}.cuda.override { cudaGcc = pkgs.gcc11; }
};
```

### Version

You can specify a version by appending `/version` after the main url,
where `version` is any branch or tag.
The version branches will only be updated in a backward compatible way, no breaking changes
(see [semantic versioning](https://semver.org)).

Append `/1` to follow branch `1` which tracks version 1.y.z of the repo:
``` shell
nix profile install github:abysssol/ollama-flake/1
```

Use an unchanging tagged version:
``` shell
nix profile install github:abysssol/ollama-flake/1.3.0
```

Alternate packages can be specified as usual.
From version 1, install the `cpu` package, which is built to only run on CPU:
``` shell
nix profile install github:abysssol/ollama-flake/1#cpu
```

Other versions may be available:
``` shell
nix profile install github:abysssol/ollama-flake/0
nix profile install github:abysssol/ollama-flake/1.1.0
```

### Backend

Multiple packages are available for the different backend implementations supported by ollama.

The available options:
- `cpu`: fallback CPU implementation
  ``` shell
  nix profile install github:abysssol/ollama-flake#cpu
  ```
- `rocm`: supported by modern AMD GPUs
  ``` shell
  nix profile install github:abysssol/ollama-flake#rocm
  ```
- `cuda`: supported by modern NVIDIA GPUs; uses unfree licensed libraries
  ``` shell
  nix profile install github:abysssol/ollama-flake#cuda
  ```
- `gpu`: build for both rocm and cuda, then dynamically load the relevant library at runtime
  ``` shell
  nix profile install github:abysssol/ollama-flake#gpu
  ```

The default is `gpu`:
``` shell
# both of these are the default package, and are equivalent
nix profile install github:abysssol/ollama-flake
nix profile install github:abysssol/ollama-flake#default
# both of the above are equivalent to the one below
nix profile install github:abysssol/ollama-flake#gpu
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
