# 🛡️ Package Armor

**The Ultimate Secure Package Manager for Linux**

Package Armor is a modern, Flutter-based package manager that provides enterprise-grade security scanning and comprehensive package management across multiple Linux distributions and package sources.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)

## ✨ Features

### 🔒 **Multi-Provider Security Scanning**
- **VirusTotal Integration**: 70+ antivirus engines for comprehensive malware detection
- **Hybrid Analysis**: Advanced behavioral analysis and sandboxing for zero-day threats
- **MetaDefender**: Enterprise-grade security with data sanitization capabilities
- **Smart Provider Selection**: Choose the best security provider for your needs
- **Real-time Threat Detection**: Scan packages before installation automatically

### 📦 **Universal Package Management**
- **Multi-Source Support**: APT, Snap, Flatpak, GitHub releases, and local files
- **Intelligent Updates**: One-click updates for individual packages or system-wide
- **Smart Uninstall**: Safe removal with dependency checking
- **Package Discovery**: Search and discover packages from multiple sources
- **System Cleanup**: Remove orphaned packages and clean cache

### 🐙 **Advanced GitHub Integration**
- **Smart Asset Detection**: Automatically finds the best package for your architecture
- **Release Management**: Browse and install from GitHub releases
- **Architecture Matching**: Supports x86_64, ARM64, ARMv7, and i386
- **Format Prioritization**: Prefers .deb > .appimage > .tar.gz > .rpm based on your system

### 🎨 **Modern User Interface**
- **Material 3 Design**: Beautiful, responsive interface with dark/light themes
- **Real-time Updates**: Live progress tracking and status updates
- **Security Dashboard**: Comprehensive scan reports and threat analysis
- **Multi-platform**: Optimized for desktop and mobile screens

## 🚀 Quick Start

### Prerequisites
- Linux distribution (Ubuntu, Debian, Fedora, Arch, etc.)
- Flutter 3.0+ (for development)

### Installation

#### Option 1: Download Release (Recommended)
1. Go to [Releases](https://github.com/Piyu-Pika/linux_package_manager/releases)
2. Download the latest `.deb`, `.rpm`, or `.AppImage` for your system
3. Install using your package manager or run the AppImage

#### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/Piyu-Pika/linux_package_manager.git
cd linux_package_manager

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build

# Build for Linux
flutter build linux

# Run the application
./build/linux/x64/release/bundle/linux_package_manager
```

## 🔧 Configuration

### Security Provider Setup

linux_package_manager supports three security providers. Choose the one that best fits your needs:

#### 🦠 **VirusTotal** (Recommended for most users)
- **Best for**: General users, developers, quick malware detection
- **Strengths**: 70+ engines, large community database, free tier available
- **Setup**: 
  1. Visit [virustotal.com](https://www.virustotal.com)
  2. Create a free account
  3. Get your API key from Profile → API Key
  4. Configure in linux_package_manager Settings

#### 🔬 **Hybrid Analysis** (For security professionals)
- **Best for**: Security researchers, advanced threat analysis, zero-day detection
- **Strengths**: Behavioral analysis, sandboxing, detailed execution reports
- **Setup**:
  1. Visit [hybrid-analysis.com](https://www.hybrid-analysis.com)
  2. Register for an account
  3. Generate API key from Profile
  4. Configure in linux_package_manager Settings

#### 🏢 **MetaDefender** (For enterprises)
- **Best for**: Enterprise environments, regulated industries, compliance
- **Strengths**: 30+ engines, data sanitization, enterprise features
- **Setup**:
  1. Visit [metadefender.opswat.com](https://metadefender.opswat.com)
  2. Sign up for an account
  3. Create API key from API section
  4. Configure in linux_package_manager Settings

### Provider Comparison

| Feature | VirusTotal | Hybrid Analysis | MetaDefender |
|---------|------------|-----------------|--------------|
| **Engines** | 70+ | 1 (Behavioral) | 30+ |
| **Free File Size** | 32MB | 100MB | 50MB |
| **Analysis Type** | Static | Dynamic/Behavioral | Static + DLP |
| **Scan Speed** | Fast (1-2 min) | Slow (5-15 min) | Medium (2-5 min) |
| **Zero-day Detection** | Good | Excellent | Good |
| **Enterprise Features** | Limited | Advanced | Comprehensive |
| **Best For** | General Use | Research/Analysis | Enterprise |

## 📱 Usage

### Installing Packages

1. **Search & Discover**: Use the Discover tab to find packages
2. **Security Scan**: Packages are automatically scanned before installation
3. **Smart Installation**: linux_package_manager chooses the best installation method
4. **Progress Tracking**: Real-time installation progress and logs

### Managing Installed Packages

1. **View Installed**: See all packages with update indicators
2. **Update Packages**: One-click updates for individual or all packages
3. **Uninstall Safely**: Remove packages with dependency checking
4. **System Cleanup**: Clean cache and remove orphaned packages

### Security Reports

1. **Scan History**: View all security scans in the Security tab
2. **Threat Analysis**: Detailed threat information and risk assessment
3. **Provider Comparison**: See results from different security providers
4. **Export Reports**: Share scan results and security assessments

## 🛠️ Development

### Project Structure
```
lib/
├── config/          # API and configuration management
├── models/          # Data models and enums
├── providers/       # Riverpod state management
├── screens/         # UI screens and pages
└── services/        # Business logic and API services
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management and dependency injection
- **Dio**: HTTP client for API requests
- **SharedPreferences**: Local data persistence
- **Material 3**: Modern design system

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Building

```bash
# Development build
flutter run -d linux

# Release build
flutter build linux --release

# Generate code (after model changes)
dart run build_runner build --delete-conflicting-outputs
```

## 🔐 Security Features

### Threat Detection
- **Multi-Engine Scanning**: Up to 70+ antivirus engines
- **Behavioral Analysis**: Dynamic malware detection
- **Zero-day Protection**: Advanced threat detection capabilities
- **Risk Assessment**: Clear risk levels (Clean, Suspicious, Malicious)

### Privacy & Safety
- **Local Processing**: Package management happens locally
- **Secure APIs**: All security providers use encrypted connections
- **No Data Collection**: linux_package_manager doesn't collect personal data
- **Open Source**: Full transparency in security implementations

## 📊 Supported Platforms

### Linux Distributions
- ✅ Ubuntu / Debian (APT)
- ✅ Fedora / RHEL / CentOS (DNF/YUM)
- ✅ Arch Linux (Pacman)
- ✅ openSUSE (Zypper)
- ✅ Any Linux with Snap/Flatpak

### Package Formats
- ✅ `.deb` (Debian packages)
- ✅ `.rpm` (Red Hat packages)
- ✅ `.pkg.tar.xz` (Arch packages)
- ✅ `.appimage` (Universal Linux apps)
- ✅ `.tar.gz/.tar.xz` (Source archives)
- ✅ Snap packages
- ✅ Flatpak applications

### Architectures
- ✅ x86_64 (AMD64)
- ✅ ARM64 (AArch64)
- ✅ ARMv7 (ARM32)
- ✅ i386 (32-bit x86)

## 🤝 Community

### Support
- 📖 [Documentation](https://github.com/Piyu-Pika/linux_package_manager/wiki)
- 🐛 [Issue Tracker](https://github.com/Piyu-Pika/linux_package_manager/issues)
- 💬 [Discussions](https://github.com/Piyu-Pika/linux_package_manager/discussions)

### Security
- 🔒 [Security Policy](SECURITY.md)
- 🚨 [Report Vulnerabilities](mailto:security@linux_package_manager.dev)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **VirusTotal** for their comprehensive malware detection API
- **Hybrid Analysis** for advanced behavioral analysis capabilities
- **MetaDefender** for enterprise-grade security features
- **Flutter Team** for the amazing cross-platform framework
- **Linux Community** for the diverse ecosystem of package managers

---

<div align="center">

**Made with ❤️ for the Linux Community**

[⭐ Star this project](https://github.com/Piyu-Pika/linux_package_manager) • [🐛 Report Bug](https://github.com/Piyu-Pika/linux_package_manager/issues) • [✨ Request Feature](https://github.com/Piyu-Pika/linux_package_manager/issues)

</div>