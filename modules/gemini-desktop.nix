# Gemini Desktop app and firejail wrapper (den.aspects.gemini-desktop).
{
  den,
  config,
  inputs,
  pkgs,
  ...
}:
{
  den.aspects.gemini-desktop =
    let
      gemini-desktop =
        if config.gemini_zh then
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop_zh
        else
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop;
    in
    {
      description = "gemini-desktop with firejail";
      nixos =
        args@{
          inputs,
          pkgs,
          ...
        }:
        let
          _include = args._include or (import ../nixos/include.nix args);
        in
        with _include;
        {
          environment.systemPackages = [
            (hardenedPkg gemini-desktop)
          ];

          programs.firejail.wrappedBinaries = {
            gemini-desktop = {
              executable = "${hardenedPkg gemini-desktop}/bin/gemini-desktop";
              profile = ../nixos/gemini-desktop.profile;
              extraArgs = [
                # https://github.com/netblue30/firejail/issues/6681#issuecomment-2725161673
                "--ignore=private-dev"
              ];
            };
          };
        };

      darwin =
        { inputs, pkgs, ... }:
        {
          environment.systemPackages = [
            gemini-desktop
          ];
        };
    };
}
