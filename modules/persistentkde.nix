{ den, ... }:
{
  den.aspects.persistentkde = {
    description = "Persist SDDM and plasma-login state under /persistent";
    nixos =
      {
        config,
        inputs,
        lib,
        pkgs,
        ...
      }:
      {
        environment.persistence."/persistent" = {
          files = lib.optionals config.services.displayManager.sddm.enable [
            "/var/lib/sddm/state.conf" # last login user for sddm
          ];
          directories = lib.optionals config.services.displayManager.plasma-login-manager.enable [
            # https://github.com/NixOS/nixpkgs/pull/479797#issuecomment-3786469834
            "/var/lib/plasmalogin"
          ];
        };
      };
  };
}
