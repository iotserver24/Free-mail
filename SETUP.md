# FreeMail Setup Guide

## 1. Database Setup

First, you need to create the database tables. Run the initialization script:

```bash
# Using psql command line
psql -h 193.24.208.154 -U postgres -d chat -f db/init.sql

# Or connect and run manually
psql -h 193.24.208.154 -U postgres -d chat
```

Then paste and run the contents of `db/init.sql` in the psql prompt.

## 2. Environment Variables

### Backend (.env)
Update `backend/.env` with your credentials:
- `ADMIN_EMAIL` - Your admin email for login
- `ADMIN_PASSWORD` - Your admin password
- `BREVO_SENDER` - Email address to send from (must be verified in Brevo)
- `CF_WEBHOOK_SECRET` - Secret for Cloudflare webhook (optional but recommended)

### Frontend (.env)
Update `frontend/.env`:
- `NUXT_PUBLIC_API_BASE` - Backend API URL (default: http://localhost:4000)
- `NUXT_PUBLIC_CATBOX_USERHASH` - (Optional) Catbox user hash for authenticated uploads

## 3. Cloudflare Email Routing Setup

**Important**: Cloudflare Email Routing only supports sending to Workers, not direct HTTP endpoints. You must use a Cloudflare Worker as an intermediary.

### Step 1: Deploy the Email Webhook Worker

1. **Install Wrangler CLI**:
   ```bash
   npm install -g wrangler
   ```

2. **Login to Cloudflare**:
   ```bash
   wrangler login
   ```

3. **Navigate to worker directory**:
   ```bash
   cd cloudflare-worker
   ```

4. **Set environment variables**:
   ```bash
   # Your backend URL (use ngrok for local testing)
   wrangler secret put BACKEND_URL
   # Enter: https://your-backend-url.com
   
   # Webhook secret (must match CF_WEBHOOK_SECRET in backend .env)
   wrangler secret put WEBHOOK_SECRET
   # Enter: super-secret
   ```

5. **Deploy the worker**:
   ```bash
   wrangler deploy
   ```

### Step 2: Enable Email Routing in Cloudflare
1. Go to your Cloudflare dashboard
2. Select your domain
3. Navigate to **Email** → **Email Routing**
4. Enable Email Routing if not already enabled

### Step 3: Create a Catch-All Route
1. In Email Routing, go to **Routing** → **Addresses**
2. Create a new route:
   - **Email address**: `*@yourdomain.com` (catch-all)
   - **Action**: **Send to a Worker**
   - **Worker**: Select `email-webhook` (the worker you deployed)

### Step 4: Local Testing with ngrok

For local development, expose your backend using ngrok:

1. **Start your backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start ngrok** (in another terminal):
   ```bash
   ngrok http 4000
   ```

3. **Update worker's BACKEND_URL**:
   ```bash
   cd cloudflare-worker
   wrangler secret put BACKEND_URL
   # Enter your ngrok URL: https://xxxx.ngrok.io
   wrangler deploy
   ```

4. **Test**: Send an email to `test@yourdomain.com` and check your backend logs.

## 4. Testing the Setup

1. **Start Backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Start Frontend**:
   ```bash
   cd frontend
   npm run dev
   ```

- Go to http://localhost:3000
   - Use your `ADMIN_EMAIL` and `ADMIN_PASSWORD` from `.env`

4. **Test Email Reception**:
   - Send an email to `anything@yourdomain.com`
   - It should appear in your inbox after Cloudflare routes it

## 5. Troubleshooting

### Database Connection Issues
- Verify your database credentials in `backend/.env`
- Ensure the database `chat` exists
- Check SSL connection settings

### Email Not Appearing
- Check Cloudflare Email Routing logs
- Verify webhook URL is accessible (use ngrok for local testing)
- Check backend logs for webhook errors
- Verify `CF_WEBHOOK_SECRET` matches in both Cloudflare and backend

### Webhook Format Issues
Cloudflare's email format may vary. Check the actual payload in your backend logs and adjust `backend/src/routes/webhooks.ts` accordingly.

