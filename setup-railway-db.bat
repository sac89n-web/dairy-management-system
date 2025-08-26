@echo off
echo Setting up Railway PostgreSQL database...

set PGPASSWORD=TpXnyLAYfIJjZtsIcxNDWnICnwtUpDyC
psql -h turntable.proxy.rlwy.net -U postgres -p 19238 -d railway -f "Scripts\railway-complete-schema.sql"

if %ERRORLEVEL% EQU 0 (
    echo Database setup completed successfully!
) else (
    echo Database setup failed!
)

pause