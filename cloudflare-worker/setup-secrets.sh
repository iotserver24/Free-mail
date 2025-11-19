#!/bin/bash
# Bash script to set up Cloudflare Worker secrets
# Run this script to configure all required secrets

echo "========================================"
echo "Cloudflare Worker Secrets Setup"
echo "========================================"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "ERROR: Wrangler CLI is not installed!"
    echo "Install it with: npm install -g wrangler"
    exit 1
fi

echo "Please enter the following values:"
echo ""

# Get backend URL
read -p "Backend URL (e.g., https://your-backend.com or https://xxxx.ngrok.io for local): " backendUrl
if [ -z "$backendUrl" ]; then
    echo "ERROR: Backend URL is required!"
    exit 1
fi

# Get webhook secret (default from backend .env)
defaultSecret="super-secret"
echo "Webhook Secret (default: $defaultSecret) - MUST match backend CF_WEBHOOK_SECRET"
read -p "Webhook Secret: " webhookSecret
if [ -z "$webhookSecret" ]; then
    webhookSecret=$defaultSecret
fi

# Get webhook path (optional)
defaultPath="/api/webhooks/cloudflare"
echo "Webhook Path (default: $defaultPath)"
read -p "Webhook Path: " webhookPath
if [ -z "$webhookPath" ]; then
    webhookPath=$defaultPath
fi

echo ""
echo "Setting up secrets..."
echo ""

# Set BACKEND_URL (use --env="" for production/default environment)
echo "Setting BACKEND_URL..."
echo "$backendUrl" | wrangler secret put BACKEND_URL --env=""
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set BACKEND_URL"
    exit 1
fi

# Set WEBHOOK_SECRET
echo "Setting WEBHOOK_SECRET..."
echo "$webhookSecret" | wrangler secret put WEBHOOK_SECRET --env=""
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set WEBHOOK_SECRET"
    exit 1
fi

# Set WEBHOOK_PATH
echo "Setting WEBHOOK_PATH..."
echo "$webhookPath" | wrangler secret put WEBHOOK_PATH --env=""
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set WEBHOOK_PATH"
    exit 1
fi

echo ""
echo "========================================"
echo "Secrets configured successfully!"
echo "========================================"
echo ""
echo "Configuration:"
echo "  BACKEND_URL: $backendUrl"
echo "  WEBHOOK_SECRET: $webhookSecret"
echo "  WEBHOOK_PATH: $webhookPath"
echo ""
echo "Next step: Deploy the worker with 'wrangler deploy'"

