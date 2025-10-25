#!/bin/bash

# Package Armor Build Script
# Creates .deb, .tar.gz, and Flatpak packages

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
APP_NAME="package-armor"
APP_DISPLAY_NAME="Package Armor"
VERSION="1.0.0"
DESCRIPTION="An advanced Flutter Linux desktop application for comprehensive package installation and management"
MAINTAINER="Piyu-Pika <piyushbhardwaj1603@gmail.com>"
HOMEPAGE="https://github.com/Piyu-Pika/linux_package_manager"
ICON_PATH="assets/icon/icon.png"

# Build directories
BUILD_DIR="build_output"
DEB_DIR="$BUILD_DIR/deb"
TARBALL_DIR="$BUILD_DIR/tarball"
FLATPAK_DIR="$BUILD_DIR/flatpak"

echo -e "${BLUE}=== Package Armor Build Script ===${NC}"
echo -e "${YELLOW}Building packages for version: $VERSION${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$DEB_DIR" "$TARBALL_DIR" "$FLATPAK_DIR"

# Build Flutter app for Linux
echo -e "${YELLOW}Building Flutter app for Linux...${NC}"
flutter clean
flutter pub get
flutter build linux --release

if [ ! -d "build/linux/x64/release/bundle" ]; then
    echo -e "${RED}Flutter build failed or bundle directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}Flutter build completed successfully${NC}"

# Function to create .deb package
create_deb_package() {
    echo -e "${YELLOW}Creating .deb package...${NC}"
    
    DEB_PACKAGE_DIR="$DEB_DIR/${APP_NAME}_${VERSION}_amd64"
    
    # Create directory structure
    mkdir -p "$DEB_PACKAGE_DIR/DEBIAN"
    mkdir -p "$DEB_PACKAGE_DIR/usr/bin"
    mkdir -p "$DEB_PACKAGE_DIR/usr/share/applications"
    mkdir -p "$DEB_PACKAGE_DIR/usr/share/pixmaps"
    mkdir -p "$DEB_PACKAGE_DIR/usr/share/$APP_NAME"
    
    # Copy application files
    cp -r build/linux/x64/release/bundle/* "$DEB_PACKAGE_DIR/usr/share/$APP_NAME/"
    
    # Create launcher script
    cat > "$DEB_PACKAGE_DIR/usr/bin/$APP_NAME" << EOF
#!/bin/bash
cd /usr/share/$APP_NAME
exec ./linux_package_manager "\$@"
EOF
    chmod +x "$DEB_PACKAGE_DIR/usr/bin/$APP_NAME"
    
    # Copy icon
    cp "$ICON_PATH" "$DEB_PACKAGE_DIR/usr/share/pixmaps/$APP_NAME.png"
    
    # Create desktop file
    cat > "$DEB_PACKAGE_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=$APP_DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=System;PackageManager;
StartupNotify=true
EOF
    
    # Create control file
    INSTALLED_SIZE=$(du -sk "$DEB_PACKAGE_DIR/usr" | cut -f1)
    cat > "$DEB_PACKAGE_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_SIZE
Depends: libc6, libgtk-3-0t64 | libgtk-3-0, libglib2.0-0, libpango-1.0-0, libcairo2, libgdk-pixbuf-2.0-0, libstdc++6
Maintainer: $MAINTAINER
Homepage: $HOMEPAGE
Description: $DESCRIPTION
 Package Armor is a comprehensive package management tool for Linux
 that supports multiple package formats and provides security scanning
 capabilities for installed packages.
EOF
    
    # Create postinst script
    cat > "$DEB_PACKAGE_DIR/DEBIAN/postinst" << EOF
#!/bin/bash
set -e
update-desktop-database || true
EOF
    chmod +x "$DEB_PACKAGE_DIR/DEBIAN/postinst"
    
    # Create postrm script
    cat > "$DEB_PACKAGE_DIR/DEBIAN/postrm" << EOF
#!/bin/bash
set -e
update-desktop-database || true
EOF
    chmod +x "$DEB_PACKAGE_DIR/DEBIAN/postrm"
    
    # Build the .deb package
    dpkg-deb --build "$DEB_PACKAGE_DIR"
    
    echo -e "${GREEN}.deb package created: ${DEB_PACKAGE_DIR}.deb${NC}"
}

# Function to create .tar.gz package
create_tarball_package() {
    echo -e "${YELLOW}Creating .tar.gz package...${NC}"
    
    TARBALL_PACKAGE_DIR="$TARBALL_DIR/${APP_NAME}-${VERSION}"
    
    # Create directory structure
    mkdir -p "$TARBALL_PACKAGE_DIR/bin"
    mkdir -p "$TARBALL_PACKAGE_DIR/share/applications"
    mkdir -p "$TARBALL_PACKAGE_DIR/share/pixmaps"
    mkdir -p "$TARBALL_PACKAGE_DIR/lib/$APP_NAME"
    
    # Copy application files
    cp -r build/linux/x64/release/bundle/* "$TARBALL_PACKAGE_DIR/lib/$APP_NAME/"
    
    # Create launcher script
    cat > "$TARBALL_PACKAGE_DIR/bin/$APP_NAME" << EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="\$SCRIPT_DIR/../lib/$APP_NAME"
cd "\$APP_DIR"
exec ./linux_package_manager "\$@"
EOF
    chmod +x "$TARBALL_PACKAGE_DIR/bin/$APP_NAME"
    
    # Copy icon
    cp "$ICON_PATH" "$TARBALL_PACKAGE_DIR/share/pixmaps/$APP_NAME.png"
    
    # Create desktop file
    cat > "$TARBALL_PACKAGE_DIR/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=$APP_DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=System;PackageManager;
StartupNotify=true
EOF
    
    # Create install script
    cat > "$TARBALL_PACKAGE_DIR/install.sh" << EOF
#!/bin/bash
set -e

echo "Installing $APP_DISPLAY_NAME..."

# Check if running as root
if [ "\$EUID" -eq 0 ]; then
    PREFIX="/usr"
else
    PREFIX="\$HOME/.local"
    mkdir -p "\$PREFIX/bin" "\$PREFIX/share/applications" "\$PREFIX/share/pixmaps"
fi

# Copy files
cp -r lib/$APP_NAME "\$PREFIX/share/"
cp bin/$APP_NAME "\$PREFIX/bin/"
cp share/pixmaps/$APP_NAME.png "\$PREFIX/share/pixmaps/"
cp share/applications/$APP_NAME.desktop "\$PREFIX/share/applications/"

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "\$PREFIX/share/applications" || true
fi

echo "$APP_DISPLAY_NAME installed successfully!"
echo "You can now run it with: $APP_NAME"
EOF
    chmod +x "$TARBALL_PACKAGE_DIR/install.sh"
    
    # Create uninstall script
    cat > "$TARBALL_PACKAGE_DIR/uninstall.sh" << EOF
#!/bin/bash
set -e

echo "Uninstalling $APP_DISPLAY_NAME..."

# Check if running as root
if [ "\$EUID" -eq 0 ]; then
    PREFIX="/usr"
else
    PREFIX="\$HOME/.local"
fi

# Remove files
rm -rf "\$PREFIX/share/$APP_NAME"
rm -f "\$PREFIX/bin/$APP_NAME"
rm -f "\$PREFIX/share/pixmaps/$APP_NAME.png"
rm -f "\$PREFIX/share/applications/$APP_NAME.desktop"

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "\$PREFIX/share/applications" || true
fi

echo "$APP_DISPLAY_NAME uninstalled successfully!"
EOF
    chmod +x "$TARBALL_PACKAGE_DIR/uninstall.sh"
    
    # Create README
    cat > "$TARBALL_PACKAGE_DIR/README.txt" << EOF
$APP_DISPLAY_NAME v$VERSION

$DESCRIPTION

Installation:
  sudo ./install.sh    # System-wide installation
  ./install.sh         # User installation

Uninstallation:
  sudo ./uninstall.sh  # System-wide removal
  ./uninstall.sh       # User removal

Running:
  $APP_NAME

For more information, visit: $HOMEPAGE
EOF
    
    # Create the tarball
    cd "$TARBALL_DIR"
    tar -czf "${APP_NAME}-${VERSION}.tar.gz" "${APP_NAME}-${VERSION}"
    cd - > /dev/null
    
    echo -e "${GREEN}.tar.gz package created: $TARBALL_DIR/${APP_NAME}-${VERSION}.tar.gz${NC}"
}

# Function to create Flatpak package
create_flatpak_package() {
    echo -e "${YELLOW}Creating Flatpak package...${NC}"
    
    # Check if flatpak-builder is available
    if ! command -v flatpak-builder >/dev/null 2>&1; then
        echo -e "${RED}flatpak-builder not found. Please install it to build Flatpak packages.${NC}"
        echo -e "${YELLOW}Skipping Flatpak package creation...${NC}"
        return
    fi
    
    # Check if ImageMagick is available for icon resizing
    if ! command -v convert >/dev/null 2>&1; then
        echo -e "${YELLOW}ImageMagick not found. Installing for icon resizing...${NC}"
        sudo apt install -y imagemagick || {
            echo -e "${RED}Failed to install ImageMagick. Skipping Flatpak creation.${NC}"
            return
        }
    fi
    
    APP_ID="com.packagearmor.PackageArmor"
    FLATPAK_MANIFEST="$FLATPAK_DIR/$APP_ID.yml"
    
    # Create Flatpak manifest
    cat > "$FLATPAK_MANIFEST" << EOF
app-id: $APP_ID
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
command: $APP_NAME
finish-args:
  - --share=ipc
  - --socket=x11
  - --socket=wayland
  - --device=dri
  - --filesystem=host
  - --share=network
  - --talk-name=org.freedesktop.Flatpak
  - --system-talk-name=org.freedesktop.PackageKit
modules:
  - name: $APP_NAME
    buildsystem: simple
    build-commands:
      - mkdir -p /app/bin /app/share/applications /app/share/icons/hicolor/256x256/apps
      - cp -r bundle/* /app/
      - install -Dm755 $APP_NAME.sh /app/bin/$APP_NAME
      - install -Dm644 $APP_NAME.desktop /app/share/applications/$APP_ID.desktop
      - install -Dm644 $APP_NAME.png /app/share/icons/hicolor/256x256/apps/$APP_ID.png
    sources:
      - type: dir
        path: ../../build/linux/x64/release/bundle
        dest: bundle
      - type: file
        path: $APP_NAME.sh
      - type: file
        path: $APP_NAME.desktop
      - type: file
        path: $APP_NAME-256.png
EOF
    
    # Create launcher script for Flatpak
    cat > "$FLATPAK_DIR/$APP_NAME.sh" << EOF
#!/bin/bash
cd /app
exec ./linux_package_manager "\$@"
EOF
    chmod +x "$FLATPAK_DIR/$APP_NAME.sh"
    
    # Resize icon for Flatpak (max 512x512, must be square)
    convert "../../$ICON_PATH" -resize 256x256! "$FLATPAK_DIR/$APP_NAME-256.png"
    
    # Create desktop file for Flatpak
    cat > "$FLATPAK_DIR/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=$APP_DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$APP_ID
Terminal=false
Type=Application
Categories=System;PackageManager;
StartupNotify=true
EOF
    
    # Build Flatpak
    cd "$FLATPAK_DIR"
    
    # Add Flathub repository if not already added
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    
    # Install runtime if not available
    flatpak install -y flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08 || true
    
    # Build the Flatpak
    flatpak-builder --force-clean --repo=repo build-dir "$APP_ID.yml"
    
    # Create bundle
    flatpak build-bundle repo "${APP_ID}.flatpak" "$APP_ID"
    
    cd - > /dev/null
    
    echo -e "${GREEN}Flatpak package created: $FLATPAK_DIR/${APP_ID}.flatpak${NC}"
}

# Main execution
echo -e "${BLUE}Starting package creation...${NC}"

# Create all packages
create_deb_package
create_tarball_package
create_flatpak_package

# Summary
echo -e "${BLUE}=== Build Summary ===${NC}"
echo -e "${GREEN}All packages have been created in the '$BUILD_DIR' directory:${NC}"
echo -e "  📦 .deb package: $DEB_DIR/${APP_NAME}_${VERSION}_amd64.deb"
echo -e "  📦 .tar.gz package: $TARBALL_DIR/${APP_NAME}-${VERSION}.tar.gz"
if [ -f "$FLATPAK_DIR/com.packagearmor.PackageArmor.flatpak" ]; then
    echo -e "  📦 Flatpak package: $FLATPAK_DIR/com.packagearmor.PackageArmor.flatpak"
else
    echo -e "  ⚠️  Flatpak package: Not created (flatpak-builder not available)"
fi

echo -e "${GREEN}Build completed successfully!${NC}"