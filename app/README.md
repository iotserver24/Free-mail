# Freemail Mobile Applications

This directory contains the mobile and desktop applications for Freemail.

## Structure

```
app/
└── frontend/        # Flutter application for Android, iOS, Windows, and macOS
```

## Frontend App

The frontend app is a cross-platform Flutter application that provides a Gmail-like interface for managing emails through your self-hosted Freemail backend.

### Supported Platforms

- **Android**: Universal APK (works on all Android devices)
- **iOS**: All architectures supported
- **Windows**: Desktop application
- **macOS**: Universal binary (Intel and Apple Silicon)

### Quick Start

```bash
cd frontend
flutter pub get
flutter run
```

For detailed instructions, see [frontend/README.md](frontend/README.md)

## Features

- Self-hosted backend connection
- Secure credential storage
- Gmail-like email interface
- Email composition and management
- Domain management
- AI-powered features
- Multi-platform support

## Requirements

- Flutter SDK 3.0+
- Platform-specific development tools (see frontend/README.md)

## Building

Each platform has its own build command:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## Documentation

For more information, please refer to:
- [Frontend App Documentation](frontend/README.md)
- [Main Freemail Documentation](../README.md)
