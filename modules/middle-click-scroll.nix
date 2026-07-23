# Middle-click scrolling modes (see option `middle_click_scroll`).
#
# "plasma" (default) — all apps via Plasma/libinput:
#   System Settings → Mouse → "Hold down middle button and move mouse to scroll"
#   https://discuss.kde.org/t/this-week-in-kde-autoscrolling/18292
#   Caveat: breaks middle-button drag (GIMP, games, etc.).
#   https://bugs.kde.org/show_bug.cgi?id=504133
#
# "browsers" — Windows-like click-to-autoscroll in Chromium + LibreWolf only:
#   Chromium: --enable-blink-features=MiddleClickAutoscroll
#   LibreWolf/Firefox: general.autoScroll (+ middlemouse.paste) in include.nix
#
# "off" — neither.
#
# Do not enable plasma + browsers together: libinput swallows middle-click when
# ScrollButton is BTN_MIDDLE, so browser autoscroll never receives the click.
{ den, ... }:
{
  den.aspects.middle-click-scroll = {
    description = "Middle-click scroll: plasma (all apps) or browsers; gated by middle_click_scroll";

    nixos =
      {
        config,
        lib,
        ...
      }:
      {
        # NixOS Chromium: bake Blink flag into the package wrapper so PATH and
        # .desktop Exec= store paths both get it.
        # https://wiki.nixos.org/wiki/Chromium
        # https://askubuntu.com/questions/28150
        nixpkgs.overlays = lib.mkIf (config.middle_click_scroll == "browsers") [
          (final: prev: {
            chromium = prev.chromium.override (old: {
              commandLineArgs = lib.concatStringsSep " " (
                lib.filter (s: s != "") [
                  (old.commandLineArgs or "")
                  "--enable-blink-features=MiddleClickAutoscroll"
                ]
              );
            });
          })
        ];
      };

    homeManager = {
      imports = [
        (
          {
            lib,
            osConfig,
            ...
          }:
          {
            # Wayland: KWin Libinput/Defaults/Pointer (no per-device IDs).
            # https://github.com/KDE/kwin/blob/master/src/backends/libinput/connection.cpp
            # X11: XLbInptScrollOnButtonDown
            # https://invent.kde.org/plasma/plasma-desktop/-/commit/7717671f
            programs.plasma =
              lib.mkIf
                (
                  (osConfig.middle_click_scroll or "off") == "plasma"
                  && (osConfig.services.desktopManager.plasma6.enable or false)
                )
                {
                  enable = true;
                  configFile."kcminputrc" = {
                    "Libinput/Defaults/Pointer" = {
                      # LIBINPUT_CONFIG_SCROLL_ON_BUTTON_DOWN = 1<<2 = 4
                      ScrollMethod = 4;
                      # BTN_MIDDLE
                      ScrollButton = 274;
                    };
                    "Mouse" = {
                      XLbInptScrollOnButtonDown = true;
                    };
                  };
                };
          }
        )
      ];
    };
  };
}
