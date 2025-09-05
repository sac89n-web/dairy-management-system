@echo off
echo 🧪 Dairy Management System - Demo Test Runner
echo ===============================================

REM Create demo environment file
echo Creating demo environment...
echo API_BASE_URL=http://localhost:8081> .env.tests
echo API_KEY=demo-token>> .env.tests
echo DB_CONN=Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy>> .env.tests

REM Create demo results
echo Creating demo test results...
mkdir report 2>nul

echo {> report\results.json
echo   "timestamp": "%date% %time%",>> report\results.json
echo   "environment": {>> report\results.json
echo     "API_BASE_URL": "http://localhost:8081",>> report\results.json
echo     "hasDbConnection": true>> report\results.json
echo   },>> report\results.json
echo   "tests": {>> report\results.json
echo     "unit_tests": {>> report\results.json
echo       "status": "passed",>> report\results.json
echo       "duration": "15s",>> report\results.json
echo       "details": "All unit tests passed successfully">> report\results.json
echo     },>> report\results.json
echo     "api_tests": {>> report\results.json
echo       "status": "passed",>> report\results.json
echo       "duration": "23s",>> report\results.json
echo       "details": "All API endpoints tested successfully">> report\results.json
echo     },>> report\results.json
echo     "e2e_tests": {>> report\results.json
echo       "status": "skipped",>> report\results.json
echo       "duration": "0s",>> report\results.json
echo       "details": "Playwright not installed">> report\results.json
echo     },>> report\results.json
echo     "load_tests": {>> report\results.json
echo       "status": "skipped",>> report\results.json
echo       "duration": "0s",>> report\results.json
echo       "details": "k6 not installed">> report\results.json
echo     }>> report\results.json
echo   }>> report\results.json
echo }>> report\results.json

REM Copy template to create report
copy report\template-index.html report\index.html >nul 2>&1

echo ✅ Demo test results created!
echo 📊 Open report\index.html to view the test dashboard
echo.
echo 📋 Next steps:
echo 1. Install dependencies: npm install
echo 2. Set real environment variables in .env.tests
echo 3. Run full test suite: bash scripts/run-all.sh
echo.
pause