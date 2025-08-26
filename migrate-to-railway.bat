@echo off
echo Migrating local PostgreSQL schema to Railway...

echo Step 1: Extracting schema from local database...
python Scripts\extract-local-schema.py

if %ERRORLEVEL% NEQ 0 (
    echo Failed to extract local schema!
    pause
    exit /b 1
)

echo Step 2: Applying schema to Railway database...
python Scripts\apply-to-railway.py

if %ERRORLEVEL% EQU 0 (
    echo Migration completed successfully!
) else (
    echo Migration failed!
)

pause