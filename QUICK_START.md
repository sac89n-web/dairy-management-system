# Quick Start Guide

## Prerequisites
1. .NET 8 SDK installed
2. PostgreSQL 14+ installed and running
3. pgAdmin or similar PostgreSQL client

## Database Setup
1. Open pgAdmin and connect to your PostgreSQL server
2. Create a new database named `dairy_management` (or use existing `postgres` database)
3. Run the SQL script: `Scripts/minimal_database_setup.sql`

## Application Setup
1. Update database credentials in both files:
   - `src/Web/appsettings.json` - ConnectionStrings:Postgres
   - `src/Web/dbconfig.json` - All fields

2. Common PostgreSQL credentials to try:
   - Username: `postgres`, Password: `postgres`
   - Username: `postgres`, Password: `admin`
   - Username: `postgres`, Password: `password`
   - Use the same credentials you use in pgAdmin

## Run Application
```bash
cd "src/Web"
dotnet run
```

## Access Application
- Main App: https://localhost:5001
- Database Test: https://localhost:5001/api/test-db
- Health Check: https://localhost:5001/health
- Swagger API: https://localhost:5001/swagger

## Default Login
- Auto-login as Admin is enabled
- Mobile: 8108891477
- OTP: 2025 (works for any mobile)

## Troubleshooting
1. **Database Connection Issues**: 
   - Check pgAdmin connection settings
   - Update `dbconfig.json` with exact same credentials
   - Test connection at `/api/test-db`

2. **Build Errors**:
   - Ensure .NET 8 SDK is installed
   - Run `dotnet restore` in src/Web directory

3. **Port Issues**:
   - Kill existing processes: `taskkill /F /IM dotnet.exe`
   - Or change port in `Properties/launchSettings.json`

## Features Available
- Dashboard with metrics
- Milk Collection management
- Sales tracking
- Payment processing
- Reports generation
- User management with OTP
- Modern responsive UI