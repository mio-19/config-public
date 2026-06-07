{ inputs, lib, ... }: {
  # workaround: make nix command faster.
  # https://github.com/gepbird/nixpkgs-patcher/commit/c80100e8664661559e430ca36f7579e47beb0b2c
  config.nixpkgs.flake.source = lib.mkForce (toString inputs.nixpkgs-unpatched);
}
