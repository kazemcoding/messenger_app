@echo off
setlocal
title Messenger App - Update GitHub
color 0A

echo ============================================================
echo   MESSENGER APP - AUTO UPDATE TO GITHUB
echo ============================================================
echo.

cd /d "%~dp0"

:: ============================================================
:: CHECK 1: Is this a git repo?
:: ============================================================
if not exist ".git" (
    echo ERROR: This is not a Git repository!
    echo    Make sure you are in the correct folder.
    pause
    exit /b 1
)

:: ============================================================
:: CHECK 2: Check for changes
:: ============================================================
echo [1/5] Checking for changes...
git status --short > temp_status.txt

for %%A in (temp_status.txt) do set FILE_SIZE=%%~zA

if !FILE_SIZE! EQU 0 (
    echo.
    echo OK: No changes to commit. Everything is up to date.
    del temp_status.txt
    echo.
    pause
    exit /b 0
)

del temp_status.txt
echo OK: Changes detected
echo.

:: ============================================================
:: STEP 3: Add all changes
:: ============================================================
echo [2/5] Adding all changes...
git add .
if errorlevel 1 (
    echo ERROR: Failed to add changes!
    pause
    exit /b 1
)
echo OK: Changes added
echo.

:: ============================================================
:: STEP 4: Commit
:: ============================================================
echo [3/5] Committing changes...

:: Generate timestamp for commit message
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set COMMIT_MSG=Auto update: !datetime:~0,4!-!datetime:~4,2!-!datetime:~6,2! !datetime:~8,2!:!datetime:~10,2!

git commit -m "!COMMIT_MSG!"
if errorlevel 1 (
    echo WARNING: Nothing to commit (maybe no changes?)
    echo.
    pause
    exit /b 0
)
echo OK: Changes committed
echo.

:: ============================================================
:: STEP 5: Pull from remote (to avoid conflicts)
:: ============================================================
echo [4/5] Pulling latest changes from GitHub...
git pull origin main --rebase
if errorlevel 1 (
    echo.
    echo WARNING: Pull failed. There might be a conflict.
    echo    You may need to resolve it manually.
    echo.
    pause
    exit /b 1
)
echo OK: Pulled latest changes
echo.

:: ============================================================
:: STEP 6: Push to GitHub
:: ============================================================
echo [5/5] Pushing to GitHub...
git push origin main
if errorlevel 1 (
    echo.
    echo ERROR: Push failed!
    echo    Possible reasons:
    echo    - No internet connection
    echo    - Authentication failed (token expired?)
    echo    - Someone else pushed at the same time
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   SUCCESS! 
echo   Your code is now updated on GitHub!
echo ============================================================
echo.
echo Repository: https://github.com/kazem575/messenger_app
echo.
pause