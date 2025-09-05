@echo off
echo Applying Feedback Implementation Schema...

REM Try to find PostgreSQL installation
set PGPATH=
if exist "C:\Program Files\PostgreSQL\17\bin\psql.exe" set PGPATH=C:\Program Files\PostgreSQL\17\bin\
if exist "C:\Program Files\PostgreSQL\16\bin\psql.exe" set PGPATH=C:\Program Files\PostgreSQL\16\bin\
if exist "C:\Program Files\PostgreSQL\15\bin\psql.exe" set PGPATH=C:\Program Files\PostgreSQL\15\bin\

if "%PGPATH%"=="" (
    echo PostgreSQL not found in standard locations
    echo Please run the SQL script manually in pgAdmin or your PostgreSQL client
    echo File: Scripts\feedback_implementation_schema.sql
    pause
    exit /b 1
)

echo Found PostgreSQL at: %PGPATH%

REM Set PGPASSWORD to avoid password prompt
set PGPASSWORD=admin123

REM Run the schema
"%PGPATH%psql.exe" -h localhost -U admin -d postgres -f "Scripts\feedback_implementation_schema.sql"

if %ERRORLEVEL% EQU 0 (
    echo ✅ Feedback implementation schema applied successfully!
) else (
    echo ❌ Error applying schema. Please check the output above.
)

pause