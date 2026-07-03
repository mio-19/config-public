# Extra desktop packages and apps (den.aspects.desktopextra).
{ den, ... }: {
  den.aspects.desktopextra = {
    description = "Extra desktop packages, firejail wrappers, and wireshark";
    nixos =
      args@{
        config,
        inputs,
        lib,
        pkgs,
        system,
        ...
      }:
      import ./_desktopextra/default.nix args;
  };
}
