{
  config,
  pkgs,
  lib,
  osConfig,
  options,
  commonExtensions,
  ...
}@args:
let
  inherit (import ./include.nix args) hasAntigravityFor;
in
{
  config.programs = lib.optionalAttrs (options ? antigravity) {
    antigravity = {
      enable = hasAntigravityFor osConfig;
      package = null;

      profiles.default = {
        enableExtensionUpdateCheck = false;
        extensions = with pkgs; commonExtensions;
        userSettings = config.programs.vscode.profiles.default.userSettings;
      };
    };
  };
}
