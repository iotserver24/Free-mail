# Free-mail

Self-hosted email studio that lets you own custom domains, inboxes, and outbound campaigns without relying on SaaS vendors. The monorepo contains:

- **Backend** — Express + TypeScript API backed by MongoDB, Brevo SMTP, Catbox for attachments, and Cloudflare Email Routing for inbound delivery.
- **Frontend** — Nuxt 4 (Vue 3) SPA for managing domains, inboxes, sending mail, and reading threads.
- **Cloudflare Worker** — Bridges Email Routing to the backend webhook so inbound messages land in MongoDB.

---

## Table of Contents

1. [Repository Layout](#repository-layout)
2. [Feature Highlights](#feature-highlights)
3. [Architecture Overview](#architecture-overview)
4. [Prerequisites](#prerequisites)
5. [Environment Variables](#environment-variables)
6. [Local Development](#local-development)
7. [Email & Attachment Flow](#email--attachment-flow)
8. [Cloudflare Worker Setup](#cloudflare-worker-setup)
9. [Deployment Notes](#deployment-notes)
10. [Troubleshooting & Tips](#troubleshooting--tips)

---

## Repository Layout

| Path | Purpose |
| --- | --- |
| `backend/` | Express REST API (`src/index.ts`) plus docs in `backend/docs/`. Handles auth, domains, emails, inboxes, messages, attachments, and webhooks. |
| `frontend/` | Nuxt + Vue single-page app (`app/`, `components/`) that consumes the API via composables (`composables/useApi.ts`). |
| `cloudflare-worker/` | Worker script (`email-webhook.js`) that receives Cloudflare Email Routing events and forwards them to `/api/webhooks/cloudflare`. |
| `HOSTING_GUIDE.md` | **Start here for hosting!** Complete step-by-step guide to deploying backend, frontend, and worker. |
| `ATTACHMENTS.md`, `ENV_CONFIG.md`, `MONGODB_SETUP.md`, `SETUP.md`, `DEPLOYMENT.md`, `VERCEL_DEPLOY.md` | Reference docs copied into this README. |

---

## Feature Highlights

- Session-based admin login (`/api/auth/login`) with Express-session cookies.
- Domain, email address, and inbox provisioning flows to keep outbound identities organized.
- Inbox UI with filtering, thread view, quick reply, canned templates, and composer validations.
- Outbound SMTP delivery via Brevo; inbound delivery via Cloudflare Email Routing + Worker.
- Attachment pipeline that uploads files to Catbox (25 MB per file limit) and stores metadata in MongoDB.
- Health endpoint (`/health`) plus detailed API reference in `backend/docs/api-reference.md`.
- Environment-first configuration so every dependency (MongoDB, Brevo, Catbox, Cloudflare) can be swapped per deployment.

## Admin User Management

Free-mail supports a role-based user system:

- **Admin**: Can create new users, manage all domains and inboxes, and view all system data.
- **User**: Can view their own domains and inboxes.

### Creating Users (Admin Only)

Admins can create new users via the API (`POST /api/users`). Required fields include:

- `username`: The user's desired handle.
- `domain_id`: The domain to associate with the user's email (e.g., `username@domain.com`).
- `personal_email`: A recovery email address for password resets.

The system automatically:

1. Creates the user account.
2. Provisions a main inbox.
3. Sends an invite email to the `personal_email` with a link to set the password.

---

## Architecture Overview

1. **Frontend** authenticates against the backend, receives a session cookie, and calls REST endpoints with `withCredentials`.
2. **Backend** exposes routers for auth, domains, emails, inboxes, messages, attachments, and webhooks. MongoDB stores all resources; services integrate with Brevo (SMTP) and Catbox (file storage).
3. **Outbound emails** hit `/api/messages`, which validates ownership, downloads attachment URLs from Catbox, and relays via Brevo.
4. **Inbound emails** are accepted by Cloudflare Email Routing, forwarded to the Worker, base64-encoded, and POSTed to `/api/webhooks/cloudflare`. The backend parses MIME (`mailparser`), uploads attachments to Catbox, and creates message + attachment records.
5. **Frontend polling** fetches `/api/messages`, `/api/messages/:id`, `/api/inboxes`, etc., to render conversation threads.

---

## Prerequisites

- Node.js 18+ and npm (any OS).
- MongoDB (local instance or MongoDB Atlas connection string).
- Brevo SMTP credentials (host, port, username, password, optional default sender).
- Catbox (public API—no account required) or self-hosted compatible service.
- Cloudflare Email Routing enabled on your domain plus Worker deployment via Wrangler CLI.
- (Optional) ngrok for tunneling inbound webhooks during development.

---

## Environment Variables

### Backend (`backend/.env`)

| Name | Required | Description |
| --- | --- | --- |
| `PORT` | No (default `4000`) | HTTP port for Express. |
| `FRONTEND_URL` | No | Single allowed origin for CORS & cookies. |
| `CORS_ORIGINS` | No | Comma-separated origins overriding `FRONTEND_URL`. |
| `MONGODB_URL` | Yes (prod) | Connection string (`mongodb://` or `mongodb+srv://`). |
| `BREVO_SMTP_HOST` | Yes | Usually `smtp-relay.brevo.com`. |
| `BREVO_SMTP_PORT` | Yes | `587` or `465`. |
| `BREVO_SMTP_USER` / `BREVO_SMTP_PASS` | Yes | SMTP credentials. |
| `BREVO_SENDER` | No | Default “From” if UI omits one. |
| `CF_WEBHOOK_SECRET` | Yes | Shared secret with Cloudflare Worker (`X-Webhook-Secret`). |
| `CATBOX_API_URL` | No | Defaults to `https://catbox.moe/user/api.php`. |
| `SESSION_SECRET` | Yes | Random string for session signing. |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | Yes | Credentials for `/api/auth/login`. |

### Frontend (`frontend/.env`)

| Name | Description |
| --- | --- |
| `NUXT_PUBLIC_API_BASE` | Base URL of the backend (e.g., `http://localhost:4000`). Must match cookie domain/origin settings. |
| `NUXT_PUBLIC_CATBOX_USERHASH` | Optional Catbox user hash so the browser can upload attachments directly. Leave blank to use anonymous uploads. |

### Cloudflare Worker (Wrangler secrets)

| Secret | Description |
| --- | --- |
| `BACKEND_URL` | Public URL of the backend (ngrok URL for local dev). |
| `WEBHOOK_SECRET` | Must match `CF_WEBHOOK_SECRET`. |
| `WEBHOOK_PATH` | Optional override for `/api/webhooks/cloudflare`. |

Keep `ENV_CONFIG.md` handy as a checklist while updating secrets.

---

## Local Development

1. **Clone & install**

   ```bash
   git clone <repo>
   cd Free-mail
   cd backend && npm install
   cd ../frontend && npm install
   cd ../cloudflare-worker && npm install
   ```

2. **Configure environment**
   - Copy `backend/.env.example` (or follow `ENV_CONFIG.md`) and fill every variable above.
   - Create `frontend/.env` with `NUXT_PUBLIC_API_BASE=http://localhost:4000`.
   - Use `wrangler secret put BACKEND_URL`, `WEBHOOK_SECRET`, `WEBHOOK_PATH` inside `cloudflare-worker/`.

3. **Start dependencies**
   - Start MongoDB locally or ensure Atlas cluster is reachable.
   - (Optional) run `ngrok http 4000` if testing inbound email locally.

4. **Run services**

   ```bash
   # terminal 1
   cd backend
   npm run dev

   # terminal 2
   cd frontend
   npm run dev # serves Nuxt on http://localhost:3000

   # terminal 3 (only needed for inbound tests)
   cd cloudflare-worker
   wrangler dev --remote
   ```

5. **Login & test**

- Visit `http://localhost:3000`, log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD`.
  - Create domains/emails/inboxes, send yourself a test email, and verify it lands in MongoDB.

---

## Email & Attachment Flow

### Outbound

1. Composer enforces sender/recipient/subject, splits comma-separated lists, and validates attachments up to 25 MB per file.
2. Files upload directly from the browser to Catbox; the backend only receives URLs.
3. `/api/messages` downloads each attachment, rehydrates buffers, and sends via Brevo using Nodemailer before persisting metadata (`attachments` collection).

### Inbound

1. Cloudflare Email Routing forwards raw MIME messages to the Worker.
2. Worker base64-encodes the payload and POSTs JSON `{ rawEmail }` to the backend webhook with `X-Webhook-Secret`.
3. Backend parses with `mailparser`, uploads attachments to Catbox, stores message + attachment documents, and associates them with inboxes.
4. Frontend polls message endpoints and renders attachment links that open the Catbox URL in a new tab.

See `ATTACHMENTS.md` for a visual flow plus security considerations (virus scanning, private storage, etc.).

---

## Cloudflare Worker Setup

1. Install Wrangler globally: `npm install -g wrangler`.
2. `cd cloudflare-worker && wrangler login`.
3. Set secrets:

   ```bash
   wrangler secret put BACKEND_URL   # e.g., https://xxxx.ngrok.io
   wrangler secret put WEBHOOK_SECRET
   wrangler secret put WEBHOOK_PATH  # optional
   ```

4. Deploy: `wrangler deploy`.
5. In Cloudflare Email Routing, add a catch-all route (`*@yourdomain.com`) and choose the deployed Worker as the action.

Whenever the backend URL changes (local ngrok vs production), update `BACKEND_URL` and deploy again.

---

## Deployment Notes

- **Full Guide**: 👉 **[Read HOSTING_GUIDE.md](./HOSTING_GUIDE.md)** for a complete, step-by-step walkthrough of deploying the Backend, Frontend, and Cloudflare Worker.
- Use a container-friendly host (Railway, Render, Fly.io, plain VM). Vercel serverless is **not** recommended because Express sessions are stateful.
- Build commands: `npm install && npm run build` inside `backend/`, start with `npm start`.
- Provision a managed MongoDB cluster (Atlas) and supply `MONGODB_URL`.
- After backend deployment:
  1. Update Cloudflare Worker `BACKEND_URL`.
  2. Point frontend `NUXT_PUBLIC_API_BASE` at the new API.
  3. Redeploy frontend (e.g., Vercel/Netlify or static hosting behind a CDN).
- See `DEPLOYMENT.md` and `VERCEL_DEPLOY.md` for platform-specific comparisons if needed.

---

## Troubleshooting & Tips

- **Mongo connection errors**: confirm server is running, credentials are valid, and Atlas IP allowlist includes your host (`MONGODB_SETUP.md`).
- **CORS/session issues**: ensure `FRONTEND_URL` or `CORS_ORIGINS` exactly matches the frontend origin *and* the frontend requests use `credentials: "include"`.
- **Webhook failures**: check backend logs for `/api/webhooks/cloudflare`, confirm headers include `X-Webhook-Secret`, and verify Worker `BACKEND_URL`.
- **Attachments missing**: make sure Catbox uploads succeed (Composer shows per-file status) and outbound messages wait for uploads to finish.
- **Health checks**: `GET /health` returns `database: "disconnected"` if MongoDB is down—use that in your monitors.
- **Production hardening**: move session storage to Redis, consider virus scanning for attachments, and replace Catbox with a private store if handling sensitive data.

For more detail, browse the docs in `backend/docs/` and the setup guides in the repository root. Happy emailing! ✉️
