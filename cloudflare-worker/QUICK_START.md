# Quick Start - Cloudflare Worker Setup

## Option 1: Automated Setup (Recommended)

### Windows (PowerShell):
```powershell
cd cloudflare-worker
.\setup-secrets.ps1
```

### Linux/Mac:
```bash
cd cloudflare-worker
chmod +x setup-secrets.sh
./setup-secrets.sh
```

The script will prompt you for:
- Backend URL (your deployed backend or ngrok URL)
- Webhook Secret (defaults to `super-secret` - must match backend)
- Webhook Path (defaults to `/api/webhooks/cloudflare`)

## Option 2: Manual Setup

```bash
cd cloudflare-worker

# Set backend URL
wrangler secret put BACKEND_URL
# Enter: https://your-backend-url.com

# Set webhook secret (MUST match backend CF_WEBHOOK_SECRET)
wrangler secret put WEBHOOK_SECRET
# Enter: super-secret

# Set webhook path (optional)
wrangler secret put WEBHOOK_PATH
# Enter: /api/webhooks/cloudflare
```

## Deploy

After setting secrets:
```bash
wrangler deploy
```

## For Local Testing with ngrok

1. Start backend: `cd backend && npm run dev`
2. Start ngrok: `ngrok http 4000`
3. Run setup script and use ngrok URL when prompted
4. Deploy: `wrangler deploy`

## Verify Configuration

Check that secrets match:

| Worker Secret | Backend .env | Status |
|--------------|--------------|--------|
| `WEBHOOK_SECRET` | `CF_WEBHOOK_SECRET` | Must match ✅ |

