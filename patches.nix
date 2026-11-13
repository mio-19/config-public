{ fetchpatch, fetchurl }:
[
  (fetchpatch {
    name = "nixos/security/wrappers: avoid linux-headers in closure";
    url = "https://github.com/NixOS/nixpkgs/pull/532581.patch";
    hash = "sha256-Tf3Lz9iQGqVVkviGg3FF2UyNVig8vhcYrMG+tIT2zA0=";
  })
  (fetchpatch {
    name = "grub-module-keep-booted-system-entry-option.patch";
    url = "https://github.com/NixOS/nixpkgs/pull/487895.patch";
    hash = "sha256-q4vOJ2BcNa+K0uWvhzuFvmOV7eVyWnKvD/CY3cGh5XI=";
  })
  (fetchurl {
    name = "flyline: init at 1.9.0";
    url = "https://github.com/NixOS/nixpkgs/pull/538842.patch";
    hash = "sha256-M2hwE/KpOi9v/sCcXeB7SnXPpqo5aE2E0gkzbzIxvtM=";
  })
  (fetchpatch {
    name = "mesh-llm, mesh-llm-cuda, mesh-llm-rocm, skippy-native-runtime, skippy-native-runtime-vulkan: init at 0.79.0";
    url = "https://github.com/NixOS/nixpkgs/pull/571722.diff";
    hash = "sha256-iiCwKJVOSBaOR93MjvYarma6MRbDWkrLMBz1lrBdBek=";
  })
  /*
    (fetchpatch {
      name = "isabelle: 2025-2 -> 2026";
      url = "https://github.com/NixOS/nixpkgs/pull/579996.patch";
      hash = "sha256-ubCIGJtM1fBr/KzCi2G2zzFi6KohbEkFVv6saUQ3yow=";
    })
  */
  (fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/578621.diff";
    hash = "sha256-gLNZZVA0Qusgb/+zfWqtT2cSc8hZPCTHfH67ibOQeYo=";
  })
]
