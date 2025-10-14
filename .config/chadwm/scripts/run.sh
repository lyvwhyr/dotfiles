#!/bin/sh
# had issues with zed and zed-editor not exiting
trap 'pkill -x zed; pkill -x zed-editor' EXIT

# Fail fast on missing commands
set -u
export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
# declare session type so portals don’t guess
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=dwm
export DESKTOP_SESSION=chadwm

# make env visible to user services
command -v systemctl >/dev/null && systemctl --user import-environment DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP DESKTOP_SESSION
command -v dbus-update-activation-environment >/dev/null && dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP DESKTOP_SESSION


# Helper for logging all the commands
LOG_FILE="$HOME/.local/share/chadwm.log"
echo "" > "$LOG_FILE"
run() { "$@" >>"$LOG_FILE" 2>&1 & }

SCRIPTS_DIR=$(dirname "$0")

# Environment
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# Merge Xresources
XRESOURCES_FILE="$HOME/.Xresources"
[ -f "$XRESOURCES_FILE" ] && xrdb -merge "$XRESOURCES_FILE"

# Optional helpers if present
command -v brightnessctl >/dev/null && brightnessctl set 100% &
command -v xset >/dev/null && xset r rate 200 50 &

# wallpaper stuff
 WALLPAPER="$HOME/Pictures/wallpapers/Akiakane.png"
command -v feh >/dev/null && [ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" &
command -v picom >/dev/null && run picom



# Max out resolution + refresh on all connected outputs; enable VRR and Full RGB if supported
if command -v xrandr >/dev/null; then
  for out in $(xrandr | awk '/ connected/{print $1}'); do
    pref_mode=$(xrandr | awk -v o="$out" '
      $1==o {in=1; next} in && / connected/ {in=0}
      in && /\+/ {print $1; exit}
    ')
    [ -n "$pref_mode" ] || pref_mode=$(xrandr | awk -v o="$out" '
      $1==o {in=1; next} in && / connected/ {in=0}
      in && $1 ~ /^[0-9]+x[0-9]+$/ {print $1; exit}
    ')
    best_rate=$(xrandr | awk -v o="$out" -v m="$pref_mode" '
      $1==o {in=1; next} in && / connected/ {in=0}
      in && $1==m {
        for (i=2;i<=NF;i++) { s=$i; gsub("[*+]","",s); if (s ~ /^[0-9]+\.[0-9]+$/ && s>max) max=s }
      } END { if (max!="") print max }
    ')
    xrandr --output "$out" --mode "$pref_mode" ${best_rate:+--rate "$best_rate"}
    xrandr --output "$out" --set "VRR" on 2>/dev/null || true
    xrandr --output "$out" --set "Broadcast RGB" "Full" 2>/dev/null || true
  done
fi

# Status bar
BAR_SCRIPT="$SCRIPTS_DIR/bar.sh"
[ -x "$BAR_SCRIPT" ] && "$BAR_SCRIPT" &


# Startup apps
pgrep -x nm-applet >/dev/null || run nm-applet
pgrep -x dunst     >/dev/null || run dunst
pgrep -x zed       >/dev/null || run /home/feral/.local/bin/zed
# pgrep -x keepassxc >/dev/null || run keepassxc
pgrep - x signal-desktop >/dev/null || run signal-desktop
pgrep -x firefox   >/dev/null || run firefox



# start screensaver after 5 min
xset s 300 5
xset +dpms dpms 0 0 600
pgrep -x xss-lock  >/dev/null || run xss-lock -- "$HOME/.local/bin/lock.sh"

# Start window manager; replace shell with chadwm
exec chadwm >>"$LOG_FILE" 2>&1
