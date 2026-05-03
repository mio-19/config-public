{
  inputs,
  config,
  pkgs,
  lib,
  # if fcitx is chosen for kde plasma virtual keyboard then maliit the real virtual keyboard doesn't wotk
  enable-fcitx,
  osConfig,
  ...
}:
{

  i18n.inputMethod = {
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    enable = enable-fcitx;
    fcitx5.fcitx5-with-addons = pkgs.kdePackages.fcitx5-with-addons;
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-gtk
      fcitx5-nord
    ];
  };

  # https://discourse.nixos.org/t/enabling-gnome-extensions-with-home-manager/59701/2
  home.packages = lib.mkIf (enable-fcitx && osConfig.services.desktopManager.gnome.enable) (
    with pkgs;
    [
      gnomeExtensions.kimpanel
    ]
  );
  dconf = lib.mkIf (enable-fcitx && osConfig.services.desktopManager.gnome.enable) {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "kimpanel@kde.org"
        ];
      };
    };
  };

}
