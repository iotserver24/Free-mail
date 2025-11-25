# GitHub Variables Setup - Step by Step

## 🔐 Your Keystore Information

Your Android signing keystore has been created with these details:

- **File**: `upload-keystore.jks`
- **Key Alias**: `upload`
- **Distinguished Name**: CN=anish kumar, OU=R3AP3Reditz, O=R3AP3Reditz, L=karkala, ST=karnataka, C=IN
- **Validity**: 10,000 days (valid until ~2052)

## 📝 Step-by-Step GitHub Variables Setup

### Step 1: Go to Your Repository Settings

1. Open your browser and go to: <https://github.com/YOUR_USERNAME/Free-mail>
2. Click on **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click on the **Variables** tab (not Secrets!)

### Step 2: Add Variable #1 - KEYSTORE_BASE64

1. Click **New repository variable**
2. **Name**: `KEYSTORE_BASE64`
3. **Value**: Copy the entire content from `app/keystore_base64.txt` file
   - Open the file: `c:\Users\Asus\codes-rep\Free-mail\app\keystore_base64.txt`
   - Select ALL text (Ctrl+A)
   - Copy (Ctrl+C)
   - Paste into the Value field
4. Click **Add variable**

### Step 3: Add Variable #2 - KEYSTORE_PASSWORD

1. Click **New repository variable**
2. **Name**: `KEYSTORE_PASSWORD`
3. **Value**: `[THE PASSWORD YOU ENTERED WHEN CREATING THE KEYSTORE]`
   - ⚠️ This is the password you typed when the keytool asked "Enter keystore password"
4. Click **Add variable**

### Step 4: Add Variable #3 - KEY_PASSWORD

1. Click **New repository variable**
2. **Name**: `KEY_PASSWORD`
3. **Value**: `[SAME AS KEYSTORE_PASSWORD]`
   - ⚠️ If you pressed Enter when asked for key password, use the same password as KEYSTORE_PASSWORD
4. Click **Add variable**

### Step 5: Add Variable #4 - KEY_ALIAS

1. Click **New repository variable**
2. **Name**: `KEY_ALIAS`
3. **Value**: `upload`
4. Click **Add variable**

## ✅ Verify Your Variables

After adding all 4 variables, you should see them listed:

| Variable Name | Value Preview |
|---------------|---------------|
| `KEYSTORE_BASE64` | `MIIKxAIBAzCCCm4GCSqGSIb...` (very long) |
| `KEYSTORE_PASSWORD` | `***` (your password) |
| `KEY_PASSWORD` | `***` (your password) |
| `KEY_ALIAS` | `upload` |

## 🚀 Test the Workflow

Once all variables are set:

1. Go to **Actions** tab in your repository
2. Click **Build Free-mail App** workflow
3. Click **Run workflow**
4. Enter:
   - **Version**: `1.0.0` (or any version number)
   - **Release type**: `beta` or `latest`
5. Click **Run workflow**

The workflow will:

- ✅ Build for all platforms (Android, Windows, Linux, iOS, macOS)
- ✅ Sign the Android APK with your keystore
- ✅ Create a GitHub Release
- ✅ Upload all build artifacts

## 📁 Important File Locations

- **Keystore file**: `c:\Users\Asus\codes-rep\Free-mail\app\upload-keystore.jks`
- **Base64 file**: `c:\Users\Asus\codes-rep\Free-mail\app\keystore_base64.txt`

⚠️ **BACKUP THESE FILES** - Store them securely. You'll need them for all future app updates!

## 🔄 If You Need to Update Variables Later

1. Go to Settings → Secrets and variables → Actions → Variables
2. Click on the variable name
3. Click **Update variable**
4. Enter the new value
5. Click **Update variable**
