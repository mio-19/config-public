{ den, ... }:
{
  den.aspects.tkg = {
    description = "wine-tkg from nix-gaming and ntsync kernel module";
    nixos =
      {
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        /*
          # we have our own cache instead
          nix.settings = {
            substituters = [ "https://nix-gaming.cachix.org" ];
            trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
          };
        */
        # lsof /dev/ntsync
        boot.kernelModules = [ "ntsync" ];
        wine64_package = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg;
      };
  };
}
