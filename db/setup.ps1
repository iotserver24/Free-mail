# PowerShell script to setup database
# Run this from the project root

$env:PGPASSWORD = "18751@Anish"
$dbHost = "193.24.208.154"
$database = "chat"
$user = "postgres"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FreeMail Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if psql is available
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: psql not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PostgreSQL client tools:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Yellow
    Write-Host "  2. Or use a GUI tool like pgAdmin or DBeaver" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SQL file location: db\init.sql" -ForegroundColor Yellow
    Write-Host "You can copy the SQL and run it manually in your database client." -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: psql found" -ForegroundColor Green
Write-Host ""
Write-Host "Connecting to database..." -ForegroundColor Yellow
Write-Host "  Host: $dbHost" -ForegroundColor Gray
Write-Host "  Database: $database" -ForegroundColor Gray
Write-Host "  User: $user" -ForegroundColor Gray
Write-Host ""

# Execute the SQL file
try {
    Write-Host "Executing init.sql..." -ForegroundColor Yellow
    & psql -h $dbHost -U $user -d $database -f "db\init.sql"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "SUCCESS: Database setup complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Tables created:" -ForegroundColor Cyan
        Write-Host "  - users" -ForegroundColor Gray
        Write-Host "  - messages" -ForegroundColor Gray
        Write-Host "  - attachments" -ForegroundColor Gray
        Write-Host "  - labels" -ForegroundColor Gray
        Write-Host "  - mailboxes" -ForegroundColor Gray
        Write-Host "  - message_labels" -ForegroundColor Gray
        Write-Host ""
        Write-Host "You can now start your backend server!" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "ERROR: Error executing SQL script" -ForegroundColor Red
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if PostgreSQL server is running" -ForegroundColor Gray
    Write-Host "  2. Verify connection details in backend/.env" -ForegroundColor Gray
    Write-Host "  3. Check firewall settings" -ForegroundColor Gray
    exit 1
}
