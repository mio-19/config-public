{
  config,
  inputs,
  lib,
  pkgs,
  system,
  _include,
  ...
}@args:
with _include;
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager.sharedModules = [
    (
      { osConfig, ... }@args:
      {
        # will this correctly apply configuration after our zfs unlock?
        home.file.".config/autostart/home-manager-restart.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Restart Home Manager
          Comment=Restart Home Manager user service on login
          Exec=${osConfig.systemd.package}/bin/systemctl --user restart home-manager.service
          X-GNOME-Autostart-enabled=true
        '';
      }
    )
  ];

  home-manager.startAsUserService = true;
  systemd.user.services.home-manager = {
    wantedBy = [ "default.target" ];
  };
}
