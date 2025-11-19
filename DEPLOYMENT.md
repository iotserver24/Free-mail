# Backend Deployment Guide

## 🚀 Quick Recommendation

**For Express backends, I recommend Railway or Render** - they're easier and better suited for traditional Node.js apps.

Vercel works but requires serverless adaptation. See options below:

---

## Option 1: Railway (Easiest) ⭐ RECOMMENDED

**Why Railway?**
- ✅ Free tier available
- ✅ Automatic GitHub deployments
- ✅ Built-in PostgreSQL support
- ✅ Zero configuration needed
- ✅ Perfect for Express apps

**Steps:**

1. **Sign up**: [railway.app](https://railway.app) → Sign up with GitHub

2. **Deploy**:
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your `Free-mail` repository
   - Set **Root Directory** to `backend`

3. **Add Environment Variables**:
   - Go to Variables tab
   - Add all from `backend/.env`:
     ```
     PORT=4000
     DATABASE_URL=postgres://postgres:18751%40Anish@193.24.208.154:5432/chat?sslmode=allow
     BREVO_SMTP_HOST=smtp-relay.brevo.com
     BREVO_SMTP_PORT=587
     BREVO_SMTP_USER=907288001@smtp-brevo.com
     BREVO_SMTP_PASS=bskr3gdXsy7bv1I
     BREVO_SENDER=no-reply@yourdomain.com
     CF_WEBHOOK_SECRET=super-secret-my-ass-nice
     CATBOX_API_URL=https://catbox.moe/user/api.php
     SESSION_SECRET=change-me-in-production-use-random-string
     FRONTEND_URL=https://your-frontend-url.com
     ADMIN_EMAIL=admin@example.com
     ADMIN_PASSWORD=admin123
     ```

4. **Deploy**:
   - Railway auto-detects Node.js
   - Runs: `npm install` → `npm run build` → `npm start`
   - Done! 🎉

5. **Get URL**: `https://your-app.up.railway.app`

---

## Option 2: Render ⭐ ALSO GREAT

**Why Render?**
- ✅ Free tier
- ✅ Easy setup
- ✅ GitHub integration

**Steps:**

1. **Sign up**: [render.com](https://render.com)

2. **Create Web Service**:
   - New + → Web Service
   - Connect GitHub repo
   - Settings:
     - **Name**: `freemail-backend`
     - **Root Directory**: `backend`
     - **Environment**: `Node`
     - **Build Command**: `npm install && npm run build`
     - **Start Command**: `npm start`

3. **Add Environment Variables**:
   - Environment tab → Add all from `backend/.env`

4. **Deploy**: Click "Create Web Service"

5. **Get URL**: `https://freemail-backend.onrender.com`

---

## Option 3: Vercel (Serverless)

**Note**: Vercel converts Express to serverless functions. Sessions may need Redis.

**Steps:**

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Deploy**:
   ```bash
   cd backend
   vercel
   ```

3. **Add Environment Variables**:
   - Vercel Dashboard → Project → Settings → Environment Variables
   - Add all from `backend/.env`

4. **Production Deploy**:
   ```bash
   vercel --prod
   ```

5. **Get URL**: `https://your-app.vercel.app`

**Important for Vercel**:
- Sessions: Consider using Vercel KV (Redis) for production
- File uploads: May need adjustment for serverless
- Cold starts: First request may be slower

---

## Option 4: Fly.io

**Steps:**

1. **Install Fly CLI**:
   ```powershell
   iwr https://fly.io/install.ps1 -useb | iex
   ```

2. **Login & Deploy**:
   ```bash
   cd backend
   fly auth login
   fly launch
   fly secrets set DATABASE_URL="postgres://..."
   # ... set all secrets
   fly deploy
   ```

---

## After Deployment

### 1. Update Cloudflare Worker

```bash
cd cloudflare-worker
wrangler secret put BACKEND_URL
# Enter your deployed backend URL (e.g., https://your-app.up.railway.app)
wrangler deploy
```

### 2. Update Frontend

Update `frontend/.env`:
```
VITE_API_BASE_URL=https://your-backend-url.com
```

### 3. Test

- Send email to `test@yourdomain.com`
- Check backend logs
- Verify email appears in dashboard

---

## Quick Comparison

| Platform | Free Tier | Setup Time | Best For |
|----------|-----------|------------|----------|
| **Railway** | ✅ Yes | 5 min | Express apps ⭐ |
| **Render** | ✅ Yes | 5 min | Express apps ⭐ |
| **Vercel** | ✅ Yes | 10 min | Serverless |
| **Fly.io** | ✅ Yes | 15 min | Docker apps |

**My Recommendation**: Start with **Railway** - it's the easiest! 🚀
