# Deploying the Email Webhook Worker

## Quick Setup Guide

### 1. Install Wrangler
```bash
npm install -g wrangler
```

### 2. Login to Cloudflare
```bash
wrangler login
```
This will open your browser to authenticate with Cloudflare.

### 3. Set Environment Variables (Secrets)

**For Production:**
```bash
# Set your backend URL (use your deployed backend or ngrok for local testing)
wrangler secret put BACKEND_URL
# When prompted, enter: https://your-backend-url.com
# Or for local testing with ngrok: https://xxxx.ngrok.io

# Set webhook secret (must match CF_WEBHOOK_SECRET in backend/.env)
wrangler secret put WEBHOOK_SECRET
# When prompted, enter: super-secret (or your custom secret)

# Optional: Set custom webhook path (defaults to /api/webhooks/cloudflare)
wrangler secret put WEBHOOK_PATH
# When prompted, enter: /api/webhooks/cloudflare
```

**Note:** Secrets are encrypted and stored securely. They apply to the production environment by default.

### 4. Deploy the Worker

```bash
cd cloudflare-worker
wrangler deploy
```

This will deploy to production. The worker name will be `free-mail-route`.

### 5. Configure Email Routing in Cloudflare Dashboard

1. Go to **Cloudflare Dashboard** → Your Domain → **Email** → **Email Routing**
2. Click **Create address** or edit existing route
3. Set:
   - **Email address**: `*@yourdomain.com` (catch-all)
   - **Action**: **Send to a Worker**
   - **Worker**: Select `free-mail-route`

### 6. Test

Send an email to `test@yourdomain.com` and check:
- Cloudflare Worker logs (in Workers dashboard)
- Your backend logs for incoming webhook requests

## Local Development Setup

### Using ngrok for Local Testing

1. **Start your backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start ngrok** (in another terminal):
   ```bash
   ngrok http 4000
   ```
   Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)

3. **Update worker secret**:
   ```bash
   cd cloudflare-worker
   wrangler secret put BACKEND_URL
   # Enter your ngrok URL: https://abc123.ngrok.io
   ```

4. **Redeploy**:
   ```bash
   wrangler deploy
   ```

5. **Test**: Send an email and check your local backend logs.

## Viewing Logs

```bash
# View real-time logs
wrangler tail

# View logs for specific environment
wrangler tail --env development
```

## Updating Secrets

To update a secret:
```bash
wrangler secret put BACKEND_URL
# Enter new value when prompted
```

To delete a secret:
```bash
wrangler secret delete BACKEND_URL
```

## Troubleshooting

- **Worker not receiving emails**: Check Email Routing configuration in Cloudflare dashboard
- **Backend not receiving webhooks**: 
  - Verify BACKEND_URL is correct
  - Check backend is accessible (test with curl)
  - Verify WEBHOOK_SECRET matches backend CF_WEBHOOK_SECRET
- **Check worker logs**: Use `wrangler tail` or Cloudflare dashboard

