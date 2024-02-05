# Ollama Nix Flake

A flake following the `main` branch of [ollama](https://github.com/jmorganca/ollama).
It's purpose is to build the most recent version supporting new models until
the version in [nixpkgs](https://github.com/nixos/nixpkgs) is updated.

### Contents
- [Install](#install)
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

Install a version that will only be updated in a backward compatible way, no breaking changes
(see [semantic versioning](https://semver.org)):
``` shell
# append `/1` to follow branch `1` which tracks version 1.y.z of the repo
nix profile install github:abysssol/ollama-flake/1
# other versions may be available
nix profile install github:abysssol/ollama-flake/0
# use an unchanging tagged version
nix profile install github:abysssol/ollama-flake/1.0.1
# install a version built to run on AMD GPUs
nix profile install github:abysssol/ollama-flake/1#rocm
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
    utils.url = "github:numtide/flake-utils";

    ollama = {
      url = "github:abysssol/ollama-flake/1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
  };
};
```

### Backend

Multiple packages are available for the different backend implementations supported by ollama.

The available options:
- `cpu`: default CPU implementation
  ``` shell
  nix profile install github:abysssol/ollama-flake#cpu
  ```
- `rocm`: supported by modern AMD GPUs
  ``` shell
  nix profile install github:abysssol/ollama-flake#rocm
  ```

The default is `cpu`:
``` shell
# both of these are the default package, and are equivalent
nix profile install github:abysssol/ollama-flake
nix profile install github:abysssol/ollama-flake#default
# both of the above are equivalent to the one below
nix profile install github:abysssol/ollama-flake#cpu
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
