# Ollama Nix Flake

A flake following the `main` branch of [ollama](https://github.com/jmorganca/ollama).
It's purpose is to build the most recent version supporting new models until
the version in [nixpkgs](https://github.com/nixos/nixpkgs) is updated.


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


## Backend API

Multiple packages are available for the different backend implementations supported by ollama.

The available APIs:
- `cpu`: default, CPU implementation
- `rocm`: supported by modern AMD GPUs

All available packages:
``` shell
nix profile install github:abysssol/ollama-flake#cpu
nix profile install github:abysssol/ollama-flake#rocm
```

The default api is `cpu`:
``` shell
# both of these are the default package, and are equivalent
nix profile install github:abysssol/ollama-flake
nix profile install github:abysssol/ollama-flake#default
# both of the above are equivalent to the below
nix profile install github:abysssol/ollama-flake#cpu
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
https://creativecommons.org/publicdomain/zero/1.0/).
Read the CC0 in the [LICENSE file](./LICENSE) or [online](
https://creativecommons.org/publicdomain/zero/1.0/legalcode).


## Contribution

Any contribution submitted for inclusion in the project is subject to the [CC0](./LICENSE);
that is, it is released into the public domain and all copyright to it is relinquished.
