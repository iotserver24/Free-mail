# Frequently Asked Questions (FAQ)

Common questions about the Freemail mobile app.

---

## General Questions

### What is Freemail?
Freemail is a self-hosted, AI-powered email management system. This mobile app provides a Gmail-like interface to access your Freemail backend from Android, iOS, Windows, and macOS devices.

### Is the app free?
Yes, the app is free and open source. You only need to host your own Freemail backend.

### Do I need a Freemail backend to use this app?
Yes, this app requires a self-hosted Freemail backend to function. It cannot be used with Gmail, Outlook, or other email services.

### Which platforms are supported?
- Android 5.0+ (all architectures via universal APK)
- iOS 12.0+ (all architectures)
- Windows 10+ (64-bit)
- macOS 10.14+ (Intel and Apple Silicon)

---

## Setup & Configuration

### How do I set up the app for the first time?
1. Install the app on your device
2. Launch the app
3. Enter your Freemail backend URL (e.g., `https://mail.yourdomain.com`)
4. Enter your admin email and password
5. Tap "Sign In"

### What is the backend URL?
The backend URL is the web address where your Freemail backend is hosted. It should start with `http://` or `https://` (HTTPS recommended for security).

### Can I use multiple backends?
Not simultaneously. You'll need to logout and login again with different credentials to switch backends.

### Where are my credentials stored?
Credentials are stored securely on your device using platform-specific secure storage:
- Android: EncryptedSharedPreferences
- iOS: Keychain
- Windows: Credential Manager
- macOS: Keychain

### Are my credentials synced across devices?
No, credentials are stored locally on each device. You'll need to login separately on each device.

---

## Features

### Can I send emails?
Yes, you can compose and send emails using the compose button (+ icon) on the home screen.

### Can I add attachments?
Yes, the compose dialog supports attachments. Click the attachment icon to add files.

### Can I use multiple email addresses?
You can manage multiple email addresses through the domains feature in your backend, but you'll need to select which address to send from when composing.

### Does the app support folders?
Yes, the app supports Inbox, Sent, Drafts, and Trash folders.

### Can I search for emails?
Search functionality is coming in a future update.

### Does the app work offline?
The app requires an internet connection to fetch and send emails. Offline support is planned for future releases.

### Are push notifications supported?
Push notifications are planned for a future update.

---

## Technical Questions

### What technology is the app built with?
The app is built with Flutter, using Dart programming language. This allows it to work across all supported platforms from a single codebase.

### How much storage does the app use?
- Android APK: ~30-50 MB
- iOS: ~40-60 MB
- Windows: ~60-80 MB
- macOS: ~60-80 MB

Actual storage usage may vary based on cached data.

### What are the memory requirements?
The app typically uses 50-100 MB of RAM during normal operation, varying by platform and usage.

### Does the app collect any data?
No, the app does not collect, track, or share any user data. All communication is directly between your device and your backend.

### Is the app open source?
Yes, the source code is available in the Freemail repository.

---

## Troubleshooting

### I can't login. What should I do?
1. Verify your backend URL is correct and accessible
2. Check that your email and password are correct
3. Ensure your backend is running and accessible from your device
4. Check your internet connection
5. Try using HTTPS instead of HTTP

### Emails aren't loading. Why?
1. Check your internet connection
2. Pull down to refresh the inbox
3. Verify your backend is responding to API requests
4. Check backend logs for errors

### I forgot my password. How do I reset it?
The password is configured in your backend's environment variables. You'll need to update the `ADMIN_PASSWORD` in your backend's `.env` file.

### The app crashes on startup. What should I do?
1. Clear the app's data and try logging in again
2. Uninstall and reinstall the app
3. Check if you're using a compatible version of the backend
4. Check device logs for error messages

### Can I use HTTP instead of HTTPS?
While HTTP works for testing, HTTPS is strongly recommended for security. Some platforms (like iOS) may block HTTP connections by default.

### My backend uses a self-signed certificate. Will it work?
Self-signed certificates may cause issues, especially on iOS and macOS. It's recommended to use a proper SSL certificate from a trusted certificate authority.

---

## Privacy & Security

### Is my data encrypted?
Yes, credentials are stored encrypted on your device. Communication with your backend should use HTTPS for encryption in transit.

### Can other apps access my emails?
No, your emails are sandboxed within the Freemail app and cannot be accessed by other apps.

### What happens when I logout?
All local data, including credentials and cached emails, is cleared from your device. Your emails on the backend are not affected.

### How secure is the app?
The app uses industry-standard security practices:
- Encrypted credential storage
- HTTPS communication
- No third-party data sharing
- Regular security updates

---

## Development & Contributing

### Can I contribute to the app?
Yes! Contributions are welcome. See the DEVELOPMENT.md file for guidelines.

### How do I report a bug?
Please open an issue on the GitHub repository with:
- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Platform and version information
- Screenshots if applicable

### How do I request a feature?
Open a feature request issue on GitHub with a detailed description of the feature and its use case.

### Can I fork the app and create my own version?
Yes, the app is open source. You can fork it and modify it according to the license terms.

---

## Platform-Specific Questions

### Android: How do I install the APK?
1. Download the APK file
2. Open it on your Android device
3. Allow installation from unknown sources if prompted
4. Follow the installation wizard

### Android: Which APK should I download?
For most users, download the universal APK. It works on all Android devices but is larger. Split APKs are smaller but device-specific.

### iOS: Can I install without the App Store?
Yes, you can build and install the app using Xcode and a developer account. Enterprise distribution is also possible.

### Windows: Is there an installer?
Currently, you need to copy the release folder. An installer will be provided in future releases.

### macOS: Why does macOS block the app?
macOS Gatekeeper may block unsigned apps. You can:
1. Right-click the app and choose "Open"
2. Or disable Gatekeeper (not recommended)
Future releases will be signed and notarized.

---

## Performance

### Why is the app slow on my device?
Performance depends on:
- Device specifications
- Number of emails loaded
- Network speed
- Backend response time

Try reducing the number of emails loaded per page in settings.

### Does the app drain battery?
The app should have minimal battery impact when not actively in use. Excessive battery drain may indicate:
- Background refresh issues
- Network problems
- Too many emails being synced

---

## Updates

### How do I update the app?
- **App Stores**: Update through the respective app store
- **Manual Installation**: Download and install the new version

### Will updates erase my data?
No, updates preserve your login credentials and settings.

### How often is the app updated?
The app receives updates as new features are added and bugs are fixed. Check the repository for the latest releases.

---

## Backend Compatibility

### Which backend versions are supported?
The app is designed for Freemail Backend v1.0.0 and later.

### What if my backend has a different API?
The app expects specific API endpoints. If your backend has been modified, you may need to update the app's service layer.

### Can I use this with other email backends?
No, this app is specifically designed for Freemail. It won't work with other email systems like Gmail or Outlook.

---

## Miscellaneous

### Is there a web version?
The main Freemail project includes a web frontend (Nuxt app). This mobile app is a companion app for mobile and desktop platforms.

### Can I use the app on a tablet?
Yes, the app works on tablets and will adapt to larger screens.

### Does the app support landscape mode?
Yes, the app supports both portrait and landscape orientations.

### What languages are supported?
Currently, the app is in English. Internationalization support is planned for future releases.

### Can I change the app's theme?
Yes, the app supports light theme, dark theme, and system theme (follows device settings).

---

## Support

### Where can I get help?
- Check this FAQ
- Read the documentation (README.md, CONFIGURATION.md)
- Open an issue on GitHub
- Check the main Freemail repository

### Is there a community forum?
Check the main Freemail repository for community links and discussion forums.

### Can I hire someone to set this up for me?
You may find developers familiar with Flutter and Freemail in the community. Check the repository discussions.

---

## Future Plans

### What features are coming next?
Planned features include:
- Push notifications
- Search functionality
- Offline support
- Email labels/tags
- Advanced filters
- Widgets for mobile platforms
- And more!

Check the repository issues and roadmap for the latest plans.

### Will the app support [feature X]?
Check the repository issues for feature requests. If your desired feature isn't there, feel free to request it!

---

Still have questions? Open an issue on GitHub or check the main Freemail documentation.
