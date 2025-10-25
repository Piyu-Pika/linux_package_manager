#!/bin/bash
set -e

echo "Uninstalling Package Armor..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    PREFIX="/usr"
else
    PREFIX="$HOME/.local"
fi

# Remove files
rm -rf "$PREFIX/share/package-armor"
rm -f "$PREFIX/bin/package-armor"
rm -f "$PREFIX/share/pixmaps/package-armor.png"
rm -f "$PREFIX/share/applications/package-armor.desktop"

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$PREFIX/share/applications" || true
fi

echo "Package Armor uninstalled successfully!"
