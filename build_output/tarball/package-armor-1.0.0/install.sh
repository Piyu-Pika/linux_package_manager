#!/bin/bash
set -e

echo "Installing Package Armor..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    PREFIX="/usr"
else
    PREFIX="$HOME/.local"
    mkdir -p "$PREFIX/bin" "$PREFIX/share/applications" "$PREFIX/share/pixmaps"
fi

# Copy files
cp -r lib/package-armor "$PREFIX/share/"
cp bin/package-armor "$PREFIX/bin/"
cp share/pixmaps/package-armor.png "$PREFIX/share/pixmaps/"
cp share/applications/package-armor.desktop "$PREFIX/share/applications/"

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$PREFIX/share/applications" || true
fi

echo "Package Armor installed successfully!"
echo "You can now run it with: package-armor"
