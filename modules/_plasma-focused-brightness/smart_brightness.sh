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

# qdbus on Plasma 6 often returns typed values (e.g. "variant uint32 123").
dbus_string() {
  local raw="${1:-}"
  if [[ "$raw" =~ \"([^\"]+)\" ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi
  echo "$raw" | awk '{print $NF}'
}

dbus_bool() {
  dbus_string "${1:-}" | grep -qi '^true$'
}

dbus_int() {
  local raw="${1:-}"
  echo "$raw" | grep -oE '[0-9]+' | tail -1
}

get_display_prop() {
  local disp="${1:?}"
  local prop="${2:?}"
  "$QDBUS" org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$disp" org.freedesktop.DBus.Properties.Get org.kde.ScreenBrightness.Display "$prop" 2>/dev/null || true
}

ACTIVE_OUTPUT=$(dbus_string "$("$QDBUS" org.kde.KWin /KWin activeOutputName 2>/dev/null || true)")

DISPLAYS_RAW=$("$QDBUS" org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness.DisplaysDBusNames 2>/dev/null || true)
DISPLAY_LIST=()
while IFS= read -r disp; do
  [[ -n "$disp" ]] && DISPLAY_LIST+=("$disp")
done < <(
  echo "$DISPLAYS_RAW" | tr ',()"' ' \n' | grep -E '^[A-Za-z0-9]' | grep -Ev '^(QStringList|variant|string|uint|bool)$' || true
)

if [[ ${#DISPLAY_LIST[@]} -eq 0 ]]; then
  exit 0
fi

TARGET_DISPLAY=""

# Map KWin's active output to a PowerDevil ScreenBrightness node.
if [[ "$ACTIVE_OUTPUT" == eDP* ]] || [[ "$ACTIVE_OUTPUT" == LVDS* ]]; then
  for disp in "${DISPLAY_LIST[@]}"; do
    if dbus_bool "$(get_display_prop "$disp" "IsInternal")"; then
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

  for disp in "${DISPLAY_LIST[@]}"; do
    if dbus_bool "$(get_display_prop "$disp" "IsInternal")"; then
      continue
    fi

    LABEL=$(dbus_string "$(get_display_prop "$disp" "Label")")
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
  TARGET_DISPLAY=${DISPLAY_LIST[0]}
fi

if [[ -z "$TARGET_DISPLAY" ]]; then
  exit 0
fi

CURRENT=$(dbus_int "$(get_display_prop "$TARGET_DISPLAY" "Brightness")")
MAX=$(dbus_int "$(get_display_prop "$TARGET_DISPLAY" "MaxBrightness")")

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
