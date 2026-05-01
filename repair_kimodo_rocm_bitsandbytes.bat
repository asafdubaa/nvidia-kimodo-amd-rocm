@echo off
setlocal
title Repair Kimodo AMD ROCm bitsandbytes

cd /d "%~dp0"

if not exist "%~dp0venv-rocm\Scripts\activate.bat" (
    echo ERROR: venv-rocm does not exist. Run install_kimodo_rocm.bat first.
    pause
    exit /b 1
)

call "%~dp0venv-rocm\Scripts\activate.bat"
if errorlevel 1 exit /b 1

set "PATH=%~dp0tools\rocm;%PATH%"
set "BNB_CUDA_VERSION="

echo ============================================
echo   Repairing bitsandbytes for AMD ROCm
echo ============================================
echo.
echo The normal PyPI wheel may not include the ROCm Windows DLL.
echo Installing the upstream continuous preview wheel instead.
echo.

python -m pip uninstall -y bitsandbytes
python -m pip install --force-reinstall --no-deps ^
    https://github.com/bitsandbytes-foundation/bitsandbytes/releases/download/continuous-release_main/bitsandbytes-1.33.7.preview-py3-none-win_amd64.whl
if errorlevel 1 goto :fail

echo.
echo Checking installed bitsandbytes ROCm DLLs...
python -c "import pathlib, bitsandbytes; p=pathlib.Path(bitsandbytes.__file__).parent; dlls=[x.name for x in p.glob('libbitsandbytes_rocm*.dll')]; print('bitsandbytes:', bitsandbytes.__version__); print('rocm dlls:', dlls); raise SystemExit(0 if dlls else 1)"
if errorlevel 1 goto :fail

echo.
echo bitsandbytes ROCm repair complete.
if not defined KIMODO_ROCM_REPAIR_NOPAUSE pause
exit /b 0

:fail
echo.
echo ERROR: bitsandbytes ROCm repair failed.
echo.
echo If this fails, the remaining route is compiling bitsandbytes from source
echo with Visual Studio C++ tools, CMake, Ninja, and ROCm SDK.
if not defined KIMODO_ROCM_REPAIR_NOPAUSE pause
exit /b 1
