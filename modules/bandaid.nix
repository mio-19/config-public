# Kernel CVE mitigations and hardening band-aids (den.aspects.bandaid).
{ den, ... }: {
  den.aspects.bandaid = {
    description = "Kernel CVE mitigations and hardening band-aids";
    os =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      {
        # https://github.com/NixOS/nixpkgs/pull/576390
        security.pki.caCertificateBlacklist = [
          "Comodo AAA Services root"
          "emSign ECC Root CA - G3"
          "emSign Root CA - C1"
          "emSign ECC Root CA - C3"
        ];
      };
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_bandaid/default.nix args;
  };
}
