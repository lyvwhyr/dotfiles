#!/bin/sh
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
echo "--- Starting Session ---" > "$LOG_FILE"
run() { "$@" >>"$LOG_FILE" 2>&1 & }
log() { echo "[run.sh] $@" >> "$LOG_FILE"; }

SCRIPTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Environment
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# Merge Xresources
XRESOURCES_FILE="$HOME/.Xresources"
[ -f "$XRESOURCES_FILE" ] && xrdb -merge "$XRESOURCES_FILE"

# Optional helpers if present
command -v brightnessctl >/dev/null && brightnessctl set 100% &
command -v xset >/dev/null && xset r rate 200 50 &
if command -v xclip >/dev/null; then
  # export CLIPBOARD_COPY_CMD="xclip -selection clipboard"
  # export CLIPBOARD_PASTE_CMD="xclip -selection clipboard -o"
  # use this instead to avoid freezing of x
  export CLIPBOARD_COPY_CMD=...
  export CLIPBOARD_PASTE_CMD=...
fi

pkill -x picom 2>/dev/null || true
picom --config "$HOME/.config/picom/picom.conf" --log-level=warn --log-file "$HOME/.cache/picom.log" &

# command -v picom >/dev/null && { pgrep -x picom >/dev/null || run picom; }





if command -v xrandr >/dev/null; then
  XR_OUT=$(xrandr)
  MAX_WIDTH=0
  log "Configuring monitors..."

  # list of all connected outputs
  # awk checks second column for 'connected'
  CONNECTED=$(echo "$XR_OUT" | awk '$2=="connected"{print $1}')

  # Identify internal vs external
  # Common internal prefixes: eDP, LVDS, DSI.
  # grep -vE returns everything NOT matching pattern.
  INTERNAL=$(echo "$CONNECTED" | grep -E "^(eDP|LVDS|DSI)" || true)
  EXTERNAL=$(echo "$CONNECTED" | grep -vE "^(eDP|LVDS|DSI)" || true)

  TARGETS=""

  if [ -n "$EXTERNAL" ]; then
    log "External monitor(s) detected: $EXTERNAL"
    TARGETS="$EXTERNAL"

    # Disable internal display if external is present
    if [ -n "$INTERNAL" ]; then
        log "Disabling internal monitor: $INTERNAL"
        for out in $INTERNAL; do
            xrandr --output "$out" --off
        done
    fi
  else
    log "No external monitors found. Using internal."
    TARGETS="$INTERNAL"
  fi

  PREV_OUT=""
  for out in $TARGETS; do
    log "Configuring $out"

    # Robust preferred mode extraction (variable 'in' -> 'active')
    # 1. Look for mode with '+' (preferred)
    pref_mode=$(echo "$XR_OUT" | awk -v o="$out" '
      $1==o {active=1; next}
      active && / connected/ {exit}
      active && /\+/ {print $1; exit}
    ')
    # 2. Fallback to first resolution pattern if no '+' mode
    [ -n "$pref_mode" ] || pref_mode=$(echo "$XR_OUT" | awk -v o="$out" '
      $1==o {active=1; next}
      active && / connected/ {exit}
      active && $1 ~ /^[0-9]+x[0-9]+$/ {print $1; exit}
    ')

    if [ -n "$pref_mode" ]; then
      log "  Found mode: $pref_mode"

      # Track max width for DPI calculation
      current_width=$(echo "$pref_mode" | cut -d'x' -f1)
      # Sanitize number just in case
      case "$current_width" in ''|*[!0-9]*) current_width=0 ;; esac
      [ "$current_width" -gt "$MAX_WIDTH" ] && MAX_WIDTH=$current_width

      # Calculate position args (Chain monitors left-to-right)
      POS_ARG="--auto"
      if [ -n "$PREV_OUT" ]; then
         POS_ARG="--right-of $PREV_OUT"
      else
         POS_ARG="--pos 0x0 --primary"
      fi

      xrandr --output "$out" --mode "$pref_mode" $POS_ARG
      xrandr --output "$out" --set "VRR" on 2>/dev/null || true
      xrandr --output "$out" --set "Broadcast RGB" "Full" 2>/dev/null || true

      PREV_OUT="$out"
    else
      log "  No mode found for $out"
    fi
  done

  # Now apply DPI based on the largest screen found
  if [ "$MAX_WIDTH" -ge 3840 ]; then
    log "  Applying High DPI (168)"
    xrandr --dpi 168
    echo "Xft.dpi: 168" | xrdb -merge
  else
    log "  Applying Standard DPI (96)"
    xrandr --dpi 96
    echo "Xft.dpi: 96" | xrdb -merge
  fi
fi

# Status bar
BAR_SCRIPT="$SCRIPTS_DIR/bar.sh"
if [ -x "$BAR_SCRIPT" ]; then
  pkill -f "bar.sh" 2>/dev/null
  "$BAR_SCRIPT" &
fi

# zed configuraiton to use only nvidia gpu
# export ZED_DEVICE_ID=0x1f14


# Wallpaper Stuff
#WALLPAPER="$HOME/Pictures/wallpapers/Akiakane-3.jpg"
WALLPAPER="$HOME/Pictures/wallpapers/1625832559504.jpg"

command -v feh >/dev/null && [ -f "$WALLPAPER" ] && feh --bg-fill "$WALLPAPER" &



# Startup apps
pgrep -x nm-applet >/dev/null || run nm-applet
pgrep -x dunst     >/dev/null || run dunst
sleep 1
pgrep -x zed       >/dev/null || run zed
# pgrep -x keepassxc >/dev/null || run keepassxc
sleep 1
pgrep -x signal-desktop >/dev/null || run signal-desktop
sleep 1
pgrep -x firefox   >/dev/null || run firefox



# start screensaver after 5 min
xset s 300 5
xset +dpms dpms 0 0 600
pgrep -x xss-lock  >/dev/null || run xss-lock -- "$SCRIPTS_DIR/lock.sh"

# Start window manager; replace shell with chadwm
exec chadwm >>"$LOG_FILE" 2>&1
