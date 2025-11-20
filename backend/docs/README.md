# Free-mail Backend Docs

This folder centralizes everything someone new to the backend needs: how the service is wired, which environment variables matter, and the exact API contract your frontend teammate will consume. Start here when setting up the project locally or preparing a deployment target (Render, Railway, bare-metal, etc.).

## Contents

- [`system-overview.md`](system-overview.md) – High-level architecture, dependencies, and request flow.
- [`environment-and-config.md`](environment-and-config.md) – Required environment variables plus local development and deployment notes.
- [`api-reference.md`](api-reference.md) – Route-by-route reference (auth, domains, inboxes, emails, messages, attachments, webhooks, health).
- [`frontend-integration.md`](frontend-integration.md) – Guidance for the frontend team (auth flow, cookies, CORS, message sending, attachments).
- [`webhooks-and-ingestion.md`](webhooks-and-ingestion.md) – How inbound mail is processed through the Cloudflare Worker + webhook pipeline.

## Quick Start

1. Copy `.env.example` to `.env` and review `environment-and-config.md` to supply real secrets (MongoDB URL, Brevo SMTP creds, webhook secret, etc.).
2. Install dependencies and build:
   ```bash
   cd backend
   npm install
   npm run dev    # or npm run build && npm start
   ```
3. Keep the frontend pointing to the backend URL via `VITE_API_URL` (or similar) and send requests with `withCredentials: true` so the session cookie is preserved.

## Hosting Note

Vercel is no longer supported for this service (stateful Express + long-lived Mongo connections caused deployment issues). Use a container-friendly host such as Render, Railway, Fly.io, or a traditional VM. The existing `render.yaml` and `railway.json` files remain valid starting points.


