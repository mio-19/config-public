{ fetchpatch, fetchurl }:
[
  (fetchpatch {
    name = "tuxguitar: 2.0.1 -> 2.1.1";
    url = "https://github.com/NixOS/nixpkgs/pull/579150.patch";
    hash = "sha256-MoBwTX19A5rcVlkFDS+ZL5tMKGjYlgOnlSHzNEDLHZQ=";
  })
  (fetchurl {
    name = "flyline: init at 1.9.0";
    url = "https://github.com/NixOS/nixpkgs/pull/538842.patch";
    hash = "sha256-M2hwE/KpOi9v/sCcXeB7SnXPpqo5aE2E0gkzbzIxvtM=";
  })
  (fetchpatch {
    name = "openlogi: 0.6.25 -> 0.8.13";
    url = "https://github.com/NixOS/nixpkgs/pull/573733.diff";
    hash = "sha256-AfhFg4ALppXSIRyCiEbZQl8LhcA3Fhi7H5rKUtznQwo=";
  })
  (fetchpatch {
    name = "mesh-llm, mesh-llm-cuda, mesh-llm-rocm, mesh-llm-native-runtime, mesh-llm-native-runtime-vulkan: init at 0.78.1; nixos/mesh-llm: init module";
    url = "https://github.com/NixOS/nixpkgs/pull/571722.diff";
    hash = "sha256-KLs2r0F+UV13ayKmDDNX90GSaDOZkl032MfmoaPsTdY=";
  })
  (fetchpatch {
    name = "Isabelle: Fix Darwin build without Rosetta and cleanup";
    url = "https://github.com/NixOS/nixpkgs/pull/578078.patch";
    hash = "sha256-9MDJfjwG7bvcs19szokNW6hStd6N11p7BYHmKHA3BWw=";
  })
]
