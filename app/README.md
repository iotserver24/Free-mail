# CTO App

This is the Flutter mobile/desktop application for the CTO Email service.

## Setup

1.  Ensure you have Flutter installed.
2.  Run `flutter pub get` to install dependencies.
3.  Since this project was generated without a Flutter environment, you may need to generate platform-specific files:
    ```bash
    flutter create .
    ```
    This will generate the `android`, `ios`, `macos`, `windows`, `linux`, and `web` directories.

## Building

The GitHub Actions workflow `.github/workflows/flutter_build.yml` handles building for Android, iOS (unsigned), macOS, and Windows.

## Features

-   **Login:** Connect to your self-hosted backend.
-   **Inbox:** View and manage emails.
-   **Compose:** Send emails with AI-assisted generation.
-   **AI Features:** Summarize emails, generate content.
-   **Domains:** Manage domains.
