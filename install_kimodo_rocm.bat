@echo off
setlocal enabledelayedexpansion
title Kimodo AMD ROCm Installation

cd /d "%~dp0"

echo ============================================
echo   Kimodo AMD ROCm Installer (Windows)
echo   Radeon RX 9000/7000 official ROCm path
echo ============================================
echo.
echo This creates a separate environment at:
echo   %~dp0venv-rocm
echo.

call :find_python312
if not defined PYTHON_CMD (
    echo ERROR: Python 3.12 was not found.
    echo.
    echo AMD's official ROCm PyTorch Windows wheels require Python 3.12.
    echo Install Python 3.12 x64 from python.org, enable "Add python.exe to PATH",
    echo then open a new terminal and run this script again.
    echo.
    pause
    exit /b 1
)

echo [1/9] Using Python:
%PYTHON_CMD% --version
if errorlevel 1 goto :fail
echo.

if not exist "%~dp0kimodo\pyproject.toml" (
    echo ERROR: Kimodo source folder was not found at:
    echo   %~dp0kimodo
    echo Place this script beside the cloned Kimodo source folder.
    pause
    exit /b 1
)

echo [2/9] Creating AMD ROCm virtual environment...
if exist "%~dp0venv-rocm\Scripts\python.exe" (
    echo   venv-rocm already exists, reusing it.
) else (
    %PYTHON_CMD% -m venv "%~dp0venv-rocm"
    if errorlevel 1 goto :fail
)
call "%~dp0venv-rocm\Scripts\activate.bat"
if errorlevel 1 goto :fail
echo.

echo [3/9] Updating Python packaging tools...
python -m pip install --upgrade pip wheel setuptools
if errorlevel 1 goto :fail
echo.

echo [4/9] Installing AMD ROCm 7.2 runtime wheels...
python -m pip install --no-cache-dir ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/rocm_sdk_core-7.2.0.dev0-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/rocm_sdk_devel-7.2.0.dev0-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/rocm_sdk_libraries_custom-7.2.0.dev0-py3-none-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/rocm-7.2.0.dev0.tar.gz
if errorlevel 1 goto :fail
echo.

echo [5/9] Installing AMD ROCm PyTorch wheels...
python -m pip uninstall -y torch torchvision torchaudio >nul 2>&1
python -m pip install --no-cache-dir ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/torch-2.9.1%%2Brocmsdk20260116-cp312-cp312-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/torchvision-0.24.1%%2Brocmsdk20260116-cp312-cp312-win_amd64.whl ^
    https://repo.radeon.com/rocm/windows/rocm-rel-7.2/torchaudio-2.9.1%%2Brocmsdk20260116-cp312-cp312-win_amd64.whl
if errorlevel 1 goto :fail
echo.

echo [6/9] Installing Kimodo and Viser into venv-rocm...
python -m pip install -e "%~dp0kimodo\kimodo-viser"
if errorlevel 1 goto :fail
set SKIP_MOTION_CORRECTION_IN_SETUP=1
python -m pip install -e "%~dp0kimodo"
if errorlevel 1 goto :fail
echo.

echo [7/9] Installing Kimodo extra dependencies...
python -m pip install transformers==5.1.0
if errorlevel 1 echo WARNING: transformers failed to install.
set KIMODO_ROCM_REPAIR_NOPAUSE=1
call "%~dp0repair_kimodo_rocm_bitsandbytes.bat"
set KIMODO_ROCM_REPAIR_NOPAUSE=
if errorlevel 1 (
    echo WARNING: bitsandbytes ROCm repair failed.
    echo Kimodo may still launch, but the local NF4 text encoder may fail.
)
echo.

echo [8/9] Installing motion_correction wheel for Python 3.12...
python -m pip install "https://github.com/Aero-Ex/kimodo/releases/download/v1.0.0/motion_correction-1.0.0-cp312-cp312-win_amd64.whl"
if errorlevel 1 (
    echo WARNING: motion_correction cp312 wheel failed to install.
    echo Check https://github.com/Aero-Ex/kimodo/releases/tag/v1.0.0 for available wheels.
)
echo.

echo [9/9] Applying local text encoder override...
set "MODEL_DIR=%~dp0KIMODO-Meta3_llm2vec_NF4"
set "MODEL_DIR_PY=%MODEL_DIR:\=/%"
set "WRAPPER_FILE=%~dp0kimodo\kimodo\model\llm2vec\llm2vec_wrapper.py"
set "TEMPLATE_FILE=%~dp0_llm2vec_wrapper_template.py"

if not exist "%MODEL_DIR%" (
    echo WARNING: Model folder not found:
    echo   %MODEL_DIR%
    echo Run the original installer or download Aero-Ex/KIMODO-Meta3_llm2vec_NF4.
) else if not exist "%TEMPLATE_FILE%" (
    echo WARNING: Template not found:
    echo   %TEMPLATE_FILE%
) else (
    python -c "t=open(r'%TEMPLATE_FILE%').read(); open(r'%WRAPPER_FILE%','w',newline='\n').write(t.replace('__MODEL_DIR__', r'%MODEL_DIR_PY%'))"
    if errorlevel 1 goto :fail
)
echo.

call "%~dp0verify_kimodo_rocm.bat"
if errorlevel 1 (
    echo.
    echo Installation finished, but ROCm verification failed.
    echo Check the messages above before launching Kimodo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   AMD ROCm installation complete.
echo.
echo   Launch with:
echo     start_kimodo_rocm.bat
echo ============================================
pause
exit /b 0

:find_python312
call :check_python "py -3.12"
if defined PYTHON_CMD exit /b 0
call :check_python "python3.12"
if defined PYTHON_CMD exit /b 0
call :check_python "python312"
if defined PYTHON_CMD exit /b 0
call :check_python "python"
exit /b 0

:check_python
set "CANDIDATE=%~1"
%CANDIDATE% -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 12) else 1)" >nul 2>&1
if not errorlevel 1 set "PYTHON_CMD=%CANDIDATE%"
exit /b 0

:fail
echo.
echo ERROR: Installation failed at the step above.
pause
exit /b 1
