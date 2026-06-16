{
  inputs,
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  # DETAILS REMOVED
  waydroidDir = "${config.home.homeDirectory}/.var_lib_waydroid";
in
{
  imports = [
    # DETAILS REMOVED
    ./usersfcitx5.nix
  ];

  # https://nixos.wiki/wiki/OpenSnitch
  services.opensnitch-ui.enable = osConfig.services.opensnitch.enable;

  # Ensure ~/.var_lib_waydroid exists with sane perms on every `home-manager switch`
  home.activation.ensureWaydroidDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${waydroidDir}" ]; then
      mkdir -p "${waydroidDir}"
      chmod 0755 "${waydroidDir}"
    fi
  '';

  #wayland.windowManager.hyprland.enable = true; # enable Hyprland

  home.packages = [
    # pkgs.firedragon
  ];
  # https://forum.garudalinux.org/t/enable-firefox-account-sync-in-firedragon/16619/4
  home.file.".firedragon/firedragon.overrides.cfg".text = ''
    lockPref("identity.sync.tokenserver.uri", "https://token.services.mozilla.com/1.0/sync/1.5");
  '';

  programs.plasma = {
    enable = osConfig.services.desktopManager.plasma6.enable;
    # DETAILS REMOVED
    kscreenlocker = {
      # DETAILS REMOVED
    };
  };

  programs.ssh = {
    enableDefaultConfig = false;
    enable = true;
    settings = {
      # DETAILS REMOVED
    };
  };

  home.stateVersion = "25.11";
}
