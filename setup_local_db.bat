@echo off
echo 🏗️ Setting up Local Dairy Management Database
echo ============================================

REM Check if PostgreSQL is running
echo 🔍 Checking PostgreSQL service...
sc query postgresql-x64-14 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL service not found. Please install PostgreSQL first.
    pause
    exit /b 1
)

echo ✅ PostgreSQL service found

REM Test connection
echo 🔗 Testing database connection...
psql -h localhost -U admin -d postgres -c "SELECT version();" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Cannot connect to PostgreSQL. Please check:
    echo    - PostgreSQL is running
    echo    - Username: admin
    echo    - Password: admin123
    echo    - Database: postgres
    pause
    exit /b 1
)

echo ✅ Database connection successful

REM Create dairy schema and tables
echo 📊 Creating dairy schema and tables...
psql -h localhost -U admin -d postgres -f complete_schema_sync.sql
if %errorlevel% neq 0 (
    echo ❌ Schema creation failed
    pause
    exit /b 1
)

echo ✅ Schema created successfully

REM Verify setup
echo 🔍 Verifying database setup...
psql -h localhost -U admin -d postgres -c "SET search_path TO dairy; SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'dairy';"

echo.
echo 🎉 Local database setup completed!
echo.
echo 📋 Next steps:
echo 1. Start the application: dotnet run --project src\Web
echo 2. Visit: http://localhost:8081/setup-db (to verify)
echo 3. Visit: http://localhost:8081/list-tables (to see all tables)
echo.
pause