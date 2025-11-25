# Android Signing Setup Guide

This guide explains how to set up Android app signing with GitHub Actions variables.

## Step 1: Generate Your Keystore (One-Time Setup)

Run this command on your local machine to create a new keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be prompted for:**

- Keystore password (remember this!)
- Key password (remember this!)
- Your name, organization, etc.

**Important Notes:**

- ⚠️ **SAVE THIS FILE SAFELY** - You need the same keystore for all future app updates
- ✅ Store it in a password manager or secure backup location
- ❌ Never commit this file to git
- 🔐 The keystore is required for Google Play Store updates

## Step 2: Encode Keystore to Base64

After generating the keystore, encode it to base64:

### On Linux/macOS

```bash
base64 upload-keystore.jks | tr -d '\n' > keystore_base64.txt
```

### On Windows (PowerShell)

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File -FilePath keystore_base64.txt -NoNewline
```

## Step 3: Create GitHub Variables

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click on the **Variables** tab
4. Click **New repository variable**
5. Create these 4 variables:

| Variable Name | Value | Example |
|---------------|-------|---------|
| `KEYSTORE_BASE64` | Content of `keystore_base64.txt` | `MIIKfAIBAzCCDUYGCSqGSIb3DQ...` |
| `KEYSTORE_PASSWORD` | Your keystore password | `mySecurePassword123` |
| `KEY_PASSWORD` | Your key password | `myKeyPassword123` |
| `KEY_ALIAS` | Your key alias | `upload` |

### To add each variable

1. Click **New repository variable**
2. Enter the **Name** (e.g., `KEYSTORE_BASE64`)
3. Paste the **Value**
4. Click **Add variable**
5. Repeat for all 4 variables

**Note:** Variables are stored as plain text (not encrypted) but are only accessible to workflows and repository collaborators.

## Step 4: Verify Setup

After adding all variables, your GitHub Actions workflow will:

- ✅ Decode the keystore from base64
- ✅ Sign your APK with the proper credentials
- ✅ Create releases with signed APKs

## Backup Checklist

Before proceeding, ensure you have backed up:

- [ ] `upload-keystore.jks` file
- [ ] Keystore password
- [ ] Key password
- [ ] Key alias name

**Without these, you cannot update your app on Google Play Store!**

## Troubleshooting

### Build fails with "keystore not found"

- Verify `KEYSTORE_BASE64` variable is set correctly
- Check that base64 encoding was done without line breaks

### Build fails with "wrong password"

- Double-check `KEYSTORE_PASSWORD` and `KEY_PASSWORD` variables
- Ensure no extra spaces were added

### Build fails with "alias not found"

- Verify `KEY_ALIAS` matches the alias used when creating the keystore
- Default is usually `upload` if you followed the command above
