{ den, ... }:
{
  den.aspects.auto-allocate-uids = {
    description = "Enable Nix auto-allocated build UIDs";
    os =
      { lib, ... }:
      {
        nix.settings = {
          experimental-features = [ "auto-allocate-uids" ];
        };
      };
    nixos =
      { lib, ... }:
      {
        nix.settings = {
          auto-allocate-uids = true;
        };
      };
    darwin =
      { lib, ... }:
      {
        # workaround for https://github.com/nix-darwin/nix-darwin/issues/1816
        nix.extraOptions = ''
          auto-allocate-uids = true
        '';
      };
  };
}
