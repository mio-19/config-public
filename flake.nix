{
  inputs = {
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    nixos.url = "path:./nixos";

    mac.url = "path:./mac";
  };

  outputs =
    { nixos, mac, ... }:
    {
      inherit (nixos) nixosConfigurations;
      inherit (mac) darwinConfigurations;
    };
}
