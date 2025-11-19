# PowerShell script to setup database
# Run this from the project root

$env:PGPASSWORD = "18751@Anish"
$host = "193.24.208.154"
$database = "chat"
$user = "postgres"

Write-Host "Setting up database tables..." -ForegroundColor Green

# Read and execute the SQL file
$sqlContent = Get-Content -Path "db\init.sql" -Raw

# Connect and execute
$connectionString = "host=$host port=5432 dbname=$database user=$user sslmode=require"
$env:PGPASSWORD = "18751@Anish"

# Using psql if available
if (Get-Command psql -ErrorAction SilentlyContinue) {
    Write-Host "Using psql to execute SQL..." -ForegroundColor Yellow
    $sqlContent | & psql -h $host -U $user -d $database
} else {
    Write-Host "psql not found. Please install PostgreSQL client tools or run the SQL manually." -ForegroundColor Red
    Write-Host "SQL file location: db\init.sql" -ForegroundColor Yellow
    Write-Host "You can also use a database GUI tool like pgAdmin or DBeaver." -ForegroundColor Yellow
}

Write-Host "Database setup complete!" -ForegroundColor Green

