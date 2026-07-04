{ den, ... }:
{
  den.aspects.auto-allocate-uids = {
    description = "Enable Nix auto-allocated build UIDs";
    os =
      { lib, ... }:
      {
        nix.settings = {
          nrBuildUsers = lib.mkForce 0;
          experimental-features = lib.mkAfter [ "auto-allocate-uids" ];
          auto-allocate-uids = true;
        };
      };
  };
}
