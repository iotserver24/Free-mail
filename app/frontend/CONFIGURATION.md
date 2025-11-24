# Freemail Mobile App - Configuration Guide

This guide explains how to configure and customize the Freemail mobile app.

## First-Time Setup

### 1. Launch the App

When you first launch the app, you'll see the login screen.

### 2. Enter Backend Configuration

You need to provide three pieces of information:

1. **Backend URL**: The URL of your self-hosted Freemail backend
   - Example: `https://mail.yourdomain.com`
   - Must include `http://` or `https://`
   - Remove any trailing slashes

2. **Admin Email**: Your administrator email address
   - This is the email you configured in your backend's `.env` file as `ADMIN_EMAIL`

3. **Password**: Your administrator password
   - This is the password you configured in your backend's `.env` file as `ADMIN_PASSWORD`

### 3. Sign In

Tap the "Sign In" button. The app will:
- Verify your credentials with the backend
- Save the backend URL for future API calls
- Securely store your credentials on your device
- Navigate to the main email interface

## Security

### Credential Storage

The app uses platform-specific secure storage:

- **Android**: Encrypted SharedPreferences
- **iOS**: Keychain
- **Windows**: Credential Manager
- **macOS**: Keychain

Your credentials are:
- ✅ Encrypted at rest
- ✅ Never transmitted in plain text (HTTPS required)
- ✅ Stored only on your device
- ✅ Cleared when you logout

### Best Practices

1. **Use HTTPS**: Always use `https://` for your backend URL in production
2. **Strong Passwords**: Use a strong, unique password for your admin account
3. **Device Security**: Enable device lock (PIN, biometric, etc.)
4. **Regular Updates**: Keep the app updated for security patches

## Features Configuration

### Email Composition

When composing emails, you can:
- Add multiple recipients (comma-separated)
- Add CC and BCC recipients
- Attach files (support varies by platform)
- Save drafts (coming soon)

### Folders

The app supports standard email folders:
- **Inbox**: Incoming messages
- **Sent**: Sent messages
- **Drafts**: Draft messages (coming soon)
- **Trash**: Deleted messages

### Notifications

Push notifications (coming soon):
- New email alerts
- Customizable notification sounds
- Per-folder notification settings

## Customization

### Theme

The app supports:
- Light theme
- Dark theme
- System theme (follows device settings)

To change the theme (coming soon):
1. Open Settings
2. Tap "Appearance"
3. Select your preferred theme

### Email Display

Default settings:
- Preview length: 100 characters
- Emails per page: 50
- Auto-load images: No (for security)

## Backend Connection

### Supported Backend Versions

This app is compatible with:
- Freemail Backend v1.0.0+

### API Endpoints Used

The app communicates with these backend endpoints:

- `POST /api/auth/login` - Authentication
- `POST /api/auth/logout` - Logout
- `GET /api/messages` - Fetch emails
- `GET /api/messages/:id` - Fetch single email
- `POST /api/messages` - Send email
- `DELETE /api/messages/:id` - Delete email
- `GET /api/domains` - Fetch domains
- `POST /api/domains` - Add domain
- `GET /api/inboxes` - Fetch inboxes

### Connection Issues

If you can't connect to your backend:

1. **Verify Backend URL**
   - Ensure the URL is correct and accessible
   - Check for typos
   - Try accessing the URL in a web browser

2. **Check Network**
   - Ensure your device has internet connectivity
   - Check if your backend is online
   - Verify firewall settings

3. **HTTPS Issues**
   - Ensure your backend has a valid SSL certificate
   - Self-signed certificates may not work without additional configuration

4. **CORS Issues**
   - Ensure your backend allows requests from mobile apps
   - Check `FRONTEND_URL` and `CORS_ORIGINS` settings in backend

## Domain Management

### Adding a Domain

1. Open the drawer menu
2. Tap "Domains"
3. Tap the "Add Domain" button
4. Enter your domain name (e.g., `example.com`)
5. Tap "Add"

### Domain Verification

After adding a domain, you need to:
1. Configure DNS records (see backend documentation)
2. Verify the domain through the backend interface
3. Wait for DNS propagation (can take up to 48 hours)

### Email Addresses

Once your domain is verified, you can:
- Create email addresses
- Assign them to inboxes
- Send emails from these addresses

## Troubleshooting

### Cannot Login

**Problem**: "Invalid credentials or server unreachable"

**Solutions**:
1. Verify your email and password
2. Check backend URL is correct and accessible
3. Ensure backend is running
4. Check backend logs for errors

### Emails Not Loading

**Problem**: Emails don't appear in the inbox

**Solutions**:
1. Pull down to refresh
2. Check your internet connection
3. Verify you have emails in the backend
4. Check backend API is responding

### Cannot Send Email

**Problem**: Email fails to send

**Solutions**:
1. Verify all required fields are filled
2. Check recipient email addresses are valid
3. Ensure backend SMTP is configured correctly
4. Check backend logs for SMTP errors

### App Crashes

**Problem**: App crashes on startup or during use

**Solutions**:
1. Clear app data and login again
2. Update to the latest app version
3. Check device storage space
4. Report the issue with device logs

## Data Management

### Logout

When you logout:
- All local data is cleared
- You'll need to login again to access emails
- Emails on the backend are not affected

### Switching Accounts

To switch to a different backend or account:
1. Logout from current account
2. Login with new credentials

### Data Privacy

The app:
- ✅ Only stores minimal data locally
- ✅ Does not share data with third parties
- ✅ Does not track your usage
- ✅ Communicates only with your backend

## Advanced Configuration

### Development Mode

For developers testing the app:

1. **Local Backend**:
   - Use `http://10.0.2.2:4000` for Android emulator
   - Use `http://localhost:4000` for iOS simulator
   - Use your computer's IP for physical devices

2. **Debug Logging**:
   - Check console output for API calls
   - Use Flutter DevTools for debugging

### Custom Backend URL

If your backend uses a non-standard port or path:
- Include the full URL with port: `https://example.com:8080`
- Include the path if needed: `https://example.com/api`

## Support

For help with:
- **Backend issues**: See backend documentation
- **App issues**: Check the app repository issues
- **Configuration help**: Refer to this guide
- **Feature requests**: Open an issue on GitHub

## Updates

To update the app:
- **Android**: Download new APK or update from store
- **iOS**: Update from App Store or TestFlight
- **Windows**: Download new installer
- **macOS**: Download new DMG

Always backup important data before updating.
