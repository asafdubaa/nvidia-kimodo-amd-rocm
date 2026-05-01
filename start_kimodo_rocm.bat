@echo off
setlocal
title Kimodo AMD ROCm

cd /d "%~dp0kimodo"

if not exist "%~dp0venv-rocm\Scripts\activate.bat" (
    echo ERROR: AMD ROCm environment not found.
    echo Run install_kimodo_rocm.bat first.
    pause
    exit /b 1
)

call "%~dp0venv-rocm\Scripts\activate.bat"
if errorlevel 1 (
    echo ERROR: Failed to activate venv-rocm.
    pause
    exit /b 1
)

set "PATH=%~dp0tools\rocm;%PATH%"
set "BNB_CUDA_VERSION="

python -c "import torch; print('torch:', torch.__version__); print('gpu available:', torch.cuda.is_available()); print('device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU')"
if errorlevel 1 (
    echo ERROR: PyTorch ROCm check failed.
    pause
    exit /b 1
)

if not exist "kimodo-viser\src\viser\client\build" (
    echo Viser client not built yet. Building now...
    set "PATH=C:\Program Files\nodejs;%PATH%"
    pushd kimodo-viser\src\viser\client
    if exist .nodeenv rmdir /s /q .nodeenv
    call npm install --legacy-peer-deps
    if errorlevel 1 exit /b 1
    call npx vite build
    if errorlevel 1 exit /b 1
    popd
    echo.
)

python -m kimodo.demo
pause
