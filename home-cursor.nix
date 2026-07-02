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
  inherit (import ./include.nix args) hasCursorFor;
in
{
  config.programs = lib.optionalAttrs (options ? cursor) {
    cursor = {
      enable = hasCursorFor osConfig;
      package = null;

      profiles.default = {
        enableUpdateCheck = false;
        extensions = with pkgs; commonExtensions;
        userSettings = config.programs.vscode.profiles.default.userSettings;
      };
    };
  };
}
