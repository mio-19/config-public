{ fetchpatch, fetchurl }:
[
  (fetchpatch {
    name = "photocraft: init at 0.7.0";
    url = "https://github.com/NixOS/nixpkgs/pull/571418.patch";
    hash = "sha256-m0FWIP4LxuJtvUKI5Tdyu2tZsjuMiiAD9OkZyW4zbMM=";
  })
  (fetchurl {
    name = "flyline: init at 1.9.0";
    url = "https://github.com/NixOS/nixpkgs/pull/538842.patch";
    hash = "sha256-M2hwE/KpOi9v/sCcXeB7SnXPpqo5aE2E0gkzbzIxvtM=";
  })
  /*
    (fetchpatch {
      name = "wordcraft: init at 0.3.0";
      url = "https://github.com/NixOS/nixpkgs/pull/572119.patch";
      hash = "sha256-4BYp7epvzIhXdBMGGMA0k7NhCLPAcPOCQdDjqR4g+TI=";
    })
  */
  (fetchpatch {
    name = "cadcraft: init at 0.3.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572118.patch";
    hash = "sha256-GjfM/UHoqlGRqsOX0WOcW2TjWpO0ntjtk+ppUeN6OkM=";
  })
  /*
    (fetchpatch {
      name = "lightcraft: init at 0.5.0";
      url = "https://github.com/NixOS/nixpkgs/pull/571423.patch";
      hash = "sha256-ryHVF/iGO0dBGcJ1WdB4H+b/SCzAS5rMTJQqZKA9QiM=";
    })
  */
  (fetchpatch {
    name = "openlogi: 0.6.25 -> 0.8.13";
    url = "https://github.com/NixOS/nixpkgs/pull/573733.diff";
    hash = "sha256-AfhFg4ALppXSIRyCiEbZQl8LhcA3Fhi7H5rKUtznQwo=";
  })
  (fetchpatch {
    name = "mesh-llm, mesh-llm-cuda, mesh-llm-rocm, mesh-llm-native-runtime, mesh-llm-native-runtime-vulkan: init at 0.78.1; nixos/mesh-llm: init module";
    url = "https://github.com/NixOS/nixpkgs/pull/571722.diff";
    hash = "sha256-cnOznfIHQFGQbepnDVARnpARJzFfGoBKRyWT9dpvmEA=";
  })
]
