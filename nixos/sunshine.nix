{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    autoStart = true;
    openFirewall = true;
  };
}
