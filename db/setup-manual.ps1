# Alternative setup method using .NET PostgreSQL driver
# This works without psql installed

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FreeMail Database Setup (Manual Method)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$dbHost = "193.24.208.154"
$database = "chat"
$user = "postgres"
$password = "18751@Anish"

Write-Host "Since psql is not installed, here are your options:" -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION 1: Install PostgreSQL Client Tools" -ForegroundColor Cyan
Write-Host "  1. Download from: https://www.postgresql.org/download/windows/" -ForegroundColor Gray
Write-Host "  2. Install PostgreSQL (includes psql)" -ForegroundColor Gray
Write-Host "  3. Run: .\db\setup.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "OPTION 2: Use a Database GUI Tool" -ForegroundColor Cyan
Write-Host "  Recommended tools:" -ForegroundColor Gray
Write-Host "    - pgAdmin: https://www.pgadmin.org/download/" -ForegroundColor Gray
Write-Host "    - DBeaver: https://dbeaver.io/download/" -ForegroundColor Gray
Write-Host "    - TablePlus: https://tableplus.com/" -ForegroundColor Gray
Write-Host ""
Write-Host "  Connection details:" -ForegroundColor Yellow
Write-Host "    Host: $dbHost" -ForegroundColor White
Write-Host "    Port: 5432" -ForegroundColor White
Write-Host "    Database: $database" -ForegroundColor White
Write-Host "    Username: $user" -ForegroundColor White
Write-Host "    Password: $password" -ForegroundColor White
Write-Host "    SSL Mode: allow" -ForegroundColor White
Write-Host ""
Write-Host "  Then open SQL file: db\init.sql" -ForegroundColor Yellow
Write-Host "  Copy and paste the SQL into your SQL editor and execute." -ForegroundColor Yellow
Write-Host ""
Write-Host "OPTION 3: Use Online SQL Editor" -ForegroundColor Cyan
Write-Host "  If your database is accessible, you can use:" -ForegroundColor Gray
Write-Host "    - Adminer (if installed on server)" -ForegroundColor Gray
Write-Host "    - phpPgAdmin (if installed on server)" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SQL File Location: db\init.sql" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

