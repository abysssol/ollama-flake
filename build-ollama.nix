{ lib
, buildGoModule
, fetchFromGitHub
, buildEnv
, linkFarm
, overrideCC
, makeWrapper
, stdenv

, cmake
, gcc12
, clblast
, libdrm
, rocmPackages
, cudaPackages
, linuxPackages

, enableRocm ? stdenv.isLinux
, enableCuda ? stdenv.isLinux
  # `nvcc` doesn't support the latest version of gcc
, cudaGcc ? gcc12
}:

let
  pname = "ollama";
  version = "0.1.24";

  warnIfNotLinux = warning: (lib.warnIfNot stdenv.isLinux warning stdenv.isLinux);
  rocmIsEnabled = enableRocm && (warnIfNotLinux
    "building ollama with rocm is only supported on linux; falling back to cpu");
  cudaIsEnabled = enableCuda && (warnIfNotLinux
    "building ollama with cuda is only supported on linux; falling back to cpu");
  gpuIsEnabled = rocmIsEnabled || cudaIsEnabled;

  inherit (lib) licenses platforms maintainers;
  ollama = {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "jmorganca";
      repo = "ollama";
      rev = "v${version}";
      hash = "sha256-GwZA1QUH8I8m2bGToIcMMaB5MBnioQP4+n1SauUJYP8=";
      fetchSubmodules = true;
    };
    vendorHash = "sha256-wXRbfnkbeXPTOalm7SFLvHQ9j46S/yLNbFy+OWNSamQ=";

    nativeBuildInputs = [ cmake ]
      ++ (lib.optional gpuIsEnabled makeWrapper);

    patches = [
      # remove uses of `git` in the `go generate` script
      # instead use `patch` where necessary
      ./patch/remove-git.patch

      # ollama's patches of llama.cpp's example server
      # `ollama/llm/generate/gen_common.sh` -> "apply temporary patches until fix is upstream"

      # created from `ollama/llm/patches/01-cache.diff`
      ./patch/01-cache.patch
      # created from `ollama/llm/patches/02-shutdown.diff`
      ./patch/02-shutdown.patch

      # `ollama/llm/generate/gen_common.sh` -> "avoid duplicate main symbols when we link into the cgo binary"
      ./patch/unique-main.patch
    ];
    postPatch = ''
      # use a patch from the nix store in the `go generate` script
      substituteInPlace llm/generate/gen_common.sh \
        --subst-var-by cmakeIncludePatch '${./patch/cmake-include.patch}'
      # replace inaccurate version number with actual release version
      substituteInPlace version/version.go --replace-fail 0.0.0 '${version}'
    '';
    preBuild = ''
      # build llama.cpp libraries for ollama
      go generate ./...
    '';

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/jmorganca/ollama/version.Version=${version}"
      "-X=github.com/jmorganca/ollama/server.mode=release"
    ];

    meta = with lib; {
      description = "Get up and running with large language models locally";
      homepage = "https://github.com/jmorganca/ollama";
      license = licenses.mit;
      platforms = platforms.unix;
      mainProgram = pname;
      maintainers = with maintainers; [ abysssol dit7ya elohmeier ];
    };
  };


  rocmClang = linkFarm "rocm-clang" {
    llvm = rocmPackages.llvm.clang;
  };
  rocmPath = buildEnv {
    name = "rocm-path";
    paths = [
      rocmPackages.rocm-device-libs
      rocmClang
    ];
  };
  rocmVars = {
    ROCM_PATH = rocmPath;
    CLBlast_DIR = "${clblast}/lib/cmake/CLBlast";
  };

  cudaToolkit = buildEnv {
    name = "cuda-toolkit";
    ignoreCollisions = true; # FIXME: find a cleaner way to do this without ignoring collisions
    paths = [
      cudaPackages.cudatoolkit
      cudaPackages.cuda_cudart
    ];
  };
  cudaVars = {
    CUDA_LIB_DIR = "${cudaToolkit}/lib";
    CUDACXX = "${cudaToolkit}/bin/nvcc";
    CUDAToolkit_ROOT = cudaToolkit;
  };

  gpuBuildLibs = {
    buildInputs = (lib.optionals rocmIsEnabled [
      rocmPackages.clr
      rocmPackages.hipblas
      rocmPackages.rocblas
      rocmPackages.rocsolver
      rocmPackages.rocsparse
      libdrm
    ])
    ++ (lib.optional cudaIsEnabled
      cudaPackages.cuda_cudart
    );
  };

  runtimeLibs = (lib.optional rocmIsEnabled rocmPackages.rocm-smi)
    ++ (lib.optional cudaIsEnabled linuxPackages.nvidia_x11);
  runtimeLibWrapper = {
    postFixup = ''
      mv "$out/bin/${pname}" "$out/bin/.${pname}-unwrapped"
      makeWrapper "$out/bin/.${pname}-unwrapped" "$out/bin/${pname}" \
        --suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath runtimeLibs}'
    '';
  };

  goBuild =
    if cudaIsEnabled then
      buildGoModule.override { stdenv = overrideCC stdenv cudaGcc; }
    else
      buildGoModule;
in
goBuild (ollama
  // (lib.optionalAttrs rocmIsEnabled rocmVars)
  // (lib.optionalAttrs cudaIsEnabled cudaVars)
  // (lib.optionalAttrs gpuIsEnabled gpuBuildLibs)
  // (lib.optionalAttrs gpuIsEnabled runtimeLibWrapper))
