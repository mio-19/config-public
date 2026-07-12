{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  imports = [
    (import ../../../../aspect.nix "keep")
    ../../../../nixos-base-den.nix
    ../../../../nixos/stockhm.nix
    (import ../../../../aspect.nix "extra")
    inputs.nixos-avf.nixosModules.avf
  ];
  # https://github.com/nix-community/nixos-avf/blob/d0a62c3f64b45a39570fde31a3a490b214bf19ee/initial/default.nix#L35
  avf.defaultUser = "user";

  mio_openssh_hpn = false;
  mio_aria2 = false;

  users.users.user = {
    uid = 1001;
  };

  system.stateVersion = "25.11";
  networking.hostName = "husky";

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
    ])
    ++ [
      progs.librewolf'
    ];

  # https://github.com/nix-community/nixos-avf/blob/d0a62c3f64b45a39570fde31a3a490b214bf19ee/avf/default.nix#L330C5-L330C28
  services.zram-generator.settings."zram0".zram-size = lib.mkForce "6G";
}
