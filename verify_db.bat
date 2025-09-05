@echo off
echo Verifying Dairy Management System Database Schema...
echo.

REM Set PostgreSQL password
set PGPASSWORD=admin123

REM Check if psql is available
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: psql command not found!
    echo Please install PostgreSQL client tools or add PostgreSQL bin directory to PATH
    echo Example: C:\Program Files\PostgreSQL\15\bin
    pause
    exit /b 1
)

echo Connecting to PostgreSQL database 'dairy'...
echo.

REM Run the verification script
psql -h localhost -p 5432 -U postgres -d dairy -f verify_schema.sql

if %errorlevel% equ 0 (
    echo.
    echo ✓ Database verification completed successfully!
) else (
    echo.
    echo ✗ Database verification failed!
    echo Please check:
    echo   1. PostgreSQL server is running
    echo   2. Database 'dairy' exists
    echo   3. User 'postgres' has access
    echo   4. Password is correct (admin123)
)

echo.
pause