{ den, ... }:
{
  den.aspects.auto-allocate-uids = {
    description = "Enable Nix auto-allocated build UIDs";
    os =
      { lib, ... }:
      {
        nix.settings = {
          experimental-features = [ "auto-allocate-uids" ];
          auto-allocate-uids = true;
        };
      };
    nixos =
      { lib, ... }:
      {
        nix.settings = {
          nrBuildUsers = lib.mkForce 0;
        };
      };
    darwin =
      { lib, ... }:
      {
        nix.settings = {
          nrBuildUsers = lib.mkForce 2;
        };
      };
  };
}
