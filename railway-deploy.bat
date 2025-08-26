@echo off
echo Preparing for Railway deployment...

echo Step 1: Cleaning build artifacts...
rmdir /s /q bin 2>nul
rmdir /s /q obj 2>nul
rmdir /s /q src\Web\bin 2>nul
rmdir /s /q src\Web\obj 2>nul

echo Step 2: Testing Docker build locally...
docker build -t dairy-management-test .

if %ERRORLEVEL% EQU 0 (
    echo Docker build successful!
    echo.
    echo Next steps:
    echo 1. Push your code to GitHub
    echo 2. Deploy from Railway dashboard
    echo 3. Set environment variables
    echo.
    echo See deploy-to-railway.html for detailed instructions
) else (
    echo Docker build failed! Check Dockerfile and dependencies.
)

pause