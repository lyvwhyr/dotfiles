#!/bin/sh

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# UI Elements
export XSECURELOCK_FONT="IBM Plex Mono"
export XSECURELOCK_SHOW_HOSTNAME=0    # Hide Hostname
export XSECURELOCK_SHOW_DATETIME=1    # Keep Date/Time
export XSECURELOCK_SHOW_KEYBOARD_LAYOUT=0

# Video Saver Setup
export XSECURELOCK_SAVER=saver_mpv

# Video path

# Video Selection
# saver_mpv expects a command that outputs file paths
#export XSECURELOCK_LIST_VIDEOS_COMMAND="echo /home/feral/01_bgm/ghibli.mkv"
export XSECURELOCK_LIST_VIDEOS_COMMAND="echo /home/feral/01_bgm/marathon_02.mkv"
#export XSECURELOCK_LIST_VIDEOS_COMMAND="echo /home/feral/01_bgm/moomin_winter_screensaver.mkv"

# saver_mpv reads these flags directly
# --video-align-x=1           : Align video to the RIGHT
# --video-margin-ratio-left   : 900px / 3440px ≈ 0.2616
export XSECURELOCK_VIDEOS_FLAGS="--video-align-x=1 --video-margin-ratio-left=0.2616 --no-audio --loop --panscan=1.0"

# -----------------------------------------------------------------------------
# Execution
# -----------------------------------------------------------------------------
# Note: Using the locally compiled version with the offset patch
exec /usr/local/bin/xsecurelock
