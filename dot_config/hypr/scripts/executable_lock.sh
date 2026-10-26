#!/usr/bin/env bash

# Lock screen wrapper script
if command -v hyprlock >/dev/null 2>&1; then
    hyprlock
elif command -v swaylock >/dev/null 2>&1; then
    swaylock -f
elif command -v gtklock >/dev/null 2>&1; then
    gtklock
else
    notify-send -u normal -i system-lock-screen "Screen Lock" "No lock utility found.\nInstall hyprlock with: sudo pacman -S hyprlock"
fi
