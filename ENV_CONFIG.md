# Environment Configuration Reference

## Backend Configuration (`backend/.env`)

All backend configuration is in `backend/.env`. Key settings:

### Critical Connection Points:

1. **CF_WEBHOOK_SECRET** = `super-secret`9
   - ⚠️ **MUST match** `WEBHOOK_SECRET` in Cloudflare Worker
   - Used to authenticate webhook requests from Cloudflare

2. **PORT** = `4000`
   - Backend API runs on this port
   - Use this for ngrok: `ngrok http 4000`

3. **ADMIN_EMAIL** & **ADMIN_PASSWORD**
   - Credentials for logging into the dashboard

## Cloudflare Worker Configuration

Workers use **encrypted secrets** (not .env files). Set them with:

```bash
cd cloudflare-worker

# Set backend URL (your deployed backend or ngrok URL)
wrangler secret put BACKEND_URL
# Enter: https://your-backend-url.com
# Or for local: https://xxxx.ngrok.io

# Set webhook secret (MUST match backend CF_WEBHOOK_SECRET)
wrangler secret put WEBHOOK_SECRET
# Enter: super-secret

# Optional: Set webhook path
wrangler secret put WEBHOOK_PATH
# Enter: /api/webhooks/cloudflare
```

## Configuration Mapping

| Backend `.env` | Cloudflare Worker Secret | Purpose |
|----------------|-------------------------|---------|
| `CF_WEBHOOK_SECRET=super-secret` | `WEBHOOK_SECRET=super-secret` | Webhook authentication |
| `PORT=4000` | `BACKEND_URL=https://...` | Backend API location |
| N/A | `WEBHOOK_PATH=/api/webhooks/cloudflare` | API endpoint path |

## Frontend Configuration (`frontend/.env`)

| Env Var | Purpose |
| --- | --- |
| `NUXT_PUBLIC_API_BASE=http://localhost:4000` | Points the Nuxt SPA at the backend origin. Must match CORS settings. |
| `NUXT_PUBLIC_CATBOX_USERHASH=` | Optional Catbox user hash used by the composer when uploading attachments directly from the browser. Leave empty to rely on anonymous uploads. |

## Quick Setup Checklist

### Backend:
- ✅ `backend/.env` is configured
- ✅ `CF_WEBHOOK_SECRET` is set

### Cloudflare Worker:
- ✅ Install wrangler: `npm install -g wrangler`
- ✅ Login: `wrangler login`
- ✅ Set `BACKEND_URL` secret
- ✅ Set `WEBHOOK_SECRET` secret (match backend)
- ✅ Deploy: `wrangler deploy`

### Connection Test:
1. Backend running on port 4000
2. Worker deployed and configured
3. Email Routing pointing to worker
4. Send test email → Check backend logs

## Local Development Setup

1. **Start backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start ngrok**:
   ```bash
   ngrok http 4000
   ```

3. **Update worker BACKEND_URL**:
   ```bash
   cd cloudflare-worker
   wrangler secret put BACKEND_URL
   # Enter ngrok URL: https://xxxx.ngrok.io
   wrangler deploy
   ```

4. **Test**: Send email to `test@yourdomain.com`

