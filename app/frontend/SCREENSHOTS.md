# Screenshots Guide

This document describes the screens and features that should be captured for app documentation and store listings.

## Required Screenshots

### 1. Login Screen
**File**: `login_screen.png`

**Description**: 
- Shows the initial login interface
- Backend URL input field
- Email input field
- Password input field (obscured)
- Sign In button
- App logo and branding

**Key Features to Highlight**:
- Clean, modern design
- Self-hosted backend support
- Secure credential input

**Recommended Size**:
- Android: 1080x1920 (9:16)
- iOS: 1242x2688 (iPhone 14 Pro Max)
- Desktop: 1920x1080 or app window size

---

### 2. Email Inbox (Home Screen)
**File**: `inbox_screen.png`

**Description**:
- Main email list view
- Multiple emails displayed
- Drawer menu visible (optional)
- FAB for compose visible

**Key Features to Highlight**:
- Gmail-like interface
- Email previews with sender, subject, and timestamp
- Unread indicators
- Star/favorite functionality
- Clean, organized layout

**States to Capture**:
- With emails (normal state)
- Empty state (no emails)
- Loading state (optional)

---

### 3. Navigation Drawer
**File**: `drawer_menu.png`

**Description**:
- Opened drawer menu
- App branding at top
- Folder list (Inbox, Sent, Drafts, Trash)
- Labels option
- Domains option
- Logout option

**Key Features to Highlight**:
- Easy navigation
- Organized folder structure
- Clear menu options

---

### 4. Email Detail Screen
**File**: `email_detail.png`

**Description**:
- Single email view
- Full email content
- Sender information with avatar
- Email metadata (date, time, recipients)
- Action buttons (reply, reply all, forward, star, delete)

**Key Features to Highlight**:
- Rich email display
- HTML content rendering
- Attachment preview (if applicable)
- Clear action buttons

**Variations**:
- Email with plain text
- Email with HTML content
- Email with attachments

---

### 5. Compose Email Dialog
**File**: `compose_email.png`

**Description**:
- Email composition interface
- To, CC, BCC fields
- Subject field
- Message body
- Send and Cancel buttons

**Key Features to Highlight**:
- Clean composition interface
- CC/BCC support
- Simple, intuitive design

---

### 6. Domains Screen
**File**: `domains_screen.png`

**Description**:
- List of configured domains
- Add domain button
- Domain cards with actions

**Key Features to Highlight**:
- Domain management
- Easy domain addition
- Action menu for each domain

**States to Capture**:
- With domains
- Empty state (no domains)

---

### 7. Settings Screen
**File**: `settings_screen.png`

**Description**:
- Settings interface
- Account information
- Preferences section
- About section
- Logout button

**Key Features to Highlight**:
- Backend URL display
- Email address display
- Theme options
- Clear organization

---

### 8. Dark Theme Example
**File**: `dark_theme.png`

**Description**:
- Any screen (preferably inbox) in dark mode
- Shows theme support

**Key Features to Highlight**:
- Full dark theme support
- Proper contrast
- Eye-friendly design

---

## App Store Specific Screenshots

### Google Play Store (Android)

**Required Sizes**:
1. Phone: 1080x1920 or higher (16:9)
2. 7-inch Tablet: 1920x1200 or higher
3. 10-inch Tablet: 2560x1600 or higher

**Required Screenshots**: Minimum 2, maximum 8

**Recommended Set**:
1. Login Screen
2. Email Inbox
3. Email Detail
4. Compose Email
5. Domains Screen
6. Dark Theme Example

### Apple App Store (iOS)

**Required Sizes** (for iPhone):
1. 6.5" Display: 1242x2688 or 1284x2778
2. 5.5" Display: 1242x2208

**Required Screenshots**: Minimum 1 per device type

**Recommended Set**:
1. Login Screen
2. Email Inbox
3. Email Detail with Actions
4. Compose Email
5. Settings Screen

### Microsoft Store (Windows)

**Required Sizes**:
- 1920x1080 or higher
- Recommended: 2560x1440

**Recommended Set**:
1. Main Window with Inbox
2. Email Detail
3. Compose Email
4. Settings

### Mac App Store (macOS)

**Required Sizes**:
- 1280x800 or higher
- Recommended: 2880x1800 (Retina)

**Recommended Set**:
1. Main Window
2. Email Management
3. Domain Management

---

## Creating Screenshots

### Using Flutter DevTools

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Take screenshots**:
   - Use Flutter DevTools screenshot feature
   - Or use platform-specific tools

### Platform-Specific Tools

#### Android
```bash
# Using ADB
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Or use Android Studio Device File Explorer
```

#### iOS
- iOS Simulator: Cmd+S
- Physical Device: Screenshot with device buttons

#### Windows
- Snipping Tool
- Win + Shift + S

#### macOS
- Cmd + Shift + 4 (selection)
- Cmd + Shift + 3 (full screen)

### Best Practices

1. **Clean Data**:
   - Use realistic but non-sensitive data
   - Show multiple emails for inbox views
   - Use professional email addresses

2. **Consistent Branding**:
   - Same color scheme across all screenshots
   - Same theme (light or dark) unless showing theme support

3. **Device Frames** (Optional):
   - Use tools like Figma or Sketch to add device frames
   - Makes screenshots more appealing

4. **Annotations** (For Marketing):
   - Add text overlays highlighting features
   - Use arrows to point out key features
   - Keep it minimal and professional

---

## Screenshot Checklist

Before publishing, ensure you have:

- [ ] Login screen showing clean UI
- [ ] Inbox with multiple emails
- [ ] Email detail with actions visible
- [ ] Compose dialog showing fields
- [ ] Domain management screen
- [ ] Settings screen
- [ ] Dark theme example
- [ ] All screenshots are high quality (no pixelation)
- [ ] No sensitive/personal information visible
- [ ] Consistent UI state across screenshots
- [ ] Correct aspect ratios for target platform
- [ ] Screenshots showcase key features

---

## Video Demo (Optional)

### Suggested Walkthrough (30-60 seconds)

1. **Login** (5 sec)
   - Show backend URL entry
   - Enter credentials
   - Login animation

2. **Inbox** (10 sec)
   - Show email list
   - Open drawer menu
   - Navigate folders

3. **Email Detail** (10 sec)
   - Open an email
   - Show content rendering
   - Demonstrate actions

4. **Compose** (10 sec)
   - Tap compose button
   - Fill in email fields
   - Show send action

5. **Domain Management** (10 sec)
   - Navigate to domains
   - Show add domain
   - Display domain list

6. **Settings** (5 sec)
   - Quick tour of settings
   - Show theme toggle

### Recording Tools

- **Android**: `adb shell screenrecord`
- **iOS**: QuickTime Player (for simulator)
- **Windows**: OBS Studio, Xbox Game Bar
- **macOS**: QuickTime Player, OBS Studio

---

## Notes

- Always use the latest app version for screenshots
- Update screenshots when UI changes significantly
- Keep source files (PSD, Sketch, Figma) for easy updates
- Consider localization (screenshots in multiple languages)
- Test on different screen sizes to ensure readability
