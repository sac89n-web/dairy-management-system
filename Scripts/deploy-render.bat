@echo off
echo Deploying to Render.com...

REM Check if git is initialized
if not exist .git (
    echo Initializing git repository...
    git init
    git branch -M main
)

REM Add all files
git add .

REM Commit changes
git commit -m "Deploy to Render - %date% %time%"

REM Check if remote exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo Please add your GitHub repository URL:
    set /p repo_url="Enter GitHub repository URL: "
    git remote add origin %repo_url%
)

REM Push to GitHub
git push -u origin main

echo.
echo Deployment files pushed to GitHub.
echo Now connect your GitHub repository to Render.com
echo.
echo Build Command: dotnet publish src/Web/Dairy.Web.csproj -c Release -o out
echo Start Command: dotnet out/Dairy.Web.dll
echo Health Check Path: /health
echo.
pause