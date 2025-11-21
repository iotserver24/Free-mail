# Environment & Configuration

Use this document when provisioning secrets, running locally, or deploying to a container host. The backend relies on environment variables loaded via `dotenv` (`src/config.ts`).

## Variables

| Name | Required | Notes |
| --- | --- | --- |
| `PORT` | No (default `4000`) | HTTP port for Express when self-hosting. |
| `FRONTEND_URL` | No (default `http://localhost:3000`) | Single origin used for CORS + session cookie domain. |
| `CORS_ORIGINS` | No | Optional comma-separated list of allowed origins (overrides `FRONTEND_URL`). |
| `MONGODB_URL` | **Yes in production** | MongoDB connection string (`mongodb+srv://...`). The dev fallback is `mongodb://localhost:27017/freemail`. |
| `BREVO_SMTP_HOST` | Yes | Usually `smtp-relay.brevo.com`. |
| `BREVO_SMTP_PORT` | Yes | `587` (STARTTLS) or `465` (SSL). |
| `BREVO_SMTP_USER` | Yes | Brevo SMTP login. |
| `BREVO_SMTP_PASS` | Yes | Brevo SMTP password. |
| `BREVO_SENDER` | No | Default From address if the UI doesn’t provide one. |
| `CF_WEBHOOK_SECRET` | Yes | Shared secret between Cloudflare Worker and `/api/webhooks/cloudflare`. |
| `CATBOX_API_URL` | No (default `https://catbox.moe/user/api.php`) | Override if you self-host an alternative. |
| `SESSION_SECRET` | **Yes** | Random string for Express-session signing. |
| `ADMIN_EMAIL` | Yes | Credential used by `/api/auth/login`. |
| `ADMIN_PASSWORD` | Yes | Credential used by `/api/auth/login`. |

## Local Development

1. Copy `.env.example` to `.env` and update the values above.
2. Run `npm install` once.
3. Start a MongoDB instance (local Docker `mongo` container or Atlas cluster).
4. Start the server with `npm run dev`. Express hot-reloads with `ts-node-dev`.
5. Hit `http://localhost:4000/health` to verify the process and DB connection.

## Deployment Checklist

1. **Container host** – Use Render, Railway, Fly.io, or any VM/container orchestrator. Vercel serverless functions are not supported due to the long-lived Mongo connection plus session storage requirements.
2. **Build step** – Run `npm install && npm run build`. Start command: `npm start`.
3. **Environment** – Provide every variable from the table. Double-check `FRONTEND_URL`/`CORS_ORIGINS` so cookies are accepted.
4. **Persistent DB** – Point `MONGODB_URL` to a managed MongoDB cluster (Atlas, Compose, ScaleGrid, etc.).
5. **Webhook URL** – Update the Cloudflare Worker to send requests to your public backend domain (HTTPS) and keep `x-webhook-secret` synced.
6. **Attachments** – Catbox is public. If you need privacy, swap `CATBOX_API_URL` with a self-hosted file service and update `services/catbox.ts`.

## Useful Scripts

| Script | Command | Purpose |
| --- | --- | --- |
| `npm run dev` | `ts-node-dev --respawn --transpile-only src/index.ts` | Local development with auto-reload. |
| `npm run build` | `tsc -p tsconfig.json` | Compile TypeScript into `dist/`. |
| `npm start` | `node dist/index.js` | Run compiled server (use in production). |


