# Free-mail Hosting Guide

This guide details how to host the complete Free-mail application, including the backend, frontend, and Cloudflare Worker.

## 📋 Prerequisites

Before starting, ensure you have:

1.  **Domain Name**: Managed via Cloudflare (required for Email Routing).
2.  **Cloudflare Account**: For DNS, Email Routing, and Workers.
3.  **MongoDB**: A hosted instance (e.g., [MongoDB Atlas](https://www.mongodb.com/atlas)) or a self-hosted server.
4.  **Brevo Account**: For sending emails via SMTP.
5.  **Catbox (Optional)**: For attachment storage (default public API used, can be swapped).

---

## 📧 Brevo (SMTP) Setup Guide

Since many users are new to transactional email services, here is a step-by-step guide to setting up Brevo:

1.  **Create an Account**: Go to [Brevo.com](https://www.brevo.com/) and sign up for a free account (300 emails/day).
2.  **Add Your Domain**:
    -   Navigate to **Senders & IP** > **Domains**.
    -   Click **Add a Domain** and enter your domain name (e.g., `yourdomain.com`).
    -   Follow the instructions to add the DNS records (TXT, SPF, DKIM) to your domain provider (Cloudflare).
    -   Click **Verify & Authenticate**. *This is crucial for your emails to not land in spam.*
3.  **Create a Sender**:
    -   Go to **Senders & IP** > **Senders**.
    -   Add an email address you own (e.g., `admin@yourdomain.com`) or use the default one.
4.  **Get SMTP Credentials**:
    -   Click your profile name (top right) > **SMTP & API**.
    -   Click the **SMTP** tab.
    -   **SMTP Server**: `smtp-relay.brevo.com`
    -   **Port**: `587`
    -   **Login**: Your login email address.
    -   **Master Password**: Click **Generate a new SMTP key**. *Copy this immediately; you won't see it again.*
    -   **Use this key** as your `BREVO_SMTP_PASS` in the backend configuration.

---

## 🏗️ Architecture Overview

The system consists of three main components that need to be hosted:

1.  **Backend (Node.js/Express)**: Handles API requests, authentication, and email processing.
2.  **Frontend (React/Vite)**: The user interface for managing inboxes and emails.
3.  **Cloudflare Worker**: Intercepts inbound emails and forwards them to the backend.

---

## 🚀 Deployment Strategy

We recommend the following setup for the best balance of ease and performance:

-   **Backend**: Railway or Render (PaaS) or Docker (Self-hosted).
-   **Frontend**: Vercel, Netlify, or Cloudflare Pages.
-   **Worker**: Cloudflare Workers (Required).
-   **Database**: MongoDB Atlas (Managed).

---

## 🛠️ Step-by-Step Deployment

### Phase 1: Database Setup (MongoDB)

1.  Create a cluster on **MongoDB Atlas** (Free tier works).
2.  Create a database user (username/password).
3.  Get the connection string: `mongodb+srv://<user>:<password>@cluster.mongodb.net/?retryWrites=true&w=majority`.
4.  (Optional) Run the initialization script if self-hosting, but the backend will create collections automatically upon use.

### Phase 2: Backend Deployment

#### Option A: Railway / Render (Recommended)

1.  **Push your code** to a GitHub repository.
2.  **Connect** the repo to Railway or Render.
3.  **Root Directory**: Set to `backend`.
4.  **Build Command**: `npm install && npm run build`.
5.  **Start Command**: `npm start`.
6.  **Environment Variables**: Add the following (see `backend/.env.example`):
    -   `PORT`: `4000` (or `3000` if using Dockerfile default)
    -   `MONGODB_URL`: Your MongoDB connection string.
    -   `BREVO_SMTP_HOST`: `smtp-relay.brevo.com`
    -   `BREVO_SMTP_PORT`: `587`
    -   `BREVO_SMTP_USER`: Your Brevo login email.
    -   `BREVO_SMTP_PASS`: Your Brevo SMTP key (not login password).
    -   `BREVO_SENDER`: Default sender email (e.g., `noreply@yourdomain.com`).
    -   `CF_WEBHOOK_SECRET`: Generate a strong random string (e.g., `openssl rand -hex 32`).
    -   `SESSION_SECRET`: Generate a strong random string.
    -   `FRONTEND_URL`: The URL where your frontend will live (you can update this later).
    -   `ADMIN_EMAIL` / `ADMIN_PASSWORD`: Credentials for the dashboard.

#### Option B: Docker (Self-Hosted / VPS)

1.  **Build the image**:
    ```bash
    cd backend
    docker build -t freemail-backend .
    ```
2.  **Run the container**:
    ```bash
    docker run -d \
      -p 3000:3000 \
      -e MONGODB_URL="your_mongo_url" \
      -e BREVO_SMTP_HOST="smtp-relay.brevo.com" \
      ... (add all env vars) \
      freemail-backend
    ```
    *Note: The Dockerfile exposes port 3000 by default.*

### Phase 3: Cloudflare Worker Deployment

This is crucial for receiving emails.

1.  **Install Wrangler**: `npm install -g wrangler`
2.  **Login**: `wrangler login`
3.  **Navigate**: `cd cloudflare-worker`
4.  **Set Secrets**:
    ```bash
    wrangler secret put BACKEND_URL
    # Enter your deployed backend URL (e.g., https://freemail-api.railway.app)

    wrangler secret put WEBHOOK_SECRET
    # Enter the SAME string as CF_WEBHOOK_SECRET in backend
    ```
5.  **Deploy**: `wrangler deploy`
6.  **Configure Email Routing**:
    -   Go to Cloudflare Dashboard > Email > Email Routing.
    -   Enable Email Routing.
    -   **Routes**: Create a "Catch-all" route.
    -   **Action**: Send to Worker.
    -   **Destination**: Select `email-webhook-worker`.

### Phase 4: Frontend Deployment

1.  **Connect** your repo to Vercel, Netlify, or Cloudflare Pages.
2.  **Root Directory**: Set to `frontend`.
3.  **Build Command**: `npm run build`.
4.  **Output Directory**: `dist`.
5.  **Environment Variables**:
    -   `VITE_API_BASE_URL`: Your deployed backend URL (e.g., `https://freemail-api.railway.app`).
6.  **Deploy**.

### Phase 5: Final Configuration

1.  **Update Backend CORS**:
    -   Go back to your Backend deployment variables.
    -   Update `FRONTEND_URL` to your actual deployed frontend URL (e.g., `https://freemail.vercel.app`).
    -   Redeploy the backend.

---

## ✅ Verification

1.  Open your frontend URL.
2.  Login with `ADMIN_EMAIL` / `ADMIN_PASSWORD`.
3.  Go to **Inboxes** and create a new inbox (e.g., `hello@yourdomain.com`).
4.  Send an email to `hello@yourdomain.com` from your personal Gmail.
5.  Wait a few seconds and refresh the dashboard. You should see the email!

## 🔧 Troubleshooting

-   **CORS Errors**: Check `FRONTEND_URL` in backend and `VITE_API_BASE_URL` in frontend. They must match exactly (no trailing slashes usually).
-   **Emails not arriving**:
    -   Check Cloudflare Email Routing logs for "Dropped" or "Failed".
    -   Check Backend logs for "Webhook received".
    -   Verify `CF_WEBHOOK_SECRET` matches `WEBHOOK_SECRET`.
-   **Database Connection**: Ensure your IP is allowed in MongoDB Atlas Network Access (allow `0.0.0.0/0` for PaaS hosting).
