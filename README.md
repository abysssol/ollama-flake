# Ollama Nix Flake

A flake following the `main` branch of [ollama](https://github.com/jmorganca/ollama).
It's purpose is to build the most recent version supporting new models
until the version in [nixpkgs](https://github.com/nixos/nixpkgs) is updated.

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

## Api Backend

Multiple packages are available for the different api backends supported by
[llama-cpp](https://github.com/ggerganov/llama.cpp).

The available apis:
- opencl: cpu or gpu  
  default
- openblas: cpu only  
  llama-cpp sets this as the default, overridden here
- cuda: nvidia gpu only  
  hasn't been tested with nvidia hardware, may or may not work
- rocm: amd gpu only  
  broken; server returns error in ggml-cuda.cu when loading model  
  probably a problem with ollama not supporting rocm, see issue [#738](
  https://github.com/jmorganca/ollama/issues/738)

The default api is opencl:
``` shell
# both of these are the default package, and are equivalent
nix profile install github:abysssol/ollama-flake
nix profile install github:abysssol/ollama-flake#default
```

``` shell
nix profile install github:abysssol/ollama-flake#opencl
nix profile install github:abysssol/ollama-flake#openblas
nix profile install github:abysssol/ollama-flake#cuda
nix profile install github:abysssol/ollama-flake#rocm
```

## Remove

Find the index of the package to remove:
``` shell
nix profile list
```

Remove the package with an index of n:
``` shell
nix profile remove n
```

## License

This software is dedicated to the public domain under the [Creative Commons Zero](
https://creativecommons.org/publicdomain/zero/1.0/).
Read the CC0 in the [LICENSE file](./LICENSE) or [online](
https://creativecommons.org/publicdomain/zero/1.0/legalcode).


## Contribution

Any contribution submitted for inclusion in the project is subject to the [CC0](./LICENSE);
that is, it is released into the public domain and all copyright to it is relinquished.
