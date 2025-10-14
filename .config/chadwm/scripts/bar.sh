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

mullvad_status() {
  if mullvad status | grep -q "Connected"; then
    loc=$(mullvad status | sed -n 's/.*in \(.*\)$/\1/p')
    [ -n "$loc" ] && printf "🔒 %s" "$loc" || printf "🔒"
  else
    printf "❌ VPN"
  fi
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
    printf "  ^c$green^ Fully Updated"
  else
      printf "  ^c$green^ %s updates" "$n"
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

net_status() {
    # Network status with SSID and speed
    wifi_info=$(nmcli -t -f IN-USE,SSID,RATE dev wifi | grep '^*' | head -n1)

    if [ -n "$wifi_info" ]; then
        ssid=$(echo "$wifi_info" | cut -d: -f2)
        speed=$(echo "$wifi_info" | cut -d: -f3 | sed 's/ //g') # remove space
        printf "󰤨 %s %s" "$ssid" "$speed"
    else
        printf "󰤭 Disconnected"
    fi
}

clock() {
	printf "^c$blue^^b$black^󱑆^c$blue^^b$black^ %s " "$(date '+%m-%dT%H:%M %Z')"
}

# Helper function to build status string without extra spaces
add_part() {
  if [ -n "$1" ]; then
    if [ -n "$2" ]; then
      printf "%s %s" "$1" "$2"
    else
      printf "%s" "$2"
    fi
  fi
}

while true; do
  # Update package count periodically
  if [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ]; then
    updates_str=$(pkg_updates)
  fi
  interval=$((interval + 1))

  # Assemble status bar string robustly
  parts=""
  add_part() {
      [ -n "$1" ] && parts="${parts}${parts:+ }$1"
  }

  add_part "$updates_str"
  add_part "$(battery)"
  add_part "$(brightness)"
  add_part "$(cpu)"
  add_part "$(mem)"
  add_part "$(net_status)"
  add_part "$(mullvad_status)"
  add_part "$(clock)"

  sleep 1 && xsetroot -name "$parts"
done
