# Free-mail Project Setup Guide

This guide provides a comprehensive step-by-step walkthrough to set up and host the entire Free-mail ecosystem, including the Backend, Cloudflare Workers, Frontend, and Mobile App.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Cloudflare Worker Setup (Email Routing)](#cloudflare-worker-setup-email-routing)
4. [Frontend Setup](#frontend-setup)
5. [Mobile App Setup](#mobile-app-setup)
6. [Services Configuration](#services-configuration)

---

## Prerequisites

Before you begin, ensure you have the following installed and set up:

- **Node.js** (v18+ recommended) & **pnpm**
- **Flutter SDK** (for the mobile app)
- **MongoDB** (Database)
- **Cloudflare Account** (for Email Routing and Workers)
- **Brevo (formerly Sendinblue) Account** (for SMTP email sending)
- **Firebase Project** (for Push Notifications)
- **Catbox Account** (Optional, for file hosting)
- **OpenAI/Gemini API Key** (for AI features)

---

## Backend Setup

The backend is built with Node.js and TypeScript. It handles API requests, database interactions, and email sending.

### 1. Installation

Navigate to the `backend` directory and install dependencies:

```bash
cd backend
pnpm install
```

### 2. Environment Configuration

Create a `.env` file in the `backend` directory based on `.env.example`.

```bash
cp .env.example .env
```

**Required Variables:**

| Variable | Description | Example |
| :--- | :--- | :--- |
| `PORT` | Server port | `4000` |
| `FRONTEND_URL` | URL of your frontend | `http://localhost:3000` |
| `MONGODB_URL` | MongoDB connection string | `mongodb://user:pass@host:port/db` |
| `SESSION_SECRET` | Random string for session security | `your-secret-key` |
| `ADMIN_EMAIL` | Initial admin email | `admin@example.com` |
| `ADMIN_PASSWORD` | Initial admin password | `securepassword` |

**Service Variables (See [Services Configuration](#services-configuration) for details):**

- **Brevo (SMTP):** `BREVO_SMTP_HOST`, `BREVO_SMTP_PORT`, `BREVO_SMTP_USER`, `BREVO_SMTP_PASS`, `BREVO_SENDER`
- **Cloudflare:** `CF_WEBHOOK_SECRET` (Must match the worker secret)
- **Catbox:** `CATBOX_API_URL`
- **AI:** `AI_ENABLED`, `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL`
- **Firebase:** `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`

### 3. Running the Backend

**Development:**

```bash
pnpm dev
```

**Production:**

```bash
pnpm build
pnpm start
```

**Docker:**

```bash
docker build -t free-mail-backend .
docker run -p 4000:4000 --env-file .env free-mail-backend
```

---

## Cloudflare Worker Setup (Email Routing)

The Cloudflare Worker intercepts incoming emails via Cloudflare Email Routing and forwards them to your backend via a webhook.

### 1. Setup

Navigate to the `cloudflare-worker` directory:

```bash
cd cloudflare-worker
npm install
```

### 2. Configuration (`wrangler.toml`)

Ensure your `wrangler.toml` is configured correctly. You can set variables directly in the file for development or use `wrangler secret` for production.

**Key Variables:**

- `BACKEND_URL`: The public URL of your deployed backend (e.g., `https://api.yourdomain.com`).
- `WEBHOOK_PATH`: The path to the webhook endpoint (default: `/api/webhooks/cloudflare`).
- `WEBHOOK_SECRET`: A shared secret to authenticate requests (must match `CF_WEBHOOK_SECRET` in backend).

### 3. Deployment

Deploy the worker to Cloudflare:

```bash
npx wrangler deploy
```

**Setting Secrets (Recommended for Production):**

```bash
npx wrangler secret put BACKEND_URL
# Enter your backend URL
npx wrangler secret put WEBHOOK_SECRET
# Enter your secret
```

### 4. Email Routing Configuration

1. Go to your **Cloudflare Dashboard** > **Email** > **Email Routing**.
2. Enable Email Routing.
3. Go to **Routes**.
4. Create a custom address (e.g., `*@yourdomain.com` or specific users) and set the **Destination** to **Worker**.
5. Select your deployed `free-mail-route` worker.

---

## Frontend Setup

The frontend is a Nuxt 3 application.

### 1. Installation

Navigate to the `frontend` directory:

```bash
cd frontend
pnpm install
```

### 2. Environment Configuration

Create a `.env` file:

```bash
cp .env.example .env
```

**Variables:**

- `NUXT_PUBLIC_API_BASE`: URL of your backend (e.g., `http://localhost:4000` or `https://api.yourdomain.com`).
- `NUXT_PUBLIC_CATBOX_USERHASH`: (Optional) Your Catbox user hash for file uploads.

### 3. Running the Frontend

**Development:**

```bash
pnpm dev
```

**Production:**

```bash
pnpm build
pnpm start
```

---

## Mobile App Setup

The mobile app is built with Flutter.

### 1. Prerequisites

Ensure you have Flutter installed and configured for your target platforms (Android/iOS).

```bash
flutter doctor
```

### 2. Firebase Configuration

1. Create a project in the Firebase Console.
2. **Android:** Download `google-services.json` and place it in `app/android/app/`.
3. **iOS:** Download `GoogleService-Info.plist` and place it in `app/ios/Runner/`.

### 3. Build and Run

Navigate to the `app` directory:

```bash
cd app
flutter pub get
```

**Run on device/emulator:**

```bash
flutter run
```

**Build APK (Android):**

```bash
flutter build apk --release
```

---

## Services Configuration

### Brevo (SMTP)

1. Create an account at [Brevo](https://www.brevo.com/).
2. Go to **SMTP & API**.
3. Generate a new SMTP Key.
4. Use these credentials in your backend `.env`:
    - `BREVO_SMTP_HOST`: `smtp-relay.brevo.com`
    - `BREVO_SMTP_PORT`: `587`
    - `BREVO_SMTP_USER`: Your login email.
    - `BREVO_SMTP_PASS`: Your generated SMTP key.

### Firebase (FCM & Service Account)

1. Go to **Project Settings** > **Service accounts**.
2. Click **Generate new private key**.
3. Open the downloaded JSON file.
4. Copy the values to your backend `.env`:
    - `FIREBASE_PROJECT_ID`: `project_id` from JSON.
    - `FIREBASE_CLIENT_EMAIL`: `client_email` from JSON.
    - `FIREBASE_PRIVATE_KEY`: `private_key` from JSON.

    **Note on Private Key:** Copy the entire key including `-----BEGIN PRIVATE KEY-----` and `\n`. The backend automatically handles formatting (removing quotes, fixing newlines) so you can paste it directly or as a single line string in deployment dashboards like Railway/Render.

### AI (OpenAI/Gemini)

1. Get your API Key from OpenAI or a compatible provider (like Gemini via OpenAI compat layer).
2. Set `AI_BASE_URL` (e.g., `https://api.openai.com/v1` or your custom endpoint).
3. Set `AI_API_KEY`.
4. Set `AI_MODEL` (e.g., `gpt-4o`, `gemini-1.5-pro`).

### Catbox (File Storage)

- Used for storing email attachments and profile pictures.
- The app uses the public API `https://catbox.moe/user/api.php`.
- No specific setup required for anonymous uploads, but `NUXT_PUBLIC_CATBOX_USERHASH` can be set in frontend for account binding.
