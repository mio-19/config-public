{
  inputs = {
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    nixos.url = "path:./nixos";
  };

  outputs =
    { self, nixos, ... }:
    {
      inherit (nixos) nixosConfigurations;
    };
}
