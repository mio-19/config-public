{ den, ... }:
let
  nixpkgs-workaround =
    { inputs, lib, ... }:
    {
      # workaround: make nix command faster.
      # https://github.com/gepbird/nixpkgs-patcher/commit/c80100e8664661559e430ca36f7579e47beb0b2c
      config.nixpkgs.flake.source = lib.mkForce (toString inputs.nixpkgs-unpatched);
    };
in
{
  den.aspects.nixpkgs-workaround = {
    description = "Point nixpkgs.flake.source at the unpatched source for faster nix commands";
    nixos = nixpkgs-workaround;
    darwin = nixpkgs-workaround;
  };
}
