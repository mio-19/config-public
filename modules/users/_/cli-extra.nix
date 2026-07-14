{
  inputs,
  config,
  pkgs,
  lib,
  options,
  osConfig,
  ...
}:
let
  isAtLeast2605 = builtins.compareVersions config.home.version.release "26.05" >= 0;
in
{
  config.programs = lib.optionalAttrs (options ? mergiraf) {
    mergiraf = {
      enable = true;
      enableGitIntegration = true;
    };
  };

  config.services = lib.optionalAttrs (options ? vscode-server) {
    vscode-server.enable = !osConfig.programs.nix-ld.enable;
    #vscode-server.enableFHS = true;
    #vscode-server.nodejsPackage = pkgs.nodejs_latest;
  };
}
