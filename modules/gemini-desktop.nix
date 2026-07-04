# Gemini Desktop app and firejail wrapper (den.aspects.gemini-desktop).
{ den, ... }:
{
  den.aspects.gemini-desktop = {
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
          (hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop)
        ];

        programs.firejail.wrappedBinaries = {
          gemini-desktop = {
            executable = "${
              hardenedPkg inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop
            }/bin/gemini-desktop";
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
          inputs.mio.packages.${pkgs.stdenv.hostPlatform.system}.gemini-desktop
        ];
      };
  };
}
