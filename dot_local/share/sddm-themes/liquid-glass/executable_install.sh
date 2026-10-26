#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/usr/share/sddm/themes/liquid-glass"

if [[ $EUID -ne 0 ]]; then
    echo "==> Elevating privileges with sudo..."
    exec sudo bash "$0" "$@"
fi

echo "==> Installing Liquid Glass theme to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
cp -rf "$SCRIPT_DIR"/* "$TARGET_DIR"/
# Remove installer and setup script from theme asset directory
rm -f "$TARGET_DIR/install.sh"
rm -f "$TARGET_DIR/Xsetup"
chmod -R 755 "$TARGET_DIR"

echo "==> Configuring SDDM to use liquid-glass theme and 24px cursor..."
mkdir -p /etc/sddm.conf.d
cat << 'EOF' > /etc/sddm.conf.d/theme.conf
[Theme]
Current=liquid-glass
CursorTheme=breeze_cursors
CursorSize=24

[X11]
EnableHiDPI=false
EOF

if [[ -f /etc/sddm.conf ]]; then
    if grep -q "\[Theme\]" /etc/sddm.conf; then
        sed -i 's/^Current=.*/Current=liquid-glass/' /etc/sddm.conf
    else
        echo -e "\n[Theme]\nCurrent=liquid-glass" >> /etc/sddm.conf
    fi
fi

echo "==> Installing dynamic primary cursor centering in /usr/share/sddm/scripts/Xsetup..."
cp -f "$SCRIPT_DIR/Xsetup" /usr/share/sddm/scripts/Xsetup
chmod 755 /usr/share/sddm/scripts/Xsetup

echo "==> Done! Liquid Glass theme and cursor centering have been updated successfully."
echo "==> Display arrangement and cursor positioning are logged to /tmp/sddm-display.log on each display startup."
