# collect packages that mostly never use. maybe useful if there is a possible situation of offline
{
  config,
  inputs,
  lib,
  pkgs,
  _include,
  ...
}@args:
with _include;
{
  imports = [
    ./desktopextra2.nix
  ];
  # https://search.nixos.org/packages
  environment.systemPackages =
    with pkgs;
    (map hardenedPkg [
      alacritty
      #kdePackages.tokodon
      ardour
      #whalebird
      sioyek
      thonny
      friture
      wayland-bongocat
      kdePackages.kdenlive
      shotcut
      flowblade
      imhex
      wxhexeditor
      jabref
      penpot-desktop
      # unfree:
      lightworks # maybe doesn't support wayland well # maybe consider https://github.com/kekkoudesu/lightworks-flatpak
    ])
    ++ [
      # breaks with wrapper
      nur.repos.mio.android-translation-layer
    ];

  services.flatpak = {
    enable = true;
    packages = [
      "cn.lceda.LCEDAPro"
      "app.organicmaps.desktop"
      "io.github.rinigus.PureMaps" # difficult to use
      # followings are built from source by flathub:
      "com.giadamusic.Giada" # Home folder read/write access!
    ];
  };

}
