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
    ../keep.nix
    ../common.nix
    ../stockhm.nix
    ../extra.nix
    inputs.nixos-avf.nixosModules.avf
  ];
  # https://github.com/nix-community/nixos-avf/blob/d0a62c3f64b45a39570fde31a3a490b214bf19ee/initial/default.nix#L35
  avf.defaultUser = "user";

  mio_openssh_hpn = false;
  mio_aria2 = false;

  users.users.user = {
    uid = 1001;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true; # https://github.com/nix-community/home-manager/issues/108#issuecomment-2569823607
    openssh.authorizedKeys.keys = import ../../sshkeys.nix;
  };

  home-manager.users.user = ../user.nix;
  home-manager.extraSpecialArgs = {
    enable-fcitx = false;
  };
  system.stateVersion = "25.11";
  networking.hostName = "husky";

  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
    ])
    ++ [
      program.librewolf'
    ];

  # https://github.com/nix-community/nixos-avf/blob/d0a62c3f64b45a39570fde31a3a490b214bf19ee/avf/default.nix#L330C5-L330C28
  services.zram-generator.settings."zram0".zram-size = lib.mkForce "6G";
}
