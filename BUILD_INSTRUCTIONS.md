# Package Armor Build Instructions

This document explains how to use the build script to create distribution packages for Package Armor.

## Prerequisites

Before running the build script, ensure you have the following installed:

### Required
- Flutter SDK (latest stable version)
- dpkg-deb (for .deb packages) - usually pre-installed on Debian/Ubuntu
- tar and gzip (for .tar.gz packages) - usually pre-installed

### Optional (for Flatpak)
- flatpak
- flatpak-builder
- org.freedesktop.Platform runtime

Install Flatpak dependencies:
```bash
# Install flatpak and flatpak-builder
sudo apt install flatpak flatpak-builder

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install required runtime and SDK
flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
```

## Usage

Simply run the build script:

```bash
./build_packages.sh
```

## Output

The script creates a `build_output` directory with three subdirectories:

### 1. DEB Package (`build_output/deb/`)
- **File**: `package-armor_1.0.0_amd64.deb`
- **Installation**: `sudo dpkg -i package-armor_1.0.0_amd64.deb`
- **Features**: 
  - System integration with desktop file
  - Automatic dependency handling
  - Clean uninstallation support

### 2. TAR.GZ Package (`build_output/tarball/`)
- **File**: `package-armor-1.0.0.tar.gz`
- **Installation**: Extract and run `./install.sh`
- **Features**:
  - Portable installation
  - User or system-wide installation options
  - Includes install/uninstall scripts

### 3. Flatpak Package (`build_output/flatpak/`)
- **File**: `com.packagearmor.PackageArmor.flatpak`
- **Installation**: `flatpak install com.packagearmor.PackageArmor.flatpak`
- **Features**:
  - Sandboxed execution
  - Universal Linux compatibility
  - Automatic dependency management

## Package Details

- **Application Name**: Package Armor
- **Package Name**: package-armor
- **Version**: 1.0.0
- **Architecture**: amd64
- **Executable**: linux_package_manager
- **Icon**: Uses `assets/icon/icon.png` (automatically resized for Flatpak)

## Verified Working

✅ **.deb package** - Tested and working on Ubuntu 24.04
✅ **.tar.gz package** - Tested and working with install script
✅ **Flatpak package** - Built successfully (may need runtime adjustments)

## Customization

To modify package details, edit the variables at the top of `build_packages.sh`:

```bash
APP_NAME="package-armor"
APP_DISPLAY_NAME="Package Armor"
VERSION="1.0.0"
DESCRIPTION="An advanced Flutter Linux desktop application..."
MAINTAINER="Package Armor Team <team@packagearmor.com>"
HOMEPAGE="https://github.com/packagearmor/package-armor"
```

## Troubleshooting

### Flutter Build Issues
- Ensure Flutter is properly installed: `flutter doctor`
- Clean previous builds: `flutter clean && flutter pub get`

### Permission Issues
- Make sure the script is executable: `chmod +x build_packages.sh`
- For system-wide installation, you may need sudo privileges

### Flatpak Issues
- If Flatpak creation fails, install flatpak-builder
- Ensure you have the required runtime installed
- The script will skip Flatpak creation if tools are missing

## Distribution

After building, you can distribute the packages:

- **DEB**: Upload to APT repository or distribute directly
- **TAR.GZ**: Host on website or GitHub releases
- **Flatpak**: Submit to Flathub or distribute directly

## Notes

- The script automatically cleans previous builds
- All packages include the application icon and desktop integration
- The .deb package includes proper dependency declarations
- The .tar.gz package supports both user and system installation
- The Flatpak package is sandboxed and includes all necessary permissions