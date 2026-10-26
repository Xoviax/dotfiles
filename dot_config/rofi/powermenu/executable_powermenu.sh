#!/usr/bin/env bash

## Rofi Powermenu Script

theme="$HOME/.config/rofi/powermenu/powermenu.rasi"

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`uname -n`

# Options
shutdown=''
reboot=''
lock=''
suspend=''
logout=''

# Rofi CMD
rofi_cmd() {
    rofi -dmenu \
        -p "Uptime: $uptime" \
        -theme "$theme"
}

# Pass options to rofi
run_rofi() {
    echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $lock)
        ~/.config/hypr/scripts/lock.sh
        ;;
    $suspend)
        systemctl suspend
        ;;
    $logout)
        hyprctl dispatch exit
        ;;
esac
