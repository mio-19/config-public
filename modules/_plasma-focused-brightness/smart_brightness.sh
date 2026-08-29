# Focused-display brightness for KDE Plasma 6 hardware keys.
# Copied from KDE Discuss (llIlllIll, 2026-04):
# https://discuss.kde.org/t/plasma-6-2-brightness-control/21782/4
#
# usage: smart_brightness.sh up|down
# Expects: QDBUS, STEP_PERCENT, REPEAT_INTERVAL_MS, REPEAT_GRACE_MS, HOLD_REPEAT

set -euo pipefail

DIRECTION="${1:-}"
STEP_PERCENT="${STEP_PERCENT:-5}"
REPEAT_INTERVAL_MS="${REPEAT_INTERVAL_MS:-50}"
REPEAT_GRACE_MS="${REPEAT_GRACE_MS:-400}"
HOLD_REPEAT="${HOLD_REPEAT:-1}"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/plasma-focused-brightness"
TARGET_CACHE_TTL_MS="${TARGET_CACHE_TTL_MS:-2000}"

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

now_ms() {
  local ts
  ts=$(date +%s%3N 2>/dev/null || true)
  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    echo "$ts"
  else
    echo $(($(date +%s) * 1000))
  fi
}

sleep_ms() {
  local seconds
  seconds=$(awk -v ms="$1" 'BEGIN { if (ms < 1) ms = 1; printf "%.3f\n", ms / 1000 }')
  sleep "$seconds"
}

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

resolve_target_display() {
  mkdir -p "$STATE_DIR"
  local cache_file="$STATE_DIR/target-display"
  local cache_stamp="$STATE_DIR/target-display.stamp"
  local now
  now=$(now_ms)

  if [[ -f "$cache_file" && -f "$cache_stamp" ]]; then
    local cached_at
    cached_at=$(cat "$cache_stamp")
    if (( now - cached_at < TARGET_CACHE_TTL_MS )); then
      cat "$cache_file"
      return
    fi
  fi

  local active_output
  active_output=$(dbus_string "$("$QDBUS" org.kde.KWin /KWin activeOutputName 2>/dev/null || true)")

  local displays_raw
  displays_raw=$("$QDBUS" org.kde.ScreenBrightness /org/kde/ScreenBrightness org.kde.ScreenBrightness.DisplaysDBusNames 2>/dev/null || true)
  local display_list=()
  while IFS= read -r disp; do
    [[ -n "$disp" ]] && display_list+=("$disp")
  done < <(
    echo "$displays_raw" | tr ',()"' ' \n' | grep -E '^[A-Za-z0-9]' | grep -Ev '^(QStringList|variant|string|uint|bool)$' || true
  )

  if [[ ${#display_list[@]} -eq 0 ]]; then
    return 0
  fi

  local target_display=""

  if [[ "$active_output" == eDP* ]] || [[ "$active_output" == LVDS* ]]; then
    for disp in "${display_list[@]}"; do
      if dbus_bool "$(get_display_prop "$disp" "IsInternal")"; then
        target_display=$disp
        break
      fi
    done
  elif [[ -n "$active_output" ]]; then
    local edid_file=""
    for candidate in /sys/class/drm/*-"$active_output"/edid; do
      if [[ -f "$candidate" ]]; then
        edid_file=$candidate
        break
      fi
    done

    local best_match=""
    local highest_score=0
    local edid_text=""
    if [[ -f "$edid_file" ]]; then
      edid_text=$(tr -cd '[:print:]' <"$edid_file")
    fi

    for disp in "${display_list[@]}"; do
      if dbus_bool "$(get_display_prop "$disp" "IsInternal")"; then
        continue
      fi

      local label
      label=$(dbus_string "$(get_display_prop "$disp" "Label")")
      if [[ -n "$label" && -n "$edid_text" ]]; then
        read -ra words <<<"$label"
        local num_words=${#words[@]}
        local substring=""
        local current_match_len=0

        for ((i = num_words - 1; i >= 0; i--)); do
          if [[ -z "$substring" ]]; then
            substring="${words[i]}"
          else
            substring="${words[i]} $substring"
          fi

          if echo "$edid_text" | grep -i -q "$substring"; then
            current_match_len=${#substring}
          else
            break
          fi
        done

        if [[ "$current_match_len" -gt "$highest_score" ]]; then
          highest_score=$current_match_len
          best_match=$disp
        fi
      fi
    done

    if [[ "$highest_score" -gt 0 ]]; then
      target_display=$best_match
    fi
  fi

  if [[ -z "$target_display" ]]; then
    target_display=${display_list[0]}
  fi

  if [[ -n "$target_display" ]]; then
    echo "$target_display" >"$cache_file"
    echo "$now" >"$cache_stamp"
    echo "$target_display"
  fi
}

adjust_brightness_once() {
  local direction="${1:?}"

  local target_display
  target_display=$(resolve_target_display || true)
  if [[ -z "$target_display" ]]; then
    return 0
  fi

  local current max step new_val
  current=$(dbus_int "$(get_display_prop "$target_display" "Brightness")")
  max=$(dbus_int "$(get_display_prop "$target_display" "MaxBrightness")")

  if [[ -z "$current" || -z "$max" ]]; then
    return 0
  fi

  step=$((max * STEP_PERCENT / 100))
  if [[ "$step" -eq 0 ]]; then
    step=1
  fi

  if [[ "$direction" == "up" ]]; then
    new_val=$((current + step))
  else
    new_val=$((current - step))
  fi

  if [[ "$new_val" -lt 0 ]]; then
    new_val=0
  fi
  if [[ "$new_val" -gt "$max" ]]; then
    new_val=$max
  fi

  "$QDBUS" org.kde.ScreenBrightness "/org/kde/ScreenBrightness/$target_display" org.kde.ScreenBrightness.Display.SetBrightness "$new_val" 0
}

run_hold_repeat_worker() {
  local direction="${1:?}"
  local stamp_file="$STATE_DIR/${direction}.stamp"
  local lock_file="$STATE_DIR/${direction}.repeat.lock"

  (
    flock -n 9 || exit 0
    exec 9>"$lock_file"

    local last_handled=""
    while true; do
      local stamp now
      stamp=$(cat "$stamp_file" 2>/dev/null || echo 0)
      now=$(now_ms)

      if [[ "$stamp" != "$last_handled" ]]; then
        adjust_brightness_once "$direction"
        last_handled=$stamp
      fi

      if (( now - stamp > REPEAT_GRACE_MS )); then
        break
      fi

      sleep_ms "$REPEAT_INTERVAL_MS"
    done
  ) &
}

touch_stamp() {
  local direction="${1:?}"
  mkdir -p "$STATE_DIR"
  echo "$(now_ms)" >"$STATE_DIR/${direction}.stamp"
}

touch_stamp "$DIRECTION"

if [[ "$HOLD_REPEAT" == "1" ]]; then
  run_hold_repeat_worker "$DIRECTION"
else
  adjust_brightness_once "$DIRECTION"
fi
