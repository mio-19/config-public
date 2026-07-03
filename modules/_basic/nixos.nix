{ pkgs, lib, ... }: {
  imports = [ ./shared.nix ];

  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    lib.optionals (pkgs ? nixtamal) [
      nixtamal
    ];
}
