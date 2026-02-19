#!/bin/sh
# ~/.config/chadwm/scripts/bar.sh


set -u


# ^c$var^ = fg color
# ^b$var^ = bg color

# Best Practice: Get script's own directory for portability
SCRIPTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
THEME_FILE="$SCRIPTS_DIR/bar_themes/guvchad"

# Best Practice: Load theme with a fallback
if [ -f "$THEME_FILE" ]; then
    . "$THEME_FILE"
else
    # Fallback colors if theme is not found
    black="#282c34"
    white="#abb2bf"
    grey="#3e4452"
    green="#98c379"
    blue="#61afef"
    red="#e06c75"
    darkblue="#61afef"
fi

interval=0
updates_str=""

cpu() {
    load=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
    printf "^c$green^ %.2f" "$load"
}

mullvad_str=""
mullvad_interval=0

mullvad_status() {
  st="$(mullvad status 2>/dev/null || true)"

  [ -z "$st" ] && { printf "⛔ VPN"; return; }

  echo "$st" | grep -qi "Connected" && {
    loc="$(printf '%s\n' "$st" | sed -n 's/.*[[:space:]]in[[:space:]]\(.*\)$/\1/p' | head -n1)"
    [ -n "$loc" ] && printf "🔒 %s" "$loc" || printf "🔒"
    return
  }

  echo "$st" | grep -Eqi "Connecting|Reconnecting" && { printf "🟡 VPN"; return; }
  echo "$st" | grep -Eqi "Blocked|Lockdown" && { printf "⛔ VPN"; return; }

  printf ""
}


pkg_updates() {
  # Arch
  if command -v checkupdates >/dev/null 2>&1; then
    n=$(checkupdates 2>/dev/null | wc -l | sed 's/ //g')
  # Debian/Ubuntu
  elif command -v apt >/dev/null 2>&1; then
    n=$(apt list --upgradeable 2>/dev/null | grep -c upgradable || true)
  # Void
  elif command -v xbps-install >/dev/null 2>&1; then
    n=$(xbps-install -un 2>/dev/null | wc -l | sed 's/ //g')
  else
    n=""
  fi
  if [ -z "$n" ] || [ "$n" -eq 0 ] 2>/dev/null; then
    printf "^c$green^ Fully Updated"
  else
      printf "^c$green^ %s updates" "$n"
  fi
}

battery() {
    batt=$(ls /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)
    if [ -n "$batt" ]; then
        cap=$(cat "$batt/capacity")
        printf "^c$blue^ %s%%" "$cap"
    fi
}

brightness() {
    # Best Practice: Find backlight device dynamically
    backlight_dir=$(find /sys/class/backlight/ -mindepth 1 -maxdepth 1 | head -n 1)

    if [ -n "$backlight_dir" ] && [ -f "$backlight_dir/brightness" ] && [ -f "$backlight_dir/max_brightness" ]; then
        current=$(cat "$backlight_dir/brightness")
        max=$(cat "$backlight_dir/max_brightness")
        if [ "$max" -gt 0 ]; then
            percent=$(( 100 * current / max ))
            printf "^c$red^ %s%%" "$percent"
        fi
    fi
}

mem() {
    mem_val=$(free -h | awk '/^Mem/ {print $3}' | sed 's/i//')
    printf "^c$blue^^b$black^ %s" "$mem_val"
}

net_str=""
net_interval=0

net_status() {
  # Wi-Fi status via NetworkManager.
  if ! command -v nmcli >/dev/null 2>&1; then
    printf "󰤭 No nmcli"
    return
  fi

  wifi_info="$(nmcli -t -f IN-USE,SSID,RATE dev wifi 2>/dev/null | grep '^*' | head -n1 || true)"
  if [ -n "$wifi_info" ]; then
    ssid="$(printf '%s' "$wifi_info" | cut -d: -f2)"
    raw_rate="$(printf '%s' "$wifi_info" | cut -d: -f3 | sed 's/[[:space:]]//g')"
    rate=""
    case "$raw_rate" in
      *Mbit/s)
        rate_value="${raw_rate%Mbit/s}"
        [ -n "$rate_value" ] && rate="$(awk -v r="$rate_value" 'BEGIN { printf "%.1fGbit/s", r / 1000 }')"
        ;;
      *Gbit/s)
        rate_value="${raw_rate%Gbit/s}"
        [ -n "$rate_value" ] && rate="$(awk -v r="$rate_value" 'BEGIN { printf "%.1fGbit/s", r }')"
        ;;
    esac
    [ -z "$rate" ] && rate="$raw_rate"
    [ -n "$rate" ] && printf "󰤨 %s %s" "$ssid" "$rate" || printf "󰤨 %s" "$ssid"
  else
    printf "󰤭 Disconnected"
  fi
}

gpu_str=""
gpu_interval=0

gpu_temp() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    return
  fi

  t="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')"
  [ -n "$t" ] && printf " %s°C" "$t"
}


clock() {
	printf "^c$blue^^b$black^󱑆^c$blue^^b$black^ %s " "$(date '+%m-%dT%H:%M %Z')"
}

add_part() {
  [ -n "$1" ] && parts="${parts}${parts:+ }$1"
}

while true; do
  # Update package count periodically
  if [ "$interval" = 0 ] || [ $((interval % 3600)) = 0 ]; then
    updates_str=$(pkg_updates)
  fi

  # Refresh Mullvad less frequently (every 3 seconds)
  if [ "$mullvad_interval" = 0 ] || [ $((mullvad_interval % 3)) = 0 ]; then
    mullvad_str="$(mullvad_status)"
  fi

  # Refresh network less frequently (every 10 seconds)
  if [ "$net_interval" = 0 ] || [ $((net_interval % 10)) = 0 ]; then
    net_str="$(net_status)"
  fi

  # Refresh GPU temp (every 10 seconds)
  if [ "$gpu_interval" = 0 ] || [ $((gpu_interval % 10)) = 0 ]; then
    gpu_str="$(gpu_temp)"
  fi

  net_interval=$((net_interval + 1))
  gpu_interval=$((gpu_interval + 1))

  interval=$((interval + 1))
  mullvad_interval=$((mullvad_interval + 1))

  parts=""

  add_part "$updates_str"
  add_part "$gpu_str"
  # add_part "$(battery)"
  # add_part "$(brightness)"
  add_part "$(cpu)"
  add_part "$(mem)"
  add_part "$net_str"
  add_part "$mullvad_str"
  add_part "$(clock)"

  command -v xsetroot >/dev/null && xsetroot -name "$parts"
  sleep 1
done
