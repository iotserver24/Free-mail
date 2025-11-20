# Frontend Integration Guide

Use this guide when wiring up a new UI (React, Vue, etc.). It covers authentication, session handling, CORS, uploading attachments, and rendering data from the backend.

## Auth & Sessions

- The backend uses **cookie-based sessions** (`express-session`). The cookie is `httpOnly` and `sameSite` toggles based on `NODE_ENV`.
- Every request from the browser must send credentials:  
  - Axios: `axios.get(url, { withCredentials: true })`  
  - fetch: `fetch(url, { credentials: "include" })`
- Login flow:
  1. `POST /api/auth/login` with `{ email, password }`.
  2. Store the returned user object in app state. The cookie is automatic.
  3. On reload, call `GET /api/auth/me` to hydrate the session.
  4. To logout, `POST /api/auth/logout` and clear local UI state.

## Base URLs & CORS

- Point the frontend `.env` to the backend origin, e.g. `VITE_API_URL=http://localhost:4000`.
- Backend CORS allowlist is controlled by `FRONTEND_URL` or `CORS_ORIGINS`. If you need multiple dev origins, set `CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:4173`.
- Always hit `/health` to confirm connectivity before showing login UI.

## Working With Data

1. **Domains** – Use `/api/domains` to list or create domains. After provisioning, display DNS instructions (TXT/MX) per your email provider.
2. **Emails** – `/api/emails` returns email IDs. When creating one, you must supply the domain ID the user owns plus an inbox name.
3. **Inboxes** – `/api/inboxes` returns inbox metadata plus the email address. Use this to populate dropdowns or left-hand navigation.
4. **Messages** – `/api/messages?inboxId=<id>` fetches message summaries (subject, preview, status). Use `/api/messages/:id` when the user opens a conversation so you can display full HTML/plain bodies plus attachments.

## Sending Mail

1. Upload files directly to Catbox from the browser by `POST`ing form data to `https://catbox.moe/user/api.php`. The response is a public URL.
2. Build the compose payload:
   ```ts
   await axios.post(
     `${API_URL}/api/messages`,
     {
       from,
       to: ["recipient@example.com"],
       cc: [],
       bcc: [],
       subject,
       text,
       html,
       attachments: uploadedFiles.map(file => ({
         filename: file.name,
         url: file.catboxUrl,
         contentType: file.type,
       })),
     },
     { withCredentials: true }
   );
   ```
3. The backend downloads the remote attachments, relays via Brevo, and stores them for later display.

## Handling Attachments

- To preview or download previously stored attachments, use the `attachments` array returned by `GET /api/messages/:id`. Each entry contains a signed Catbox URL (`attachment.url`). Catbox links are public; hide them behind UI controls if you need additional protection.
- Full binary uploads via `/api/attachments` are possible if you build admin tooling, but the main flow uploads directly from the browser to Catbox.

## Error Handling

- Validation errors return `400` with `{ error: string }`.
- Auth failures use `401 { error: "invalid credentials" }` or `401 { error: "not authenticated" }`.
- Missing resources respond with `404`.
- Unexpected issues hit the global error handler and return `500 { error: "internal server error", message?: string }` (the message only appears in `NODE_ENV=development`).

## Dev Workflow Tips

- Enable `withCredentials` globally in your axios instance:  
  ```ts
  const api = axios.create({
    baseURL: import.meta.env.VITE_API_URL,
    withCredentials: true,
  });
  ```
- When hot-reloading Vite, the backend session remains valid as long as you don’t clear cookies.
- Use the `/` root endpoint response to show a nice status indicator in the UI (it returns `status`, `health`, and route hints).


