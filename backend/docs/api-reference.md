# API Reference

Base URL defaults to `http://localhost:4000`. All routes under `/api/*` require a logged-in session cookie unless noted. Send `Content-Type: application/json` and include `withCredentials: true` (Axios) or `credentials: "include"` (fetch) so the Express-session cookie persists.

## Auth

| Method | Path | Description | Body |
| --- | --- | --- | --- |
| `POST` | `/api/auth/login` | Authenticate with admin credentials and start a session. | `{ "email": "admin@example.com", "password": "admin123" }` |
| `POST` | `/api/auth/logout` | Destroy the current session. | _None_ |
| `GET` | `/api/auth/me` | Return the current user profile. | _None_ |

## Users

 | Method | Path | Description | Body |
 | --- | --- | --- | --- |
 | `GET` | `/api/users` | List all users (Admin only). | _None_ |
 | `POST` | `/api/users` | Create a new user (Admin only). | `{ "username": "handle", "domain_id": "uuid", "personal_email": "recovery@gmail.com", "fullname": "Name", "details": "Bio", "send_invite": true }` |
 | `PATCH` | `/api/users/:id` | Update user profile (Admin or Self). | `{ "fullname": "New Name", "details": "New Bio", "password": "newpassword" }` |
 | `POST` | `/api/users/invite/:token` | Set password via invite token (Public). | `{ "password": "newpassword" }` |
 | `POST` | `/api/users/forgot-password` | Request password reset email (Public). | `{ "email": "user@domain.com" }` |

## Domains

All routes require authentication.

| Method | Path | Description | Body |
| --- | --- | --- | --- |
| `GET` | `/api/domains` | List all domains owned by the user. | _None_ |
| `POST` | `/api/domains` | Register a new domain. Validates duplicate ownership and format. | `{ "domain": "mail.example.com" }` |
| `GET` | `/api/domains/:domainId` | Fetch metadata for a single domain. | _None_ |
| `DELETE` | `/api/domains/:domainId` | Remove a domain (and any dependent resources you clean up manually). | _None_ |

## Emails

Email addresses bind a domain to an inbox.

| Method | Path | Description | Body |
| --- | --- | --- | --- |
| `GET` | `/api/emails` | List all email identities. | _None_ |
| `POST` | `/api/emails` | Create a new email + inbox pair. Validates that the domain belongs to the user. | `{ "email": "support@mail.example.com", "domain": "mail.example.com", "inboxName": "Support" }` |
| `GET` | `/api/emails/:emailId` | Fetch a single email record. | _None_ |
| `DELETE` | `/api/emails/:emailId` | Delete the email and its associated inbox. | _None_ |

## Inboxes

| Method | Path | Description | Body |
| --- | --- | --- | --- |
| `GET` | `/api/inboxes` | List inboxes. Each response entry includes the resolved email string. | _None_ |
| `POST` | `/api/inboxes` | Create an inbox for an existing email ID. | `{ "emailId": "<email-id>", "name": "Human-readable name" }` |
| `GET` | `/api/inboxes/:inboxId` | Fetch metadata for one inbox. | _None_ |
| `DELETE` | `/api/inboxes/:inboxId` | Permanently remove an inbox. | _None_ |

## Messages

| Method | Path | Description | Body / Query |
| --- | --- | --- |
| `GET` | `/api/messages?inboxId=<optional>&limit=25` | List recent messages. If `inboxId` is omitted, returns newest messages across all inboxes. |
| `GET` | `/api/messages/inbox/:inboxId?limit=25` | Convenience alias to filter by inbox. |
| `GET` | `/api/messages/:id` | Fetch a message plus attachment metadata. |
| `POST` | `/api/messages` | Send an outbound message. Body fields: <ul><li>`from` (string) – must be one of your provisioned emails.</li><li>`to` (string[]), `cc?`, `bcc?`</li><li>`subject` (string)</li><li>`html?` / `text?`</li><li>`threadId?` – optionally force a thread.</li><li>`attachments` – array of `{ filename, url, contentType? }` where `url` is a pre-uploaded Catbox link.</li></ul> |

The server downloads each attachment from Catbox, relays the email via Brevo SMTP, stores the message, and mirrors the attachment metadata in MongoDB.

## Attachments

| Method | Path | Description | Notes |
| --- | --- | --- | --- |
| `POST` | `/api/attachments` | Upload a binary file (`multipart/form-data` with `file` field) and associate it with an existing `messageId`. | Backend uploads the buffer to Catbox and stores metadata. |

Most attachment uploads are performed on the frontend (upload to Catbox first, then include URLs in `/api/messages`). This endpoint exists for administrative tooling.

## Webhooks

| Method | Path | Description | Body |
| --- | --- | --- | --- |
| `POST` | `/api/webhooks/cloudflare` | Accepts JSON from the Cloudflare Worker. Requires `x-webhook-secret` header and a JSON body with `{ "rawEmail": "<base64 RFC822>" }`. | Base64 encoded raw email. |
| `POST` | `/api/webhooks` | Raw MIME endpoint for future providers that can POST `message/rfc822`. | Raw MIME payload (string). |

If no recipient address matches an existing email record, the webhook returns `{ rejected: true }` with HTTP 200 to prevent retries.

## Health & Root

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` | Returns service metadata and links to important routes. |
| `GET` | `/health` | Always returns `200` with `status: "ok"`. Includes `database: "connected"` or `database: "disconnected"` so monitors can detect DB issues. |
