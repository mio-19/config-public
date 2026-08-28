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
                        kdePackages.libkscreen
                        kdotool
                        jq
                        bash
                      ];
                      text = ''
                        ACTION="''${1:-up}"
                        STEP_PERCENT=${toString stepPercent}

                        DISPLAY_NODES=$(qdbus org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness.DisplaysDBusNames 2>/dev/null || true)
                        if [ -z "$DISPLAY_NODES" ]; then
                          exit 0
                        fi

                        readarray -t NODES <<< "$DISPLAY_NODES"
                        TARGET_NODE="''${NODES[0]}"

                        if [ "''${#NODES[@]}" -gt 1 ]; then
                          FOCUSED_OUTPUT=""
                          if kdotool getactivewindow >/dev/null 2>&1; then
                            JSON_DATA=$(kscreen-doctor -j)
                            FOCUSED_OUTPUT=$(echo "$JSON_DATA" | jq -r '.outputs[] | select(.enabled == true and .priority == 1) | .name')
                          fi

                          for NODE in "''${NODES[@]}"; do
                            LABEL=$(qdbus org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$NODE" org.kde.ScreenBrightness.Display.Label 2>/dev/null || true)
                            if [[ -n "$FOCUSED_OUTPUT" && "$LABEL" == *"$FOCUSED_OUTPUT"* ]]; then
                              TARGET_NODE="$NODE"
                              break
                            fi
                          done
                        fi

                        DBUS_PATH="/org/kde/ScreenBrightness/$TARGET_NODE"
                        CURRENT=$(qdbus org.kde.ScreenBrightness "$DBUS_PATH" org.kde.ScreenBrightness.Display.Brightness 2>/dev/null)
                        MAX=$(qdbus org.kde.ScreenBrightness "$DBUS_PATH" org.kde.ScreenBrightness.Display.BrightnessMax 2>/dev/null || echo 100)

                        STEP=$(( MAX * STEP_PERCENT / 100 ))
                        if [ "$STEP" -lt 1 ]; then STEP=1; fi

                        if [ "$ACTION" == "up" ]; then
                          NEW_VALUE=$(( CURRENT + STEP ))
                          if [ "$NEW_VALUE" -gt "$MAX" ]; then NEW_VALUE="$MAX"; fi
                        else
                          NEW_VALUE=$(( CURRENT - STEP ))
                          if [ "$NEW_VALUE" -lt 0 ]; then NEW_VALUE=0; fi
                        fi

                        qdbus org.kde.ScreenBrightness "$DBUS_PATH" org.kde.ScreenBrightness.Display.SetBrightness "$NEW_VALUE" 0
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
