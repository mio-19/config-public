{ fetchpatch, fetchurl }:
[
  (fetchpatch {
    name = "nixos/security/wrappers: avoid linux-headers in closure";
    url = "https://github.com/NixOS/nixpkgs/pull/532581.patch";
    hash = "sha256-Tf3Lz9iQGqVVkviGg3FF2UyNVig8vhcYrMG+tIT2zA0=";
  })
  (fetchpatch {
    name = "update nixos/hardware.fw-fanctrl + package fw-fanctrl";
    url = "https://github.com/NixOS/nixpkgs/pull/526318.diff";
    hash = "sha256-w480zZf4tR01wZMojLrn3TNzAkOisD+rOvWCdxTYIu8=";
  })
  (fetchpatch {
    name = "grub-module-keep-booted-system-entry-option.patch";
    url = "https://github.com/NixOS/nixpkgs/pull/487895.patch";
    hash = "sha256-q4vOJ2BcNa+K0uWvhzuFvmOV7eVyWnKvD/CY3cGh5XI=";
  })
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
    name = "isabelle: 2025-2 -> 2026";
    url = "https://github.com/NixOS/nixpkgs/pull/579996.patch";
    hash = "sha256-ubCIGJtM1fBr/KzCi2G2zzFi6KohbEkFVv6saUQ3yow=";
  })
]
