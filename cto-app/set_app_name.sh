#!/bin/bash
set -e

# This script is run after 'flutter create .' to update the App Name
# Default flutter create uses the project name (cto_app) as the app name.
# We want "Free Mail".

echo "Updating App Name to 'Free Mail'..."

# Function to run sed in a cross-platform way (Linux/GNU and macOS/BSD)
run_sed() {
    local pattern="$1"
    local file="$2"
    
    # Check if we are on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS/BSD sed requires an empty string argument for -i to not use backup
        sed -i '' "$pattern" "$file"
    else
        # Linux/GNU sed does not need an argument for -i (and '' is treated as input file)
        sed -i "$pattern" "$file"
    fi
}

# Android
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo "Updating Android Manifest..."
    run_sed 's/android:label="cto_app"/android:label="Free Mail"/' "android/app/src/main/AndroidManifest.xml"
fi

# iOS
if [ -f "ios/Runner/Info.plist" ]; then
    echo "Updating iOS Info.plist..."
    # Use plistbuddy or sed. simpler with sed for "cto_app"
    run_sed 's/<string>cto_app<\/string>/<string>Free Mail<\/string>/' "ios/Runner/Info.plist"
fi

# macOS
if [ -f "macos/Runner/Configs/AppInfo.xcconfig" ]; then
    echo "Updating macOS AppInfo.xcconfig..."
    run_sed 's/PRODUCT_NAME = cto_app/PRODUCT_NAME = Free Mail/' "macos/Runner/Configs/AppInfo.xcconfig"
fi

# Linux
if [ -f "linux/CMakeLists.txt" ]; then
     echo "Updating Linux CMakeLists..."
     run_sed 's/set(BINARY_NAME "cto_app")/set(BINARY_NAME "free_mail")/' "linux/CMakeLists.txt"
     # This changes the binary name, but maybe not the window title in code.
     # Window title is usually in linux/my_application.cc
fi

if [ -f "linux/my_application.cc" ]; then
    echo "Updating Linux Window Title..."
    run_sed 's/gtk_window_set_title(window, "cto_app");/gtk_window_set_title(window, "Free Mail");/' "linux/my_application.cc"
fi


# Windows
if [ -f "windows/CMakeLists.txt" ]; then
    echo "Updating Windows CMakeLists..."
    run_sed 's/set(BINARY_NAME "cto_app")/set(BINARY_NAME "free_mail")/' "windows/CMakeLists.txt"
fi

if [ -f "windows/runner/main.cpp" ]; then
    echo "Updating Windows Window Title..."
    run_sed 's/window.Create(L"cto_app", origin, size)/window.Create(L"Free Mail", origin, size)/' "windows/runner/main.cpp"
fi

if [ -f "windows/runner/Runner.rc" ]; then
    echo "Updating Windows Runner.rc..."
    run_sed 's/VALUE "FileDescription", "cto_app"/VALUE "FileDescription", "Free Mail"/' "windows/runner/Runner.rc"
    run_sed 's/VALUE "InternalName", "cto_app"/VALUE "InternalName", "Free Mail"/' "windows/runner/Runner.rc"
    run_sed 's/VALUE "OriginalFilename", "cto_app.exe"/VALUE "OriginalFilename", "free_mail.exe"/' "windows/runner/Runner.rc"
    run_sed 's/VALUE "ProductName", "cto_app"/VALUE "ProductName", "Free Mail"/' "windows/runner/Runner.rc"
fi

echo "App Name update complete."
