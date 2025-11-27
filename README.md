# Free-mail

Self-hosted email studio that lets you own custom domains, inboxes, and outbound campaigns without relying on SaaS vendors. The monorepo contains:

- **Backend** — Express + TypeScript API backed by MongoDB, Brevo SMTP, Catbox for attachments, and Cloudflare Email Routing for inbound delivery.
- **Frontend** — Nuxt (Vue 3) SPA for managing domains, inboxes, sending mail, and reading threads.
- **Mobile App** — Flutter app (Android/iOS) for reading emails and receiving push notifications via Firebase (FCM).
- **Cloudflare Worker** — Bridges Email Routing to the backend webhook so inbound messages land in MongoDB.

---

## Table of Contents

1. [Repository Layout](#repository-layout)
2. [Feature Highlights](#feature-highlights)
3. [Architecture Overview](#architecture-overview)
4. [Prerequisites](#prerequisites)
5. [Environment Variables](#environment-variables)
6. [Setup & Installation](#setup--installation)
7. [Email & Attachment Flow](#email--attachment-flow)
8. [Cloudflare Worker Setup](#cloudflare-worker-setup)
9. [Services Configuration](#services-configuration)
10. [Troubleshooting & Tips](#troubleshooting--tips)

---

## Repository Layout

| Path | Purpose |
| --- | --- |
| `backend/` | Express REST API (`src/index.ts`). Handles auth, domains, emails, inboxes, messages, attachments, AI features, and webhooks. |
| `frontend/` | Nuxt + Vue single-page app (`app/`, `components/`) that consumes the API. |
| `app/` | Flutter mobile application for Android and iOS. |
| `cloudflare-worker/` | Worker script (`email-webhook.js`) that receives Cloudflare Email Routing events and forwards them to `/api/webhooks/cloudflare`. |
| `SETUP.md` | **Start here!** Complete step-by-step guide to deploying backend, frontend, app, and worker. |

---

## Feature Highlights

- **Full Email Suite**: Domain, email address, and inbox provisioning.
- **Cross-Platform**: Web interface (Nuxt) and Mobile App (Flutter).
- **Real-time Notifications**: Firebase Cloud Messaging (FCM) for new email alerts on mobile.
- **AI Integration**: OpenAI/Gemini integration for smart features (summarization, drafting).
- **Inbox UI**: Filtering, thread view, quick reply, canned templates, and composer validations.
- **Reliable Delivery**: Outbound SMTP via Brevo; inbound via Cloudflare Email Routing + Worker.
- **Attachments**: Pipeline that uploads files to Catbox (25 MB limit) and stores metadata in MongoDB.
- **Role-Based Access**: Admin (full control) vs User (view only) roles.

---

## Architecture Overview

1. **Frontend/App** authenticates against the backend. Web uses session cookies; App uses token-based auth.
2. **Backend** exposes REST endpoints. MongoDB stores all data.
3. **Outbound emails** are relayed via **Brevo SMTP**.
4. **Inbound emails** are captured by **Cloudflare Email Routing**, processed by the **Worker**, and POSTed to the backend webhook.
5. **Push Notifications** are triggered by the backend via **Firebase Admin SDK** to **FCM**, delivering alerts to the Flutter app.
6. **Attachments** are stored on **Catbox** (public API) or compatible services.

---

## Prerequisites

- **Node.js** (v18+) & **pnpm**
- **Flutter SDK** (for mobile app)
- **MongoDB** (Database)
- **Cloudflare Account** (Email Routing & Workers)
- **Brevo Account** (SMTP)
- **Firebase Project** (FCM)
- **OpenAI/Gemini API Key** (Optional, for AI)

---

## Environment Variables

### Backend (`backend/.env`)

| Name | Required | Description |
| --- | --- | --- |
| `PORT` | No | Default `4000`. |
| `FRONTEND_URL` | Yes | URL of your frontend (CORS). |
| `MONGODB_URL` | Yes | MongoDB connection string. |
| `BREVO_SMTP_HOST` | Yes | `smtp-relay.brevo.com`. |
| `BREVO_SMTP_PORT` | Yes | `587`. |
| `BREVO_SMTP_USER` | Yes | Brevo login email. |
| `BREVO_SMTP_PASS` | Yes | Brevo SMTP key. |
| `CF_WEBHOOK_SECRET` | Yes | Shared secret with Cloudflare Worker. |
| `FIREBASE_PROJECT_ID` | Yes | From Firebase Service Account. |
| `FIREBASE_CLIENT_EMAIL` | Yes | From Firebase Service Account. |
| `FIREBASE_PRIVATE_KEY` | Yes | From Firebase Service Account (handles newlines/quotes). |
| `AI_ENABLED` | No | `true` or `false`. |
| `AI_BASE_URL` | No | e.g., `https://api.openai.com/v1`. |
| `AI_API_KEY` | No | Your AI API key. |
| `AI_MODEL` | No | e.g., `gpt-4o-mini`. |
| `CATBOX_API_URL` | No | Defaults to `https://catbox.moe/user/api.php`. |
| `SESSION_SECRET` | Yes | Random string. |
| `ADMIN_EMAIL` | Yes | Initial admin login. |
| `ADMIN_PASSWORD` | Yes | Initial admin password. |

### Frontend (`frontend/.env`)

| Name | Description |
| --- | --- |
| `NUXT_PUBLIC_API_BASE` | Base URL of the backend (e.g., `http://localhost:4000`). |
| `NUXT_PUBLIC_CATBOX_USERHASH` | Optional Catbox user hash. |

### Cloudflare Worker (`wrangler.toml` / Secrets)

| Secret | Description |
| --- | --- |
| `BACKEND_URL` | Public URL of the backend. |
| `WEBHOOK_SECRET` | Must match `CF_WEBHOOK_SECRET`. |
| `WEBHOOK_PATH` | Optional override (default `/api/webhooks/cloudflare`). |

---

## Setup & Installation

**👉 [Read SETUP.md](./SETUP.md) for the complete, step-by-step guide.**

### Quick Start (Local Dev)

1. **Backend**:

    ```bash
    cd backend
    pnpm install
    cp .env.example .env # Fill in vars
    pnpm dev
    ```

2. **Frontend**:

    ```bash
    cd frontend
    pnpm install
    cp .env.example .env # Fill in vars
    pnpm dev
    ```

3. **Cloudflare Worker**:

    ```bash
    cd cloudflare-worker
    npm install
    # Configure wrangler.toml
    npx wrangler deploy
    ```

4. **Mobile App**:

    ```bash
    cd app
    flutter pub get
    flutter run
    ```

---

## Services Configuration

### Brevo (SMTP)

Get your SMTP credentials from [Brevo Dashboard](https://app.brevo.com/settings/keys/smtp).

### Firebase (FCM)

1. Create a Firebase project.
2. Generate a **Service Account** private key (JSON) for the backend.
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) for the app.

### Cloudflare Email Routing

1. Enable Email Routing in Cloudflare.
2. Create a **Worker** route to send emails to your `free-mail-route` worker.

### AI (OpenAI/Gemini)

Set `AI_BASE_URL` and `AI_API_KEY` in backend `.env` to enable summarization and drafting features.

---

## Troubleshooting & Tips

- **Firebase Key Errors**: Ensure `FIREBASE_PRIVATE_KEY` in `.env` is a single line if your deployment platform requires it, or rely on the backend's built-in formatting logic which handles quotes and `\n`.
- **Notification Failures**: Check if the Firebase Service Account has the correct permissions and that the App has initialized FCM correctly.
- **Webhook Failures**: Verify `CF_WEBHOOK_SECRET` matches between Worker and Backend.
- **MongoDB**: Ensure your IP is whitelisted if using Atlas.

For detailed setup instructions, see [SETUP.md](./SETUP.md).

---

## Support the Project

If you find Free-mail useful, consider supporting the development:

- **Razorpay**: [https://razorpay.me/@megavault](https://razorpay.me/@megavault)
- **Buy Me a Coffee**: [https://buymeacoffee.com/r3ap3redit](https://buymeacoffee.com/r3ap3redit)
