# Contributing to PackageArmor

Thank you for your interest in contributing to PackageArmor! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Types of Contributions
- 🐛 **Bug Reports**: Help us identify and fix issues
- ✨ **Feature Requests**: Suggest new features and improvements
- 📝 **Documentation**: Improve docs, guides, and examples
- 🔧 **Code Contributions**: Fix bugs, implement features, improve performance
- 🌍 **Translations**: Help make PackageArmor accessible worldwide
- 🎨 **Design**: UI/UX improvements and design assets

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.0 or higher
- **Dart SDK**: 3.0 or higher
- **Linux Development Environment**: Ubuntu 20.04+ recommended
- **Git**: For version control
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA

### Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/packagearmor.git
   cd packagearmor
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code**
   ```bash
   dart run build_runner build
   ```

4. **Run the Application**
   ```bash
   flutter run -d linux
   ```

5. **Run Tests**
   ```bash
   flutter test
   ```

## 📋 Development Guidelines

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format code
- Use `dart analyze` to check for issues
- Maximum line length: 120 characters

### Project Structure
```
lib/
├── config/          # Configuration and API management
├── models/          # Data models and enums
├── providers/       # Riverpod state management
├── screens/         # UI screens and widgets
├── services/        # Business logic and API services
└── main.dart        # Application entry point

test/
├── unit/           # Unit tests
├── widget/         # Widget tests
└── integration/    # Integration tests
```

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Private members**: `_leadingUnderscore`

### State Management
- Use **Riverpod** for state management
- Use **code generation** for providers (`@riverpod`)
- Keep business logic in services, not in UI
- Use async providers for API calls

### Security Guidelines
- **Never commit API keys** or secrets
- **Validate all inputs** from users and APIs
- **Use HTTPS** for all network requests
- **Handle errors gracefully** without exposing sensitive information
- **Follow security best practices** outlined in SECURITY.md

## 🐛 Bug Reports

### Before Reporting
1. **Search existing issues** to avoid duplicates
2. **Update to latest version** to see if bug is fixed
3. **Test on clean environment** if possible

### Bug Report Template
```markdown
**Describe the Bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected Behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- OS: [e.g. Ubuntu 22.04]
- PackageArmor Version: [e.g. 2.0.0]
- Flutter Version: [e.g. 3.16.0]

**Additional Context**
Any other context about the problem.
```

## ✨ Feature Requests

### Before Requesting
1. **Check existing requests** to avoid duplicates
2. **Consider the scope** - does it fit PackageArmor's mission?
3. **Think about implementation** - is it technically feasible?

### Feature Request Template
```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions you've considered.

**Additional context**
Any other context, mockups, or examples.
```

## 🔧 Code Contributions

### Workflow
1. **Create an issue** first (for significant changes)
2. **Fork the repository**
3. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
4. **Make your changes**
5. **Add tests** for new functionality
6. **Update documentation** if needed
7. **Commit your changes** (`git commit -m 'Add amazing feature'`)
8. **Push to branch** (`git push origin feature/amazing-feature`)
9. **Open a Pull Request**

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/):
```
type(scope): description

feat(security): add MetaDefender integration
fix(ui): resolve package list loading issue
docs(readme): update installation instructions
test(services): add unit tests for GitHub service
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Guidelines
- **Link to related issue** in PR description
- **Describe changes** clearly and concisely
- **Include screenshots** for UI changes
- **Ensure tests pass** and coverage is maintained
- **Update documentation** for new features
- **Keep PRs focused** - one feature/fix per PR

### Code Review Process
1. **Automated checks** must pass (tests, linting, formatting)
2. **Security review** for security-related changes
3. **Manual testing** by maintainers
4. **Documentation review** for user-facing changes
5. **Final approval** by project maintainers

## 🧪 Testing

### Test Types
- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete user flows

### Writing Tests
```dart
// Unit test example
test('should calculate file hash correctly', () async {
  final service = SecurityScannerService();
  final hash = await service.calculateFileHash('test_file.txt');
  expect(hash, isNotEmpty);
});

// Widget test example
testWidgets('should display package list', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Installed Packages'), findsOneWidget);
});
```

### Test Coverage
- Aim for **80%+ code coverage**
- **All new features** must have tests
- **Bug fixes** should include regression tests
- **Critical paths** must be thoroughly tested

## 📚 Documentation

### Types of Documentation
- **Code Comments**: Explain complex logic
- **API Documentation**: Document public APIs
- **User Guides**: Help users understand features
- **Developer Docs**: Architecture and contribution guides

### Documentation Standards
- Use **clear, concise language**
- Include **code examples** where helpful
- Keep documentation **up to date** with code changes
- Use **proper markdown formatting**

## 🌍 Internationalization

### Adding Translations
1. **Create locale files** in `lib/l10n/`
2. **Use ARB format** for translations
3. **Test with different locales**
4. **Update language selection** in settings

### Translation Guidelines
- **Keep text concise** but clear
- **Consider cultural context**
- **Test UI layout** with longer translations
- **Use proper pluralization** rules

## 🎨 Design Contributions

### Design System
- Follow **Material 3** design principles
- Use **consistent spacing** and typography
- Ensure **accessibility** compliance
- Support both **light and dark** themes

### Asset Guidelines
- **Icons**: Use Material Icons or consistent style
- **Images**: Optimize for different screen densities
- **Colors**: Follow Material 3 color system
- **Animations**: Keep subtle and purposeful

## 🏷️ Release Process

### Version Numbering
We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist
- [ ] Update version numbers
- [ ] Update CHANGELOG.md
- [ ] Run full test suite
- [ ] Update documentation
- [ ] Create release notes
- [ ] Tag release in Git
- [ ] Build and publish binaries

## 🏆 Recognition

### Contributors
All contributors are recognized in:
- **README.md**: Major contributors
- **CHANGELOG.md**: Feature and fix credits
- **Release Notes**: Acknowledgments
- **GitHub Contributors**: Automatic recognition

### Maintainer Path
Active contributors may be invited to become maintainers:
- **Consistent contributions** over time
- **High-quality code** and reviews
- **Community involvement** and support
- **Alignment with project values**

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Email**: security@packagearmor.dev (security issues)
- **Documentation**: [Wiki](https://github.com/your-repo/packagearmor/wiki)

### Mentorship
New contributors can get help from:
- **Good First Issues**: Labeled for beginners
- **Mentorship Program**: Pair with experienced contributors
- **Code Reviews**: Learn from feedback
- **Community Support**: Ask questions in discussions

## 📜 Code of Conduct

### Our Pledge
We are committed to making participation in our project a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience, nationality
- Personal appearance, race, religion
- Sexual identity and orientation

### Our Standards
**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- Harassment, trolling, or discriminatory comments
- Publishing others' private information
- Other conduct inappropriate in a professional setting

### Enforcement
Report violations to: conduct@packagearmor.dev

## 🙏 Thank You

Thank you for contributing to PackageArmor! Your efforts help make Linux package management safer and more accessible for everyone.

---

**Happy Contributing! 🚀**