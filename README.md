# PackageArmor

A comprehensive Flutter desktop application for installing and managing Linux packages from multiple sources. This advanced package manager supports various package formats and repositories, making it easy to install software on any Linux distribution.

## Features

### 🔍 **Multi-Source Package Search**
- **APT Repository**: Search and install packages from APT repositories
- **Snap Store**: Browse and install Snap packages
- **Flatpak**: Access Flatpak applications
- **GitHub Releases**: Install software directly from GitHub releases
- **Custom URLs**: Download and install packages from any URL

### 📦 **Comprehensive Package Format Support**
- **.deb** packages (Debian/Ubuntu)
- **.rpm** packages (Red Hat/Fedora/SUSE)
- **.pkg** packages (Arch Linux)
- **.tar.gz/.tar.xz** archives with install scripts
- **AppImage** portable applications
- **Direct downloads** from URLs

### 🛠️ **Advanced Installation Features**
- **Automatic dependency resolution** for supported formats
- **Installation progress tracking** with detailed logs
- **Installation time measurement**
- **Rollback support** for failed installations
- **Batch installation** capabilities
- **🦠 VirusTotal Integration** for virus scanning before installation
- **Security risk warnings** with delayed confirmation for unsafe files
- **Scan result caching** to avoid repeated scans

### 📱 **Modern User Interface**
- **Material Design 3** with enhanced theming and modern color schemes
- **Responsive layout** with adaptive navigation (rail for desktop, bottom bar for mobile)
- **Improved visual hierarchy** with better spacing and typography
- **Enhanced cards and components** with subtle borders and improved contrast
- **Better user feedback** with loading states, empty states, and progress indicators
- **Polished dialogs and interactions** with modern button styles and animations
- **Intuitive iconography** with rounded icons and consistent visual language
- **Real-time search** with advanced filtering and source selection
- **Installation progress dialogs** with live output and better status indicators

### ⚙️ **System Integration**
- **Automatic system detection** (distribution, architecture, available package managers)
- **Privilege escalation** using pkexec for secure installations
- **Desktop integration** for AppImages
- **Settings persistence** with SharedPreferences

### 🔧 **Configuration & Settings**
- **Default package manager** selection
- **Auto-update package lists**
- **Installation confirmation** settings
- **System package visibility** toggle
- **Cache management**

## Supported Linux Distributions

This application works on any Linux distribution with the following package managers:
- **Debian/Ubuntu**: APT (.deb packages)
- **Fedora/RHEL/CentOS**: DNF/YUM (.rpm packages)
- **Arch Linux/Manjaro**: Pacman (.pkg packages)
- **openSUSE**: Zypper (.rpm packages)
- **Universal**: Snap, Flatpak, AppImage

## Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Linux desktop environment
- `pkexec` for privilege escalation (usually pre-installed)

### Build from Source
```bash
# Clone the repository
git clone <repository-url>
cd linux_package_manager

# Get dependencies
flutter pub get

# Build for Linux
flutter build linux

# Run the application
./build/linux/x64/release/bundle/linux_package_manager
```

### Dependencies
The app will automatically detect and use available package managers on your system:
- `apt` - for Debian/Ubuntu packages
- `dnf`/`yum` - for RPM-based distributions
- `pacman` - for Arch Linux
- `snap` - for Snap packages
- `flatpak` - for Flatpak applications

### VirusTotal Integration (Optional)
For virus scanning functionality:
1. Get a free API key from [VirusTotal.com](https://www.virustotal.com/)
2. Configure it in **Settings** → **Security & Virus Scanning**
3. See `VIRUSTOTAL_SETUP.md` for detailed setup instructions

## Usage

### 1. Search and Install Packages
- Use the **Search** tab to find packages across multiple sources
- Filter by package source (APT, Snap, Flatpak, GitHub)
- Click **Install** to download and install packages automatically

### 2. Install Local Package Files
- Use the **Install** tab to select local package files
- Supports .deb, .rpm, .pkg, .tar.gz, and .AppImage files
- View real-time installation logs

### 3. Manage Installed Packages
- View all installed packages in the **Installed Apps** tab
- Search and filter installed packages
- Uninstall packages with confirmation dialogs
- Toggle system package visibility

### 4. Configure Settings
- Access **Settings** to customize the application behavior
- Set default package manager
- Configure installation preferences
- View system information

## Architecture

### Core Components
- **Models**: Data structures for packages, installation results, and sources
- **Services**: Business logic for package management, search, and system detection
- **Screens**: UI components for different app sections
- **Enhanced Installer**: Advanced installation engine with multi-format support

### Key Services
- `SystemDetector`: Detects Linux distribution and available package managers
- `PackageSearchService`: Searches packages across multiple sources
- `EnhancedPackageInstaller`: Handles installation of various package formats
- `PackageManager`: Manages installed packages and uninstallation

## Security

- Uses `pkexec` for secure privilege escalation
- No hardcoded credentials or API keys
- Validates package integrity before installation
- Sandboxed installation processes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent cross-platform framework
- Linux package maintainers for their continuous work
- Open source community for inspiration and feedback
