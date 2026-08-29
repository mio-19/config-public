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
    enable = enable-fcitx;
    fcitx5 = {
      waylandFrontend = true;
      fcitx5-with-addons = pkgs.kdePackages.fcitx5-with-addons;
      addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
        fcitx5-gtk
        fcitx5-nord
      ];
      # On KDE Wayland, KWin should launch fcitx5 via Virtual Keyboard settings.
      systemd.enable = !(osConfig.services.desktopManager.plasma6.enable or false);
      # HM manages ~/.config/fcitx5; learned words live in ~/.local/share/fcitx5/pinyin/user.{dict,history}
      ignoreUserConfig = false;
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "pinyin";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "pinyin";
      };
      settings.addons.pinyin.globalSection = {
        # Without this, fcitx5-chinese-addons shows the cloud-pinyin prompt every boot
        # because HM owns ~/.config/fcitx5 and user-written pinyin.conf cannot stick.
        FirstRun = false;
        CloudPinyinEnabled = false;
      };
      settings.addons.classicui.globalSection =
        if osConfig.services.desktopManager.plasma6.enable then
          {
            Theme = "plasma";
            DarkTheme = "plasma";
            UseDarkTheme = true;
          }
        else
          {
            Theme = "Nord-Light";
            DarkTheme = "Nord-Dark";
            UseDarkTheme = true;
          };
    };
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
