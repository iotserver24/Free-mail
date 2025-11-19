# Deploying Backend to Vercel

## Quick Deploy Guide

### Prerequisites

1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **Vercel CLI** (optional, for CLI deployment):
   ```bash
   npm install -g vercel
   ```

---

## Option 1: Deploy via Vercel Dashboard (Recommended) ⭐

### Step 1: Prepare Your Repository

1. **Push your code to GitHub** (if not already):
   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push
   ```

### Step 2: Import Project in Vercel

1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Click **"Add New..."** → **"Project"**
3. **Import your GitHub repository**
4. Select the `Free-mail` repository

### Step 3: Configure Project

**Root Directory:**
- Set to: `backend`

**Build Settings:**
- **Framework Preset**: Other
- **Build Command**: `npm run build`
- **Output Directory**: `dist`
- **Install Command**: `npm install`

**OR** leave as auto-detected (Vercel should detect it)

### Step 4: Add Environment Variables

Click **"Environment Variables"** and add all these:

```
# Server
PORT=4000
FRONTEND_URL=https://your-frontend-url.vercel.app

# MongoDB
MONGODB_URL=mongodb://root:18751Anish@193.24.208.154:4532/freemail?directConnection=true

# Brevo SMTP
BREVO_SMTP_HOST=smtp-relay.brevo.com
BREVO_SMTP_PORT=587
BREVO_SMTP_USER=907288001@smtp-brevo.com
BREVO_SMTP_PASS=bskr3gdXsy7bv1I

# Cloudflare Webhook
CF_WEBHOOK_SECRET=super-secret-my-ass-nice

# Catbox
CATBOX_API_URL=https://catbox.moe/user/api.php

# Session
SESSION_SECRET=your-random-secret-here-change-this

# Admin
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
```

**Important:**
- Set `SESSION_SECRET` to a random string (use: `openssl rand -base64 32`)
- Update `FRONTEND_URL` to your actual frontend URL after deploying

### Step 5: Deploy

1. Click **"Deploy"**
2. Wait for build to complete
3. Get your backend URL: `https://your-project.vercel.app`

---

## Option 2: Deploy via CLI

### Step 1: Install Vercel CLI

```bash
npm install -g vercel
```

### Step 2: Login

```bash
vercel login
```

### Step 3: Navigate to Backend

```bash
cd backend
```

### Step 4: Deploy

```bash
# First deployment (follow prompts)
vercel

# Production deployment
vercel --prod
```

### Step 5: Set Environment Variables

```bash
# Set each variable
vercel env add MONGODB_URL
# Paste: mongodb://root:18751Anish@193.24.208.154:4532/freemail?directConnection=true

vercel env add BREVO_SMTP_USER
# Paste: 907288001@smtp-brevo.com

vercel env add BREVO_SMTP_PASS
# Paste: bskr3gdXsy7bv1I

# ... repeat for all variables
```

**Or set all at once:**
```bash
vercel env add MONGODB_URL production
vercel env add BREVO_SMTP_HOST production
vercel env add BREVO_SMTP_PORT production
vercel env add BREVO_SMTP_USER production
vercel env add BREVO_SMTP_PASS production
vercel env add CF_WEBHOOK_SECRET production
vercel env add CATBOX_API_URL production
vercel env add SESSION_SECRET production
vercel env add ADMIN_EMAIL production
vercel env add ADMIN_PASSWORD production
vercel env add FRONTEND_URL production
```

---

## Important Notes for Vercel

### 1. Serverless Functions

- Your Express app runs as serverless functions
- Each request is a separate invocation
- MongoDB connection is reused across invocations (optimized)

### 2. Session Storage

**Current Setup**: Uses in-memory sessions (not persistent)

**For Production**: Consider using Vercel KV (Redis):
```bash
# Install Vercel KV
npm install @vercel/kv

# Update session store to use Redis
```

### 3. Function Timeout

- Default: 10 seconds
- Updated in `vercel.json` to 30 seconds
- For longer operations, use background jobs

### 4. Cold Starts

- First request may be slower (cold start)
- Subsequent requests are fast (warm)
- MongoDB connection is cached

---

## After Deployment

### 1. Update Cloudflare Worker

Update your Cloudflare Worker `BACKEND_URL`:

```bash
cd cloudflare-worker
wrangler secret put BACKEND_URL
# Enter: https://your-project.vercel.app
wrangler deploy
```

### 2. Update Frontend

Update `frontend/.env`:
```
VITE_API_BASE_URL=https://your-project.vercel.app
```

### 3. Test

1. Visit: `https://your-project.vercel.app/health`
2. Should return: `{"status":"ok","database":"connected"}`

---

## Troubleshooting

### "MongoServerSelectionError"
- Check MongoDB connection string
- Verify VPS firewall allows Vercel IPs
- Check MongoDB is accessible from internet

### "Function timeout"
- Increase timeout in `vercel.json`
- Optimize database queries
- Use background jobs for long operations

### "Session not persisting"
- Sessions are in-memory (lost on cold start)
- Use Vercel KV for persistent sessions

### Build Errors
- Check `tsconfig.json` is correct
- Verify all dependencies in `package.json`
- Check build logs in Vercel dashboard

---

## Environment Variables Checklist

Make sure all these are set in Vercel:

- [x] `MONGODB_URL`
- [x] `BREVO_SMTP_HOST`
- [x] `BREVO_SMTP_PORT`
- [x] `BREVO_SMTP_USER`
- [x] `BREVO_SMTP_PASS`
- [x] `CF_WEBHOOK_SECRET`
- [x] `CATBOX_API_URL`
- [x] `SESSION_SECRET` (random string)
- [x] `ADMIN_EMAIL`
- [x] `ADMIN_PASSWORD`
- [x] `FRONTEND_URL` (after frontend is deployed)

---

## Quick Deploy Script

Save this as `deploy.sh`:

```bash
#!/bin/bash
cd backend
vercel --prod
```

Or for Windows PowerShell (`deploy.ps1`):

```powershell
cd backend
vercel --prod
```

---

## Next Steps

1. ✅ Deploy backend to Vercel
2. ✅ Update Cloudflare Worker with new backend URL
3. ✅ Deploy frontend (Vercel or other)
4. ✅ Update `FRONTEND_URL` in backend env vars
5. ✅ Test the full flow!

---

**Need help?** Check Vercel logs in dashboard → Your Project → Deployments → View Function Logs

