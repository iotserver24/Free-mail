# Cloudflare Worker Environment Setup

## Important Note

Cloudflare Workers **do not use .env files**. They use encrypted secrets managed by Wrangler CLI.

## Required Environment Variables

The worker needs these three secrets:

1. **BACKEND_URL** - Your backend API URL
2. **WEBHOOK_SECRET** - Secret key (must match backend `CF_WEBHOOK_SECRET`)
3. **WEBHOOK_PATH** - API endpoint path (optional, defaults to `/api/webhooks/cloudflare`)

## Setup Steps

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
```

### 2. Login to Cloudflare

```bash
wrangler login
```

### 3. Set Secrets

```bash
cd cloudflare-worker

# Set backend URL (use your deployed URL or ngrok for local testing)
wrangler secret put BACKEND_URL
# When prompted, enter: https://your-backend-url.com
# Or for local: https://xxxx.ngrok.io

# Set webhook secret (MUST match backend/.env CF_WEBHOOK_SECRET)
wrangler secret put WEBHOOK_SECRET
# When prompted, enter: super-secret

# Optional: Set webhook path
wrangler secret put WEBHOOK_PATH
# When prompted, enter: /api/webhooks/cloudflare
```

### 4. Deploy Worker

```bash
wrangler deploy
```

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

## Verify Configuration

Check that secrets match between worker and backend:

| Worker Secret | Backend .env Variable | Must Match |
|--------------|----------------------|------------|
| `WEBHOOK_SECRET` | `CF_WEBHOOK_SECRET` | ✅ Yes |
| `BACKEND_URL` | N/A | Your backend URL |
| `WEBHOOK_PATH` | N/A | `/api/webhooks/cloudflare` |

## Viewing/Updating Secrets

```bash
# View all secrets (names only, not values)
wrangler secret list

# Update a secret
wrangler secret put BACKEND_URL

# Delete a secret
wrangler secret delete BACKEND_URL
```

## Troubleshooting

- **Worker can't reach backend**: Verify BACKEND_URL is correct and accessible
- **403 Forbidden errors**: Check WEBHOOK_SECRET matches backend CF_WEBHOOK_SECRET
- **404 Not Found**: Verify WEBHOOK_PATH is correct (`/api/webhooks/cloudflare`)

