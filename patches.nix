{ fetchpatch, fetchurl }:
[
  (fetchpatch {
    name = "craft-fonts: init at 0.1.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572622.patch";
    hash = "sha256-tA0U9aPPhEW40xgtwsauDczX5xmDjp0NZZDmQ9JD2ps=";
  })
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
  (fetchpatch {
    name = "deckcraft: init at 0.3.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572122.patch";
    hash = "sha256-kVvRvfy6E89XS1XtTsvQdk3v3n8PT2/qezUhcc89ijE=";
  })
  (fetchpatch {
    name = "gridcraft: init at 0.3.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572121.patch";
    hash = "sha256-uaS4DNyK8dOdnT/O4nJIQM+N1EXG69f3380DPYnJpSk=";
  })
  (fetchpatch {
    name = "wordcraft: init at 0.3.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572119.patch";
    hash = "sha256-NSP22fGB4soKhxv37oxA9HisbuQgISRPCz+U/7slloY=";
  })
  (fetchpatch {
    name = "cadcraft: init at 0.3.0";
    url = "https://github.com/NixOS/nixpkgs/pull/572118.patch";
    hash = "sha256-9BsbRigt9hq29mTB+3Z2a37DU7e+rNvjkiUz4Ous7Gw=";
  })
  /*
    (fetchpatch {
      name = "lightcraft: init at 0.5.0";
      url = "https://github.com/NixOS/nixpkgs/pull/571423.patch";
      hash = "sha256-ryHVF/iGO0dBGcJ1WdB4H+b/SCzAS5rMTJQqZKA9QiM=";
    })
  */
]
