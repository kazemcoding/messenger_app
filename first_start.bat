@echo off
setlocal enabledelayedexpansion
title Messenger App - First Time Setup
color 0B

echo ============================================================
echo   MESSENGER APP - FIRST TIME SETUP
echo   Run this file only ONCE for initial setup
echo ============================================================
echo.

:: ============================================================
:: CHECK 1: Is this really the first time?
:: ============================================================
if exist "venv\Scripts\activate.bat" (
    if exist "backend\.env" (
        echo WARNING: Setup appears to be already completed.
        echo.
        echo    - venv folder exists
        echo    - .env file exists
        echo.
        echo If you want to reinstall from scratch, delete:
        echo    - venv folder
        echo    - backend\.env file
        echo.
        pause
        exit /b 0
    )
)

:: ============================================================
:: CHECK 2: Check Python
:: ============================================================
echo [1/7] Checking Python installation...
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed!
    echo.
    echo Please install Python 3.11 or higher:
    echo   https://www.python.org/downloads/
    echo.
    echo IMPORTANT: Check "Add Python to PATH" during installation!
    echo.
    
    :: Offer to open download page
    set /p OPEN_URL="Do you want to open the download page? (y/n): "
    if /i "!OPEN_URL!"=="y" (
        start https://www.python.org/downloads/
    )
    
    pause
    exit /b 1
)

:: Check Python version >= 3.11
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PY_VERSION=%%i
for /f "tokens=1,2 delims=." %%a in ("!PY_VERSION!") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)

if !PY_MAJOR! LSS 3 (
    echo ERROR: Python version !PY_VERSION! is too old!
    echo    Python 3.11 or higher is required.
    pause
    exit /b 1
)

if !PY_MAJOR! EQU 3 if !PY_MINOR! LSS 11 (
    echo ERROR: Python version !PY_VERSION! is too old!
    echo    Python 3.11 or higher is required.
    pause
    exit /b 1
)

echo OK: Python !PY_VERSION! is installed
echo.

:: ============================================================
:: CHECK 3: Check pip
:: ============================================================
echo [2/7] Checking pip...

python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo WARNING: pip is not installed. Installing...
    python -m ensurepip --upgrade
)

echo OK: pip is ready
echo.

:: ============================================================
:: CHECK 4: Create Virtual Environment
:: ============================================================
echo [3/7] Creating virtual environment (venv)...
echo.

if exist "venv" (
    echo WARNING: venv already exists
    set /p DELETE_VENV="Do you want to delete and recreate it? (y/n): "
    if /i "!DELETE_VENV!"=="y" (
        echo Deleting venv...
        rmdir /s /q venv
        python -m venv venv
        if errorlevel 1 (
            echo ERROR: Failed to create venv!
            pause
            exit /b 1
        )
        echo OK: New venv created
    )
) else (
    echo Creating venv (this may take 1-2 minutes)...
    python -m venv venv
    if errorlevel 1 (
        echo ERROR: Failed to create venv!
        pause
        exit /b 1
    )
    echo OK: venv created
)
echo.

:: ============================================================
:: CHECK 5: Install Dependencies
:: ============================================================
echo [4/7] Activating venv and installing packages...
echo.

call venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Failed to activate venv!
    pause
    exit /b 1
)

echo Upgrading pip...
python -m pip install --upgrade pip --quiet
echo OK: pip upgraded
echo.

echo Installing required packages (3-5 minutes)...
echo.

if not exist "backend\requirements.txt" (
    echo ERROR: backend\requirements.txt not found!
    echo    Make sure you are in the correct folder.
    pause
    exit /b 1
)

echo [Attempt 1] Installing from main PyPI...
python -m pip install -r backend\requirements.txt --quiet
if errorlevel 1 (
    echo.
    echo WARNING: Main PyPI failed. Trying Runflare mirror...
    python -m pip install -r backend\requirements.txt ^
        --index-url https://mirror-pypi.runflare.com/simple ^
        --trusted-host mirror-pypi.runflare.com ^
        --quiet
    
    if errorlevel 1 (
        echo.
        echo WARNING: Runflare failed too. Trying Sharif mirror...
        python -m pip install -r backend\requirements.txt ^
            --index-url https://mirror.sharif.edu/pypi/simple ^
            --trusted-host mirror.sharif.edu ^
            --quiet
        
        if errorlevel 1 (
            echo.
            echo ERROR: All mirrors failed!
            echo    Please check your internet connection.
            pause
            exit /b 1
        )
    )
)

echo.
echo OK: All packages installed
echo.

:: ============================================================
:: CHECK 6: Create .env File
:: ============================================================
echo [5/7] Creating .env file with random SECRET_KEY...
echo.

if exist "backend\.env" (
    echo WARNING: backend\.env already exists
    set /p KEEP_ENV="Do you want to keep it? (y/n): "
    if /i "!KEEP_ENV!"=="y" (
        echo OK: Keeping existing .env file
        goto :verify
    )
    echo Rebuilding .env...
    del "backend\.env"
)

:: Generate random SECRET_KEY
for /f "delims=" %%i in ('python -c "import secrets; print(secrets.token_hex(32))"') do set SECRET_KEY=%%i

(
    echo SECRET_KEY=!SECRET_KEY!
    echo ALGORITHM=HS256
    echo ACCESS_TOKEN_EXPIRE_MINUTES=10080
) > backend\.env

echo OK: backend\.env created
echo.

:verify

:: ============================================================
:: CHECK 7: Verify Installation
:: ============================================================
echo [6/7] Verifying package installation...
echo.

set ALL_OK=1

python -c "import fastapi; print('  OK FastAPI:', fastapi.__version__)" 2>nul || (echo   ERROR: FastAPI not installed & set ALL_OK=0)
python -c "import uvicorn; print('  OK uvicorn:', uvicorn.__version__)" 2>nul || (echo   ERROR: uvicorn not installed & set ALL_OK=0)
python -c "import sqlalchemy; print('  OK SQLAlchemy:', sqlalchemy.__version__)" 2>nul || (echo   ERROR: SQLAlchemy not installed & set ALL_OK=0)
python -c "import pydantic; print('  OK pydantic:', pydantic.__version__)" 2>nul || (echo   ERROR: pydantic not installed & set ALL_OK=0)
python -c "import jose; print('  OK python-jose: OK')" 2>nul || (echo   ERROR: python-jose not installed & set ALL_OK=0)
python -c "import passlib; print('  OK passlib: OK')" 2>nul || (echo   ERROR: passlib not installed & set ALL_OK=0)
python -c "import bcrypt; print('  OK bcrypt:', bcrypt.__version__)" 2>nul || (echo   ERROR: bcrypt not installed & set ALL_OK=0)

echo.

if !ALL_OK! EQU 0 (
    echo ERROR: Some packages are not installed!
    echo    Please check the errors above.
    pause
    exit /b 1
)

:: ============================================================
:: FINAL: Ask to start server
:: ============================================================
echo [7/7] Setup complete!
echo.
echo ============================================================
echo   SETUP COMPLETE!
echo   Installation successful!
echo ============================================================
echo.

:: Check if Tailscale is available
where tailscale >nul 2>&1
if errorlevel 1 (
    echo WARNING: Tailscale is not installed. (Optional)
    echo    To allow access from the internet, install from:
    echo      https://tailscale.com/download/windows
    echo.
)

set /p START_NOW="Do you want to start the server now? (y/n): "
if /i "!START_NOW!"=="y" (
    echo.
    echo Starting server...
    echo.
    echo Press Ctrl+C to stop the server.
    echo.
    cd backend
    python main.py
    cd ..
) else (
    echo.
    echo OK: To start later, double-click start.bat
    echo.
)

pause