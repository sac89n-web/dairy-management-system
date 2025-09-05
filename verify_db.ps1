# PowerShell script to verify PostgreSQL dairy schema
try {
    # Connection string
    $connectionString = "Host=localhost;Port=5432;Database=dairy;Username=postgres;Password=admin123"
    
    # Load Npgsql assembly (if available)
    Add-Type -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\*\Npgsql.dll" -ErrorAction SilentlyContinue
    
    Write-Host "Attempting to connect to PostgreSQL database 'dairy'..." -ForegroundColor Green
    
    # Try using psql command if available
    $psqlPath = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlPath) {
        Write-Host "Using psql command..." -ForegroundColor Yellow
        
        # Get tables in dairy schema
        $tablesQuery = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'dairy' ORDER BY table_name;"
        $env:PGPASSWORD = "admin123"
        $tables = psql -h localhost -p 5432 -U postgres -d dairy -t -c $tablesQuery
        
        Write-Host "Tables in 'dairy' schema:" -ForegroundColor Cyan
        $tables | ForEach-Object { 
            $tableName = $_.Trim()
            if ($tableName) {
                Write-Host "  - $tableName" -ForegroundColor White
                
                # Get column info for each table
                $columnsQuery = "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'dairy' AND table_name = '$tableName' ORDER BY ordinal_position;"
                $columns = psql -h localhost -p 5432 -U postgres -d dairy -t -c $columnsQuery
                
                Write-Host "    Columns:" -ForegroundColor Gray
                $columns | ForEach-Object {
                    $colInfo = $_.Trim()
                    if ($colInfo) {
                        Write-Host "      $colInfo" -ForegroundColor DarkGray
                    }
                }
                Write-Host ""
            }
        }
    } else {
        Write-Host "psql command not found. Please install PostgreSQL client tools." -ForegroundColor Red
        Write-Host "Or ensure PostgreSQL bin directory is in your PATH." -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}