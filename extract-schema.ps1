# PowerShell script to extract PostgreSQL schema
$ErrorActionPreference = "Stop"

Write-Host "Extracting schema from local PostgreSQL..."

# Check if pg_dump is available
$pgDumpPath = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $pgDumpPath) {
    Write-Host "pg_dump not found. Please install PostgreSQL client tools."
    exit 1
}

# Extract schema only (no data)
$env:PGPASSWORD = "admin123"
pg_dump -h localhost -U admin -d postgres -n dairy --schema-only --no-owner --no-privileges -f "Scripts\schema-only.sql"

# Extract data only
pg_dump -h localhost -U admin -d postgres -n dairy --data-only --no-owner --no-privileges -f "Scripts\data-only.sql"

# Combine into migration script
$schemaContent = Get-Content "Scripts\schema-only.sql" -Raw
$dataContent = Get-Content "Scripts\data-only.sql" -Raw

$migrationScript = @"
-- Generated migration script from local PostgreSQL to Railway
-- Run this script on Railway PostgreSQL

$schemaContent

$dataContent

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA dairy TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA dairy TO PUBLIC;

SELECT 'Migration completed successfully!' as status;
"@

$migrationScript | Out-File -FilePath "Scripts\local-to-railway-migration.sql" -Encoding UTF8

Write-Host "Schema extracted to Scripts\local-to-railway-migration.sql"
Write-Host "Now apply this script to Railway PostgreSQL manually."