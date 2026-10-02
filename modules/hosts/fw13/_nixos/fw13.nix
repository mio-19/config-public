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
  import = [
    ./358h.nix
  ];
  systemPackages_hardened = with pkgs; [
    kdePackages.kamoso
  ];

  # Disabled because reloading the driver makes the trackpad disappear and reappear as a new device,
  # causing libinput and KDE to temporarily drop click events and tap-to-click settings.
  config_trackpad-resume-workaround.enable = false;

  /*
    # https://github.com/troymoder/dotfiles/blob/f09867c7d178331596359cf1229e7e6806e75624/system/framework.nix#L48-L49
    # https://wiki.archlinux.org/title/Framework_Laptop_13_(AMD_Ryzen_7040_Series)
    services.colord.enable = true;
    environment.etc."color/icc/BOE_CQ_NE135FBM_N41_03.icm".source = ./BOE_CQ_______NE135FBM_N41_03.icm;
  */

  # https://www.reddit.com/r/framework/comments/17d6pjy/comment/k5uup6a/
  boot.blacklistedKernelModules = [
    "psmouse"
  ];
}
