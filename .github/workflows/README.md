# GitHub Actions CI/CD for Flutter App

This directory contains GitHub Actions workflows for automatically building the Freemail Flutter app across all supported platforms.

## Workflows

### `build-flutter.yml`

Automatically builds the Flutter app for all platforms when changes are pushed to the `app/frontend/` directory.

**Platforms Built:**

1. **Android** (Universal APK)
   - Runs on: `ubuntu-latest`
   - Output: Universal APK (works on all Android architectures)
   - Artifact: `android-universal-apk`
   - Size: ~30-50 MB

2. **iOS** (Unsigned, No Code Signing)
   - Runs on: `macos-latest`
   - Output: Unsigned IPA
   - Artifact: `ios-unsigned-ipa`
   - Size: ~40-60 MB
   - Note: Requires code signing for App Store distribution

3. **Windows** (x64)
   - Runs on: `windows-latest`
   - Output: ZIP archive with executable and dependencies
   - Artifact: `windows-x64-app`
   - Size: ~60-80 MB

4. **macOS** (Universal Binary - Intel + Apple Silicon)
   - Runs on: `macos-latest`
   - Output: DMG disk image
   - Artifact: `macos-universal-dmg`
   - Size: ~60-80 MB

5. **Linux** (x64)
   - Runs on: `ubuntu-latest`
   - Output: Tarball with executable and dependencies
   - Artifact: `linux-x64-app`
   - Size: ~60-80 MB

## Triggers

The workflow runs on:
- **Push** to `main` or `copilot/**` branches (when `app/frontend/**` changes)
- **Pull Request** to `main` (when `app/frontend/**` changes)
- **Manual trigger** via workflow_dispatch

## Artifacts

All builds are uploaded as GitHub Actions artifacts with a 30-day retention period. You can download them from the Actions tab after a successful build.

### Artifact Names:
- `android-universal-apk` - Android APK
- `ios-unsigned-ipa` - iOS IPA (unsigned)
- `windows-x64-app` - Windows executable (ZIP)
- `macos-universal-dmg` - macOS app (DMG)
- `linux-x64-app` - Linux executable (tarball)

## Build Summary

After all builds complete, a summary job displays the build status for each platform in the Actions summary.

## Flutter Version

All builds use **Flutter 3.24.0** (stable channel) to ensure consistency across platforms.

## Usage

### Download Artifacts

1. Go to the Actions tab in GitHub
2. Click on the latest workflow run
3. Scroll down to the "Artifacts" section
4. Download the artifact for your platform

### Install on Device

**Android:**
```bash
adb install android-universal-apk/app-release.apk
```

**iOS:**
Requires code signing. Use Xcode to sign and install.

**Windows:**
Extract the ZIP and run `freemail.exe`

**macOS:**
Open the DMG and drag the app to Applications

**Linux:**
```bash
tar -xzf linux-x64-app.tar.gz
./freemail
```

## Code Signing

### iOS Code Signing
The workflow builds iOS without code signing. To create a signed build:
1. Download the unsigned IPA artifact
2. Use Xcode or fastlane to sign it
3. Or set up GitHub Secrets for automatic signing

### macOS Code Signing
The macOS build is unsigned. For distribution:
1. Download the DMG artifact
2. Sign it with your Apple Developer certificate
3. Notarize it for Gatekeeper compatibility

### Windows Code Signing
The Windows build is unsigned. For distribution:
1. Download the ZIP artifact
2. Sign it with a Windows code signing certificate

## Troubleshooting

### Build Failures

**Android:**
- Check Java version (requires Java 17)
- Verify Gradle compatibility

**iOS:**
- Ensure Xcode version compatibility
- Check CocoaPods dependencies

**Windows:**
- Verify Visual Studio components are available on runner
- Check CMake configuration

**macOS:**
- Verify Xcode version
- Check for Apple Silicon compatibility

**Linux:**
- Ensure all GTK dependencies are installed
- Check CMake and ninja availability

### Common Issues

1. **Flutter version mismatch**: Update `flutter-version` in workflow
2. **Dependency errors**: Run `flutter pub get` locally to verify
3. **Build timeout**: Increase timeout in workflow if needed
4. **Artifact upload fails**: Check artifact size limits

## Local Testing

To test builds locally before pushing:

```bash
# Android
cd app/frontend
flutter build apk --release

# iOS
flutter build ios --release --no-codesign

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## Extending the Workflow

### Add New Platforms

To add support for new platforms:
1. Add a new job in `build-flutter.yml`
2. Specify the appropriate runner OS
3. Add Flutter build command
4. Upload artifacts

### Add Tests

To add testing to the workflow:
```yaml
- name: Run tests
  run: flutter test
```

### Add Code Analysis

To add static analysis:
```yaml
- name: Analyze code
  run: flutter analyze
```

## References

- [Flutter CI/CD Documentation](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment)
