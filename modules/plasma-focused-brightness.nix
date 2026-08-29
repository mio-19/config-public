# Focus-aware monitor brightness hotkeys for KDE Plasma 6 (see option `plasma_focused_brightness`).
#
# Inspired by llIlllIll's script on KDE Discuss:
# https://discuss.kde.org/t/plasma-6-2-brightness-control/21782/4
#
# Plasma 6 hardware brightness keys adjust every connected display by default.
# Disable PowerDevil's global shortcuts and bind Monitor Brightness Up/Down to a
# Rust helper that targets the focused display via org.kde.ScreenBrightness D-Bus
# and ramps on hold via evdev key-state tracking.
{ den, ... }:
let
  homeModule =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      enabled =
        (osConfig.plasma_focused_brightness.enable or false)
        && (osConfig.services.desktopManager.plasma6.enable or false);
      rustSrc = ./_plasma-focused-brightness/plasma-focused-brightness;
      plasmaFocusedBrightness = pkgs.rustPlatform.buildRustPackage {
        pname = "plasma-focused-brightness";
        version = "0.1.0";
        src = rustSrc;
        cargoLock.lockFile = "${rustSrc}/Cargo.lock";
        meta.mainProgram = "plasma-focused-brightness";
      };
    in
    lib.mkIf enabled {
      programs.plasma = {
        enable = true;

        shortcuts = {
          org_kde_powerdevil = {
            "Increase Screen Brightness" = "none";
            "Decrease Screen Brightness" = "none";
          };
        };

        hotkeys.commands = {
          "increase-focused-brightness" = {
            name = "Increase Focused Display Brightness";
            comment = "increase-focused-brightness";
            # KDE names hardware brightness keys "Monitor Brightness Up/Down" in
            # kglobalshortcutsrc, not XF86MonBrightnessUp/Down.
            key = "Monitor Brightness Up";
            command = "${lib.getExe plasmaFocusedBrightness} up";
            logs.enabled = false;
          };
          "decrease-focused-brightness" = {
            name = "Decrease Focused Display Brightness";
            comment = "decrease-focused-brightness";
            key = "Monitor Brightness Down";
            command = "${lib.getExe plasmaFocusedBrightness} down";
            logs.enabled = false;
          };
        };
      };
    };
in
{
  den.aspects.plasma-focused-brightness = {
    description = "KDE Plasma: brightness keys adjust focused display only";

    # Host-aspect homeManager branches are not forwarded to HM users by Den;
    # deliver via nixos home-manager.sharedModules (see desktopextra.nix).
    nixos =
      { config, lib, ... }:
      {
        home-manager.sharedModules =
          lib.mkIf (config.plasma_focused_brightness.enable && config.services.desktopManager.plasma6.enable)
            [
              homeModule
            ];

        # Hold-repeat reads /dev/input; primary desktop user on NixOS hosts.
        users.users.user.extraGroups = lib.mkIf (
          config.plasma_focused_brightness.enable && config.services.desktopManager.plasma6.enable
        ) [ "input" ];
      };

    homeManager = {
      imports = [ homeModule ];
    };
  };
}
