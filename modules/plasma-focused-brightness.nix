# Focus-aware monitor brightness hotkeys for KDE Plasma 6 (see option `plasma_focused_brightness`).
#
# Plasma 6 hardware brightness keys adjust every connected display by default.
# Disable PowerDevil's global shortcuts and bind XF86MonBrightnessUp/Down to a
# script that targets the focused display via org.kde.ScreenBrightness D-Bus.
{ den, ... }:
{
  den.aspects.plasma-focused-brightness = {
    description = "KDE Plasma: brightness keys adjust focused display only";

    homeManager = {
      imports = [
        (
          {
            lib,
            osConfig,
            pkgs,
            ...
          }:
          let
            qdbus = lib.getExe' pkgs.kdePackages.qttools "qdbus";
          in
          {
            programs.plasma =
              lib.mkIf
                (
                  (osConfig.plasma_focused_brightness.enable or false)
                  && (osConfig.services.desktopManager.plasma6.enable or false)
                )
                (
                  let
                    stepPercent = osConfig.plasma_focused_brightness.stepPercent or 5;

                    focusedBrightnessScript = pkgs.writeShellApplication {
                      name = "plasma-focused-brightness";
                      runtimeInputs = with pkgs; [
                        kdePackages.qttools
                        bash
                        coreutils
                        gnugrep
                      ];
                      text = ''
                        export QDBUS=${qdbus}
                        export STEP_PERCENT=${toString stepPercent}
                        ${builtins.readFile ./_plasma-focused-brightness/smart_brightness.sh}
                      '';
                    };
                  in
                  {
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
                        key = "XF86MonBrightnessUp";
                        command = "${focusedBrightnessScript}/bin/plasma-focused-brightness up";
                      };
                      "decrease-focused-brightness" = {
                        name = "Decrease Focused Display Brightness";
                        key = "XF86MonBrightnessDown";
                        command = "${focusedBrightnessScript}/bin/plasma-focused-brightness down";
                      };
                    };
                  }
                );
          }
        )
      ];
    };
  };
}
