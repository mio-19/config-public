{
  inputs = {
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    nixos.url = "path:./nixos";

    mac.url = "path:./mac";

    bsd.url = "path:./bsd";
  };

  outputs =
    {
      nixos,
      mac,
      bsd,
      ...
    }:
    {
      inherit (nixos) nixosConfigurations;
      inherit (mac) darwinConfigurations;
      inherit (bsd) nixbsdConfigurations;
    };
}
