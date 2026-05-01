@echo off
setlocal
title Verify Kimodo AMD ROCm

cd /d "%~dp0"

if not exist "%~dp0venv-rocm\Scripts\activate.bat" (
    echo ERROR: venv-rocm does not exist. Run install_kimodo_rocm.bat first.
    exit /b 1
)

call "%~dp0venv-rocm\Scripts\activate.bat"
if errorlevel 1 exit /b 1

set "PATH=%~dp0tools\rocm;%PATH%"
set "BNB_CUDA_VERSION="

echo Verifying AMD ROCm PyTorch...
python -c "import torch; print('torch:', torch.__version__); print('cuda namespace available:', hasattr(torch, 'cuda')); print('gpu available:', torch.cuda.is_available()); print('device count:', torch.cuda.device_count()); print('device 0:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'none')"
if errorlevel 1 exit /b 1

echo Verifying bitsandbytes ROCm library...
python -c "import pathlib, bitsandbytes; p=pathlib.Path(bitsandbytes.__file__).parent; print('bitsandbytes:', bitsandbytes.__version__); print('rocm dlls:', [x.name for x in p.glob('libbitsandbytes_rocm*.dll')])"
if errorlevel 1 exit /b 1

python -c "import kimodo; print('kimodo import: ok')"
if errorlevel 1 exit /b 1

echo ROCm verification complete.
exit /b 0
