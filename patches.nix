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
]
