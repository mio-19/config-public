# Focused-display brightness for KDE Plasma 6 hardware keys.
# Copied from KDE Discuss (llIlllIll, 2026-04):
# https://discuss.kde.org/t/plasma-6-2-brightness-control/21782/4
#
# usage: smart_brightness.sh up|down
# Expects: QDBUS (path to qdbus/qdbus6), STEP_PERCENT (optional, default 5)

set -euo pipefail

DIRECTION="${1:-}"
STEP_PERCENT="${STEP_PERCENT:-5}"

if [[ "$DIRECTION" != "up" && "$DIRECTION" != "down" ]]; then
  echo "Error: Invalid argument. Use 'up' or 'down'." >&2
  exit 1
fi

if [[ -z "${QDBUS:-}" ]]; then
  if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS=qdbus6
  elif command -v qdbus >/dev/null 2>&1; then
    QDBUS=qdbus
  else
    echo "Error: qdbus6 or qdbus not found." >&2
    exit 1
  fi
fi

ACTIVE_OUTPUT=$("$QDBUS" org.kde.KWin /KWin activeOutputName 2>/dev/null || true)
DISPLAYS=$("$QDBUS" org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness.DisplaysDBusNames 2>/dev/null || true)

if [[ -z "$DISPLAYS" ]]; then
  exit 0
fi

get_display_prop() {
  local disp="${1:?}"
  local prop="${2:?}"
  "$QDBUS" org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$disp" org.freedesktop.DBus.Properties.Get org.kde.ScreenBrightness.Display "$prop" 2>/dev/null || true
}

TARGET_DISPLAY=""

# Map KWin's active output to a PowerDevil ScreenBrightness node.
if [[ "$ACTIVE_OUTPUT" == eDP* ]] || [[ "$ACTIVE_OUTPUT" == LVDS* ]]; then
  for disp in $DISPLAYS; do
    if [[ "$(get_display_prop "$disp" "IsInternal")" == "true" ]]; then
      TARGET_DISPLAY=$disp
      break
    fi
  done
elif [[ -n "$ACTIVE_OUTPUT" ]]; then
  EDID_FILE=""
  for candidate in /sys/class/drm/*-"$ACTIVE_OUTPUT"/edid; do
    if [[ -f "$candidate" ]]; then
      EDID_FILE=$candidate
      break
    fi
  done

  BEST_MATCH=""
  HIGHEST_SCORE=0
  EDID_TEXT=""
  if [[ -f "$EDID_FILE" ]]; then
    EDID_TEXT=$(tr -cd '[:print:]' <"$EDID_FILE")
  fi

  for disp in $DISPLAYS; do
    if [[ "$(get_display_prop "$disp" "IsInternal")" == "true" ]]; then
      continue
    fi

    LABEL=$(get_display_prop "$disp" "Label")
    if [[ -n "$LABEL" && -n "$EDID_TEXT" ]]; then
      read -ra WORDS <<<"$LABEL"
      NUM_WORDS=${#WORDS[@]}
      SUBSTRING=""
      CURRENT_MATCH_LEN=0

      for ((i = NUM_WORDS - 1; i >= 0; i--)); do
        if [[ -z "$SUBSTRING" ]]; then
          SUBSTRING="${WORDS[i]}"
        else
          SUBSTRING="${WORDS[i]} $SUBSTRING"
        fi

        if echo "$EDID_TEXT" | grep -i -q "$SUBSTRING"; then
          CURRENT_MATCH_LEN=${#SUBSTRING}
        else
          break
        fi
      done

      if [[ "$CURRENT_MATCH_LEN" -gt "$HIGHEST_SCORE" ]]; then
        HIGHEST_SCORE=$CURRENT_MATCH_LEN
        BEST_MATCH=$disp
      fi
    fi
  done

  if [[ "$HIGHEST_SCORE" -gt 0 ]]; then
    TARGET_DISPLAY=$BEST_MATCH
  fi
fi

# NixOS addition: fall back to first controllable display instead of erroring on hotkey.
if [[ -z "$TARGET_DISPLAY" ]]; then
  read -r TARGET_DISPLAY _ <<<"$DISPLAYS"
fi

if [[ -z "$TARGET_DISPLAY" ]]; then
  exit 0
fi

CURRENT=$(get_display_prop "$TARGET_DISPLAY" "Brightness")
MAX=$(get_display_prop "$TARGET_DISPLAY" "MaxBrightness")

if [[ -z "$CURRENT" || -z "$MAX" ]]; then
  exit 0
fi

STEP=$((MAX * STEP_PERCENT / 100))
if [[ "$STEP" -eq 0 ]]; then
  STEP=1
fi

if [[ "$DIRECTION" == "up" ]]; then
  NEW_VAL=$((CURRENT + STEP))
else
  NEW_VAL=$((CURRENT - STEP))
fi

if [[ "$NEW_VAL" -lt 0 ]]; then
  NEW_VAL=0
fi
if [[ "$NEW_VAL" -gt "$MAX" ]]; then
  NEW_VAL=$MAX
fi

"$QDBUS" org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$TARGET_DISPLAY" org.kde.ScreenBrightness.Display.SetBrightness "$NEW_VAL" 0
