# Freemail Mobile App

A Flutter-based mobile application for Freemail - AI-powered email management system.

## Features

- **Multi-platform Support**: Built for Android, iOS, Windows, and macOS (both Intel and Apple Silicon)
- **Self-hosted Backend**: Connect to your own Freemail backend server
- **Secure Authentication**: Admin credentials stored securely on device
- **Gmail-like UI**: Familiar and intuitive email interface
- **Email Management**: Send, receive, and manage emails
- **Domain Management**: Add and manage custom domains
- **AI-Powered**: Leverage AI features from the Freemail backend
- **Offline Storage**: Secure local storage of backend URL and credentials

## Screenshots

_Coming soon_

## Prerequisites

- Flutter SDK 3.0 or higher
- For Android development:
  - Android Studio
  - Android SDK
- For iOS development:
  - macOS
  - Xcode 14+
- For Windows development:
  - Visual Studio 2022 with C++ development tools
- For macOS development:
  - macOS
  - Xcode 14+

## Getting Started

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd app/frontend
```

2. Install dependencies:
```bash
flutter pub get
```

### Running the App

#### Android
```bash
# For universal APK (works on all architectures)
flutter build apk --release

# Or run in debug mode
flutter run -d android
```

#### iOS
```bash
# For all iOS devices (both architectures supported)
flutter build ios --release

# Or run in debug mode
flutter run -d ios
```

#### Windows
```bash
flutter build windows --release

# Or run in debug mode
flutter run -d windows
```

#### macOS
```bash
# For both Intel and Apple Silicon
flutter build macos --release

# Or run in debug mode
flutter run -d macos
```

## Configuration

### First Launch

On first launch, you'll need to provide:

1. **Backend URL**: The URL of your self-hosted Freemail backend
   - Example: `https://your-backend.com`
   - Must include `http://` or `https://`

2. **Admin Email**: Your administrator email address

3. **Password**: Your administrator password

These credentials are securely stored on your device and used for all API requests.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── email_message.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── email_detail_screen.dart
│   └── settings_screen.dart
├── services/                 # Business logic & API
│   ├── auth_service.dart
│   ├── email_service.dart
│   └── storage_service.dart
└── widgets/                  # Reusable widgets
    ├── email_list_item.dart
    └── compose_dialog.dart
```

## Building for Production

### Android Universal APK
```bash
flutter build apk --release
```
The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (All Architectures)
```bash
flutter build ios --release
```
Then use Xcode to create an IPA for distribution.

### Windows
```bash
flutter build windows --release
```
The executable will be in: `build/windows/runner/Release/`

### macOS (Universal Binary - Intel & Apple Silicon)
```bash
flutter build macos --release
```
The app bundle will be in: `build/macos/Build/Products/Release/`

## Security

- Credentials are stored using `flutter_secure_storage`
- All API communications use HTTPS (recommended)
- Session cookies are securely managed
- No credentials are transmitted in clear text

## Troubleshooting

### Android Build Issues
- Ensure you have Java 11 or higher
- Run `flutter clean` and rebuild

### iOS Build Issues
- Update CocoaPods: `sudo gem install cocoapods`
- Run `cd ios && pod install`

### Windows Build Issues
- Ensure Visual Studio 2022 is installed with C++ tools
- Run as Administrator if permission issues occur

### macOS Build Issues
- Ensure Xcode command line tools are installed
- Check that your Apple Developer certificate is valid

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the same license as the Freemail project.

## Support

For issues, questions, or contributions, please visit the main Freemail repository.
