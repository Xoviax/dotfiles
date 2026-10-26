#!/usr/bin/env bash

# Clean session logout handler for Hyprland under UWSM / systemd / loginctl

if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then
    exec uwsm stop
elif [ -n "${XDG_SESSION_ID:-}" ]; then
    exec loginctl terminate-session "$XDG_SESSION_ID"
else
    hyprctl dispatch exit || loginctl terminate-user "$USER"
fi
