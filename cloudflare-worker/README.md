# Cloudflare Worker for Email Routing

This worker receives emails from Cloudflare Email Routing and forwards them to your FreeMail backend API.

## Setup Instructions

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 2. Login to Cloudflare

```bash
wrangler login
```

### 3. Configure Environment Variables

Set your backend URL and webhook secret:

```bash
# Set backend URL (your deployed backend or ngrok URL for local testing)
wrangler secret put BACKEND_URL
# Enter: https://your-backend-url.com (or https://your-ngrok-url.ngrok.io)

# Set webhook secret (must match CF_WEBHOOK_SECRET in backend .env)
wrangler secret put WEBHOOK_SECRET
# Enter: super-secret (or your custom secret)

# Optional: Set custom webhook path (defaults to /api/webhooks/cloudflare)
wrangler secret put WEBHOOK_PATH
# Enter: /api/webhooks/cloudflare
```

### 4. Deploy the Worker

```bash
cd cloudflare-worker
wrangler deploy
```

### 5. Configure Email Routing

1. Go to Cloudflare Dashboard → Your Domain → Email → Email Routing
2. Create a catch-all route:
   - **Email address**: `*@yourdomain.com`
   - **Action**: **Send to a Worker**
   - **Worker**: Select `email-webhook` (the worker you just deployed)

### 6. Test

Send an email to `test@yourdomain.com` and check your backend logs to see if it's received.

## Local Development

For local testing with ngrok:

1. Start your backend:
   ```bash
   cd backend
   npm run dev
   ```

2. Start ngrok:
   ```bash
   ngrok http 4000
   ```

3. Update the worker's BACKEND_URL secret:
   ```bash
   wrangler secret put BACKEND_URL
   # Enter your ngrok URL: https://xxxx.ngrok.io
   ```

4. Redeploy:
   ```bash
   wrangler deploy
   ```

## Troubleshooting

- Check Cloudflare Worker logs in the dashboard
- Verify BACKEND_URL is accessible
- Ensure WEBHOOK_SECRET matches in both worker and backend
- Check backend logs for incoming webhook requests

