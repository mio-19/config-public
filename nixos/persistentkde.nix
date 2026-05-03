{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{

  environment.persistence."/persistent" = {
    files =
      lib.optionals config.services.displayManager.sddm.enable [
        "/var/lib/sddm/state.conf" # last login user for sddm
      ]
      ++ lib.optionals config.services.displayManager.plasma-login-manager.enable [
        # https://github.com/NixOS/nixpkgs/pull/479797#issuecomment-3786469834
        "/var/lib/plasmalogin/state.conf"
      ];
  };

}
