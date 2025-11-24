# Freemail Mobile Applications

This directory contains the mobile and desktop applications for Freemail - an AI-powered email management system.

## Overview

The Freemail mobile app provides a Gmail-like interface to access your self-hosted Freemail backend from multiple platforms. Built with Flutter, it offers a native experience on Android, iOS, Windows, and macOS.

## Structure

```
app/
└── frontend/        # Flutter application for Android, iOS, Windows, and macOS
    ├── lib/         # Source code
    ├── android/     # Android-specific files
    ├── ios/         # iOS-specific files
    ├── windows/     # Windows-specific files
    ├── macos/       # macOS-specific files
    └── docs/        # Documentation
```

## Features

### 🔐 Authentication & Security
- Self-hosted backend connection
- Secure credential storage (platform-specific)
- Session management
- Auto-login support

### 📧 Email Management
- Gmail-like inbox interface
- Email composition with CC/BCC support
- HTML email rendering
- Attachment support
- Multiple folders (Inbox, Sent, Drafts, Trash)
- Star/favorite emails
- Pull to refresh

### 🌐 Domain Management
- Add and manage custom domains
- Domain verification support
- Multiple domain support

### ⚙️ Settings & Customization
- Light/dark theme support
- Backend URL configuration
- Account management
- Preferences

### 🎨 User Interface
- Material Design 3
- Responsive layouts
- Platform-adaptive components
- Smooth animations
- Intuitive navigation

## Supported Platforms

| Platform | Min Version | Architectures | Status |
|----------|-------------|---------------|--------|
| **Android** | 5.0 (API 21) | Universal (all) | ✅ Ready |
| **iOS** | 12.0 | arm64 | ✅ Ready |
| **Windows** | 10 (1809+) | x64 | ✅ Ready |
| **macOS** | 10.14 | Universal (Intel + Apple Silicon) | ✅ Ready |

## Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Platform-specific tools (see [Build Guide](frontend/BUILD.md))
- Self-hosted Freemail backend

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Free-mail/app/frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### Building for Production

#### Android (Universal APK)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### iOS
```bash
flutter build ios --release
# Then use Xcode to create IPA
```

#### Windows
```bash
flutter build windows --release
```
Output: `build/windows/runner/Release/`

#### macOS (Universal Binary)
```bash
flutter build macos --release
```
Output: `build/macos/Build/Products/Release/freemail.app`

## Documentation

Comprehensive documentation is available in the `frontend/` directory:

- **[README.md](frontend/README.md)** - Overview and features
- **[BUILD.md](frontend/BUILD.md)** - Complete build instructions for all platforms
- **[CONFIGURATION.md](frontend/CONFIGURATION.md)** - Setup and configuration guide
- **[DEVELOPMENT.md](frontend/DEVELOPMENT.md)** - Developer guide and best practices
- **[PLATFORM_NOTES.md](frontend/PLATFORM_NOTES.md)** - Platform-specific information
- **[SCREENSHOTS.md](frontend/SCREENSHOTS.md)** - Screenshot guidelines
- **[FAQ.md](frontend/FAQ.md)** - Frequently asked questions

## Technology Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage
- **HTML Rendering**: flutter_html
- **Dependencies**: See [pubspec.yaml](frontend/pubspec.yaml)

## Architecture

```
lib/
├── main.dart           # App entry point
├── models/             # Data models
├── screens/            # UI screens
├── services/           # Business logic & API
├── widgets/            # Reusable components
└── utils/              # Utilities & helpers
```

The app follows a clean architecture pattern with:
- **Models**: Data structures for emails, attachments, etc.
- **Services**: API integration, authentication, storage
- **Screens**: Full-page views
- **Widgets**: Reusable UI components
- **Utils**: Helper functions and constants

## Key Features Implemented

✅ **Complete**
- Login with backend URL configuration
- Email list view with Gmail-like UI
- Email detail view with HTML rendering
- Email composition
- Domain management
- Settings screen
- Secure credential storage
- Multi-platform support
- Dark theme support
- Pull to refresh
- Error handling

🔄 **Planned**
- Push notifications
- Search functionality
- Email labels
- Advanced filters
- Offline support
- Widgets
- Share functionality

## Testing

Run tests with:
```bash
flutter test
```

For specific platforms:
```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d "iPhone 14"

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

## Contributing

We welcome contributions! Please see [DEVELOPMENT.md](frontend/DEVELOPMENT.md) for:
- Development setup
- Code style guidelines
- Pull request process
- Testing requirements

## Security

- Credentials stored using platform-specific secure storage
- HTTPS required for production backends
- No data collection or tracking
- Open source and auditable
- Regular security updates

## Performance

- Optimized builds for each platform
- Efficient memory usage (50-100 MB typical)
- Smooth 60 FPS animations
- Fast startup times
- Minimal battery impact

## Distribution

### Android
- Google Play Store (coming soon)
- Direct APK download
- F-Droid (planned)

### iOS
- App Store (coming soon)
- TestFlight (for beta testing)
- Enterprise distribution

### Windows
- Microsoft Store (planned)
- Direct download
- Package managers (Chocolatey, Scoop)

### macOS
- Mac App Store (planned)
- Direct DMG download
- Homebrew Cask (planned)

## Support

For help:
1. Check the [FAQ](frontend/FAQ.md)
2. Read the [documentation](frontend/)
3. Search [existing issues](../../issues)
4. Open a new issue if needed

## License

This project is licensed under the same license as the main Freemail project.

## Links

- **Main Repository**: [Free-mail](../../)
- **Backend Documentation**: [../backend/](../backend/)
- **Web Frontend**: [../frontend/](../frontend/)
- **Issues**: [GitHub Issues](../../issues)

---

**Built with ❤️ using Flutter**
