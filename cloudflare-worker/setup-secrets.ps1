# PowerShell script to set up Cloudflare Worker secrets
# Run this script to configure all required secrets

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cloudflare Worker Secrets Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if wrangler is installed
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Wrangler CLI is not installed!" -ForegroundColor Red
    Write-Host "Install it with: npm install -g wrangler" -ForegroundColor Yellow
    exit 1
}

Write-Host "Please enter the following values:" -ForegroundColor Yellow
Write-Host ""

# Get backend URL
$backendUrl = Read-Host "Backend URL (e.g., https://your-backend.com or https://xxxx.ngrok.io for local)"
if ([string]::IsNullOrWhiteSpace($backendUrl)) {
    Write-Host "ERROR: Backend URL is required!" -ForegroundColor Red
    exit 1
}

# Get webhook secret (default from backend .env)
$defaultSecret = "super-secret"
Write-Host "Webhook Secret (default: $defaultSecret) - MUST match backend CF_WEBHOOK_SECRET" -ForegroundColor Yellow
$webhookSecret = Read-Host "Webhook Secret"
if ([string]::IsNullOrWhiteSpace($webhookSecret)) {
    $webhookSecret = $defaultSecret
}

# Get webhook path (optional)
$defaultPath = "/api/webhooks/cloudflare"
Write-Host "Webhook Path (default: $defaultPath)" -ForegroundColor Yellow
$webhookPath = Read-Host "Webhook Path"
if ([string]::IsNullOrWhiteSpace($webhookPath)) {
    $webhookPath = $defaultPath
}

Write-Host ""
Write-Host "Setting up secrets..." -ForegroundColor Green
Write-Host ""

# Set BACKEND_URL (use --env="" for production/default environment)
Write-Host "Setting BACKEND_URL..." -ForegroundColor Cyan
echo $backendUrl | wrangler secret put BACKEND_URL --env=""
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set BACKEND_URL" -ForegroundColor Red
    exit 1
}

# Set WEBHOOK_SECRET
Write-Host "Setting WEBHOOK_SECRET..." -ForegroundColor Cyan
echo $webhookSecret | wrangler secret put WEBHOOK_SECRET --env=""
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set WEBHOOK_SECRET" -ForegroundColor Red
    exit 1
}

# Set WEBHOOK_PATH
Write-Host "Setting WEBHOOK_PATH..." -ForegroundColor Cyan
echo $webhookPath | wrangler secret put WEBHOOK_PATH --env=""
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to set WEBHOOK_PATH" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Secrets configured successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  BACKEND_URL: $backendUrl" -ForegroundColor White
Write-Host "  WEBHOOK_SECRET: $webhookSecret" -ForegroundColor White
Write-Host "  WEBHOOK_PATH: $webhookPath" -ForegroundColor White
Write-Host ""
Write-Host "Next step: Deploy the worker with 'wrangler deploy'" -ForegroundColor Cyan

