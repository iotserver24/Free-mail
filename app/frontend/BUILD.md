# Building Freemail Mobile App

This guide explains how to build the Freemail mobile app for all supported platforms.

## Prerequisites

### General Requirements
- Flutter SDK 3.0 or higher
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Platform-Specific Requirements

#### Android
- Android Studio (or Android SDK command-line tools)
- Java Development Kit (JDK) 11 or higher
- Android SDK Platform-Tools
- Android SDK Build-Tools

#### iOS
- macOS (required)
- Xcode 14 or higher
- CocoaPods
- iOS deployment target: iOS 12.0+

#### Windows
- Windows 10 or higher (64-bit)
- Visual Studio 2022 with:
  - Desktop development with C++
  - Windows 10 SDK

#### macOS Desktop
- macOS 10.14 or higher
- Xcode 14 or higher
- CocoaPods

## Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Free-mail/app/frontend
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**:
   ```bash
   flutter doctor
   ```
   
   Fix any issues reported by `flutter doctor` before proceeding.

## Building for Different Platforms

### Android

#### Debug Build (for testing)
```bash
flutter run -d android
```

#### Release APK (Universal - works on all Android devices)
```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### Architecture-Specific APKs (smaller file size)
```bash
# ARM 32-bit
flutter build apk --target-platform android-arm --release

# ARM 64-bit
flutter build apk --target-platform android-arm64 --release

# x86 64-bit (emulators)
flutter build apk --target-platform android-x64 --release
```

#### App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

The App Bundle will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

### iOS

#### Debug Build (for testing)
```bash
flutter run -d ios
```

#### Release Build
```bash
flutter build ios --release
```

Then open the project in Xcode:
```bash
open ios/Runner.xcworkspace
```

In Xcode:
1. Select your development team
2. Choose a signing certificate
3. Select Product > Archive
4. Follow the prompts to distribute your app

#### Build for Specific Architectures
```bash
# For physical devices (arm64)
flutter build ios --release

# For simulator (x86_64/arm64)
flutter build ios --release --simulator
```

### Windows

#### Debug Build (for testing)
```bash
flutter run -d windows
```

#### Release Build
```bash
flutter build windows --release
```

The executable and required files will be in:
```
build/windows/runner/Release/
```

To distribute:
1. Copy the entire `Release` folder
2. Or create an installer using tools like:
   - Inno Setup
   - NSIS (Nullsoft Scriptable Install System)
   - WiX Toolset

### macOS Desktop

#### Debug Build (for testing)
```bash
flutter run -d macos
```

#### Release Build (Universal Binary - Intel + Apple Silicon)
```bash
flutter build macos --release
```

The app bundle will be in:
```
build/macos/Build/Products/Release/freemail.app
```

#### Architecture-Specific Builds
```bash
# Intel only
flutter build macos --release --dart-define=FLUTTER_BUILD_MODE=release --target-platform macos-x64

# Apple Silicon only
flutter build macos --release --dart-define=FLUTTER_BUILD_MODE=release --target-platform macos-arm64
```

To distribute:
1. Right-click the `.app` bundle and select "Compress"
2. Or create a DMG using tools like `create-dmg`

## Code Signing

### Android
For production releases, you need to sign your APK/App Bundle:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=<path-to-keystore>
   ```

3. Update `android/app/build.gradle` to use the keystore

### iOS
Code signing is managed through Xcode:
1. Open the project in Xcode
2. Select the Runner target
3. Go to Signing & Capabilities
4. Select your team and provisioning profile

### macOS
Similar to iOS, managed through Xcode:
1. Open `macos/Runner.xcworkspace`
2. Configure signing in Signing & Capabilities

## Testing Builds

### Run on Emulator/Simulator
```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d "iPhone 14"

# List all available devices
flutter devices
```

### Install on Physical Device

#### Android (via ADB)
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### iOS
Use Xcode or TestFlight for distribution to physical devices.

## Troubleshooting

### Common Issues

#### "Flutter SDK not found"
- Ensure Flutter is in your PATH
- Run `flutter doctor` to diagnose

#### Android build fails
- Update Android SDK: `sdkmanager --update`
- Clean build: `flutter clean && flutter pub get`
- Check Java version: `java -version` (should be 11+)

#### iOS build fails
- Update CocoaPods: `sudo gem install cocoapods`
- Clean pods: `cd ios && pod deintegrate && pod install`
- Update Xcode to the latest version

#### Windows build fails
- Ensure Visual Studio 2022 is installed with C++ tools
- Run as Administrator if permission errors occur

#### macOS build fails
- Update Xcode: `xcode-select --install`
- Clean build: `flutter clean`

### Performance Optimization

#### Reduce APK Size
```bash
# Enable R8 shrinking and obfuscation
flutter build apk --release --shrink

# Split APKs by ABI
flutter build apk --split-per-abi --release
```

#### Optimize for Release
All release builds automatically:
- Enable tree-shaking
- Minify code
- Obfuscate code (helps with security)
- Strip debug symbols

## Continuous Integration

### GitHub Actions Example
```yaml
name: Build Flutter App

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter build apk --release

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

## Distribution

### Android
- Google Play Store: Upload the App Bundle
- Direct distribution: Share the APK file
- Alternative stores: Amazon Appstore, F-Droid, etc.

### iOS
- App Store: Use Xcode or Transporter
- TestFlight: For beta testing
- Enterprise: With an Apple Developer Enterprise account

### Windows
- Microsoft Store: Create an MSIX package
- Direct distribution: Share the executable folder
- Package managers: Chocolatey, Scoop, etc.

### macOS
- Mac App Store: Use Xcode
- Direct distribution: Share DMG file
- Package managers: Homebrew Cask, etc.

## Support

For issues or questions:
1. Check the [Flutter documentation](https://docs.flutter.dev)
2. Review the main Freemail repository issues
3. Consult platform-specific build guides
