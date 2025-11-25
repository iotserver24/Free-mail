# System Overview

The Free-mail backend is an Express + TypeScript application that exposes a session-based REST API for managing custom domains, email addresses, inboxes, and messages. MongoDB persists all state, Brevo (Sendinblue) handles outbound SMTP traffic, Catbox provides temporary storage for attachments, and Cloudflare Email Routing delivers inbound mail via webhook.

## Architecture

| Layer | Responsibility | Key Files |
| --- | --- | --- |
| HTTP server | Express app, session config, middleware bootstrapping, router mounting | `src/index.ts`, `src/middleware/auth.ts` |
| Routers | Route definitions per resource (auth, domains, emails, inboxes, messages, attachments, webhooks) | `src/routes/*` |
| Repositories | Thin data-access layer wrapping MongoDB collections | `src/repositories/*`, `src/db.ts` |
| Services | Integrations (Brevo SMTP, Catbox uploads) | `src/services/mailer.ts`, `src/services/catbox.ts` |
| Cloudflare Worker | Receives raw inbound emails and forwards them to `/api/webhooks/cloudflare` | `cloudflare-worker/` (separate package) |

## Request Flow

1. **Auth** – Users log in via `/api/auth/login`. Credentials are checked, and a session is established.
2. **Domain & email provisioning** – Admins can provision domains and emails for themselves or other users. Regular users can view their assigned resources.
3. **Outbound mail** – `/api/messages` accepts message payloads from the UI. Each request is relayed through Brevo SMTP (`sendBrevoMail`) and persisted to MongoDB (including attachments uploaded to Catbox).
4. **Inbound mail** – Cloudflare Email Routing posts base64-encoded RFC822 messages to `/api/webhooks/cloudflare`. The backend parses, validates, stores content, and pushes attachment metadata (again via Catbox).
5. **Frontend consumption** – The UI polls `/api/messages`, `/api/messages/:id`, `/api/inboxes`, etc., to render the mailbox experience.

## Data Model (Collections)

| Collection | Purpose | Key Fields |
| --- | --- | --- |
| `users` | Admin account plus any future multi-user support | `id`, `email`, `display_name`, `password_hash`, `role`, `personal_email`, `invite_token`, timestamps |
| `domains` | Custom domains owned by the user | `id`, `domain`, `user_id`, `created_at` |
| `email_addresses` | Individual email identities tied to domains | `id`, `email`, `domain`, `user_id`, `inbox_id`, timestamps |
| `inboxes` | Virtual inbox containers scoped to a user | `id`, `email_id`, `user_id`, `name`, timestamps |
| `messages` | Stored inbound/outbound email bodies | `id`, `user_id`, `inbox_id`, `direction`, `subject`, `sender_email`, `recipient_emails`, `thread_id`, `body_plain`, `body_html`, `status`, timestamps |
| `attachments` | Metadata pointing to Catbox-hosted files | `id`, `message_id`, `filename`, `mimetype`, `size_bytes`, `url`, `created_at` |

All repository helpers live under `src/repositories` and enforce ownership checks so a session can only load/manipulate its own data.

## Dependencies & Services

- **MongoDB** – Primary datastore. Connection details set via `MONGODB_URL`.
- **Brevo (Sendinblue)** – SMTP gateway for outbound messages. Credentials set via `BREVO_SMTP_*`.
- **Catbox** – Simple file host used to avoid storing binary blobs in MongoDB.
- **Cloudflare Email Routing** – Accepts inbound mail for your domains and replays payloads to the backend webhook.
- **Session storage** – In-memory Express-session (backed by server memory). For production scale, consider plugging in Redis.

## Operational Notes

- The server expects long-lived connections, so deploy it to a container/VM host. Vercel serverless functions are not supported.
- CORS enforces an allowlist. Configure `FRONTEND_URL` or `CORS_ORIGINS` with comma-separated entries so your teammate’s frontend can issue credentialed requests.
- Health check (`/health`) returns 200 even if MongoDB is temporarily unavailable, but it includes `database: "disconnected"` so uptime monitors can differentiate.
