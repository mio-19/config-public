{
  osConfig,
  lib,
  ...
}:
{
  programs.plasma = {
    enable = osConfig.services.desktopManager.plasma6.enable;
    powerdevil = {
      AC = {
        powerButtonAction = lib.mkForce "sleep";
        autoSuspend = {
          action = lib.mkForce "sleep";
        };
        whenLaptopLidClosed = lib.mkForce "sleep";
      };
    };
  };
}
