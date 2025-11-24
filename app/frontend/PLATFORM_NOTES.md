# Platform-Specific Notes

This document contains platform-specific information, tips, and known issues for the Freemail mobile app.

## Android

### Supported Versions
- Minimum SDK: 21 (Android 5.0 Lollipop)
- Target SDK: 34 (Android 14)
- Tested on: Android 5.0 - 14

### Build Configurations

#### Universal APK (Recommended)
- Works on all Android devices
- Larger file size (~30-50 MB)
- Command: `flutter build apk --release`

#### Split APKs (Smaller Size)
- Individual APKs for each architecture
- Smaller file size (~15-20 MB each)
- Command: `flutter build apk --split-per-abi --release`

### Permissions Required
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

### Known Issues
- **Issue**: Secure storage not working on Android < 6.0
  - **Workaround**: App requires Android 5.0+ but secure storage works best on 6.0+
  
- **Issue**: Cleartext HTTP blocked on Android 9+
  - **Solution**: Use HTTPS for backend, or add network security config for development

### Platform-Specific Features
- Material Design 3 components
- Android-style navigation
- Share functionality (coming soon)
- Android Auto support (future)

### Testing on Emulator
```bash
# Create AVD
flutter emulators --create --name test_avd

# Launch emulator
flutter emulators --launch test_avd

# Run app
flutter run -d emulator-5554
```

### Release Signing
For production releases:
1. Create keystore
2. Configure `android/key.properties`
3. Update `android/app/build.gradle`
4. Build signed APK

See BUILD.md for detailed instructions.

---

## iOS

### Supported Versions
- Minimum: iOS 12.0
- Tested on: iOS 12.0 - 17.x
- Compatible with: iPhone, iPad

### Build Configurations

#### Architectures Supported
- arm64 (iPhone 5s and later, all iPads with 64-bit processors)
- Universal binary includes all required architectures

### Permissions Required (Info.plist)
```xml
<!-- Currently no special permissions required -->
<!-- Future additions may include: -->
<!-- <key>NSCameraUsageDescription</key> -->
<!-- <key>NSPhotoLibraryUsageDescription</key> -->
```

### Known Issues
- **Issue**: CocoaPods installation can be slow
  - **Workaround**: Use `pod install --repo-update`
  
- **Issue**: Signing issues in Xcode
  - **Solution**: Ensure you're logged into Apple Developer account in Xcode

### Platform-Specific Features
- iOS-style navigation patterns
- Haptic feedback
- Share sheet integration (coming soon)
- Widgets (future)
- Siri shortcuts (future)

### Testing on Simulator
```bash
# List available simulators
xcrun simctl list devices

# Run on specific simulator
flutter run -d "iPhone 14"
```

### App Store Submission
1. Build in Release mode
2. Archive in Xcode
3. Upload to App Store Connect
4. Submit for review

---

## Windows

### Supported Versions
- Windows 10 version 1809 or higher (64-bit)
- Windows 11 (recommended)

### Build Configuration
- Built with CMake and Visual Studio 2022
- C++ runtime included in build
- Win32 API integration

### Dependencies
- Visual Studio 2022 with:
  - Desktop development with C++
  - Windows 10 SDK (10.0.17763.0 or higher)

### Known Issues
- **Issue**: Build fails with "Visual Studio not found"
  - **Solution**: Install Visual Studio 2022 with C++ tools
  
- **Issue**: Permission denied errors
  - **Solution**: Run as Administrator

### Platform-Specific Features
- Native Windows title bar
- Windows 11 style UI elements
- Taskbar integration
- Jump lists (future)
- Windows notifications (future)

### Distribution
- Standalone executable
- Installer with Inno Setup or NSIS
- Microsoft Store (MSIX package)

### Testing
```bash
flutter run -d windows
```

---

## macOS

### Supported Versions
- macOS 10.14 (Mojave) or higher
- Tested on: macOS 10.14 - 14.x (Sonoma)

### Build Configurations

#### Universal Binary (Default)
- Supports both Intel and Apple Silicon
- Larger file size
- Command: `flutter build macos --release`

#### Architecture-Specific
- Intel only: Smaller for Intel Macs
- Apple Silicon only: Smaller for M1/M2/M3 Macs

### Permissions Required (Info.plist)
```xml
<!-- Currently no special permissions required -->
<!-- Future additions may include: -->
<!-- <key>NSCameraUsageDescription</key> -->
<!-- <key>NSPhotoLibraryUsageDescription</key> -->
```

### Known Issues
- **Issue**: Code signing required for distribution
  - **Solution**: Sign with Apple Developer certificate
  
- **Issue**: Gatekeeper warnings
  - **Solution**: Notarize the app for distribution

### Platform-Specific Features
- Native macOS UI elements
- Touch Bar support (for compatible Macs)
- macOS menu bar
- Spotlight integration (future)
- Quick Look support (future)

### Testing
```bash
flutter run -d macos
```

### Distribution
1. Build release version
2. Sign with Developer ID
3. Notarize with Apple
4. Create DMG or PKG installer

---

## Cross-Platform Considerations

### Networking
- All platforms require internet connectivity
- HTTPS recommended for all platforms
- Certificate validation on iOS/macOS is stricter

### Storage
- Each platform uses its own secure storage:
  - Android: EncryptedSharedPreferences
  - iOS: Keychain
  - Windows: Credential Manager  
  - macOS: Keychain

### UI Differences
- Material Design on Android
- Cupertino/iOS style on iOS
- Platform-adaptive widgets used where appropriate
- Theme respects system preferences

### File Handling
- File picker behavior varies by platform
- Path conventions differ (/, \)
- Permissions requirements vary

---

## Performance Notes

### Android
- First launch may be slower (JIT compilation)
- Subsequent launches are faster
- Memory usage: ~50-100 MB

### iOS
- AOT compilation = fast startup
- Smooth 60 FPS animations
- Memory usage: ~40-80 MB

### Windows
- Startup time: ~1-2 seconds
- Memory usage: ~60-120 MB
- CPU usage minimal when idle

### macOS
- Startup time: ~1-2 seconds
- Memory usage: ~60-100 MB
- Efficient on Apple Silicon

---

## Debugging Platform-Specific Issues

### Android
```bash
# View logs
adb logcat | grep flutter

# Clear app data
adb shell pm clear com.freemail.app
```

### iOS
```bash
# View logs
xcrun simctl spawn booted log stream --predicate 'processImagePath endswith "Runner"'

# Reset simulator
xcrun simctl erase all
```

### Windows
- Check Event Viewer for errors
- Use Visual Studio debugger
- Check Windows Defender logs

### macOS
- Check Console.app for logs
- Use Xcode debugger
- Check system logs with `log show`

---

## Future Platform Enhancements

### Planned
- [ ] Widgets for all platforms
- [ ] Platform-specific shortcuts
- [ ] Native share integration
- [ ] Quick actions
- [ ] Background sync
- [ ] Notifications

### Under Consideration
- [ ] Android Wear support
- [ ] Apple Watch support
- [ ] Linux support
- [ ] Chrome OS optimization

---

## Support Matrix

| Feature | Android | iOS | Windows | macOS |
|---------|---------|-----|---------|-------|
| Basic Email | ✅ | ✅ | ✅ | ✅ |
| Secure Storage | ✅ | ✅ | ✅ | ✅ |
| Dark Theme | ✅ | ✅ | ✅ | ✅ |
| File Picker | ✅ | ✅ | ✅ | ✅ |
| Notifications | 🔄 | 🔄 | 🔄 | 🔄 |
| Widgets | 🔄 | 🔄 | ❌ | 🔄 |
| Share | 🔄 | 🔄 | 🔄 | 🔄 |

✅ = Supported | 🔄 = Coming Soon | ❌ = Not Supported
