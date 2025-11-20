# Webhooks & Inbound Mail

Inbound email delivery relies on Cloudflare Email Routing (or any provider that can forward raw MIME payloads). This document explains how to wire up the Worker, what the backend expects, and how data is stored.

## Flow Summary

1. A message hits Cloudflare Email Routing for one of your custom domains.
2. The Cloudflare Worker (`cloudflare-worker/email-webhook.js`) receives the event, base64-encodes the raw email, and `fetch`es your backend:  
   `POST https://<backend-domain>/api/webhooks/cloudflare`
3. The backend validates the `x-webhook-secret` header against `CF_WEBHOOK_SECRET`.
4. The body is parsed with `mailparser`, and the system ensures at least one recipient address belongs to a known `email_addresses` record.
5. A `messages` document (direction `inbound`) is created along with attachments (uploaded to Catbox).
6. Frontend clients can now display the new message via `/api/messages`.

## Cloudflare Worker Requirements

- Set `WEBHOOK_SECRET` in the worker environment; it must match `CF_WEBHOOK_SECRET` on the backend.
- The worker must send JSON in the form:
  ```json
  {
    "rawEmail": "<base64 RFC822 string>"
  }
  ```
- Include the header `x-webhook-secret: <secret>`.
- Retries: The backend purposely returns HTTP 200 with `{ rejected: true }` if no recipient matches. This prevents Cloudflare from retrying indefinitely when spam hits unknown addresses.

## Backend Expectations

- `Content-Type` must include `application/json`. The route also handles `Buffer` and string fallbacks but JSON is the safest path.
- Each email must contain at least one `To` recipient. The first matching email record determines `user_id` and `inbox_id`.
- Attachments are streamed to Catbox. Ensure `CATBOX_API_URL` is reachable and not rate limited.
- Errors are logged to stdout/stderr. In production, plug logs into your host (Render/ Railway) for monitoring.

## Testing Locally

1. Start the backend with `npm run dev`.
2. Use the worker repo’s `setup-secrets.*` scripts to configure the webhook secret.
3. Run `wrangler dev --remote` (or use `curl` directly):  
   ```bash
   curl -X POST http://localhost:4000/api/webhooks/cloudflare \
     -H "x-webhook-secret: super-secret" \
     -H "Content-Type: application/json" \
     -d "{\"rawEmail\":\"$(base64 -w0 sample.eml)\"}"
   ```
4. Observe logs for parsing output and confirm the message shows up via `/api/messages`.

## Operational Tips

- Keep the webhook secret rotated regularly. Update both Cloudflare Worker and backend env file simultaneously.
- When onboarding a new domain, provision DNS records (MX, SPF, DKIM) through Cloudflare first so emails actually route to your worker.
- If you need to support another ingress provider (Mailgun, Postmark, etc.), point them to `/api/webhooks` (raw MIME endpoint) or add a new router under `src/routes/webhooks.ts`.


