# NVIDIA Kimodo on AMD ROCm

Run NVIDIA's Kimodo demo on supported AMD Radeon GPUs using AMD's official Windows ROCm PyTorch stack.

This helper package was tested with:

- AMD Radeon RX 9070 XT
- Windows 11
- Python 3.12 x64
- ROCm 7.2 Windows PyTorch wheels
- `torch 2.9.1+rocmsdk20260116`

It is separate from ZLUDA. No CUDA DLL replacement is required.

## What This Does

Kimodo's original Windows installer assumes a CUDA-style setup. On AMD, the main PyTorch path can work through AMD's ROCm build, but the local text encoder also uses a 4-bit NF4 bitsandbytes model. These scripts create a separate `venv-rocm` environment and install the bitsandbytes Windows ROCm preview wheel needed by that text encoder.

The original Kimodo `venv` is left untouched.

## Requirements

- Windows 11
- A supported AMD Radeon GPU, such as RX 9070 XT
- AMD Adrenalin / graphics driver new enough for ROCm 7.2
- Python 3.12 x64 from python.org
- Git
- Node.js
- The Kimodo source folder and text encoder model downloaded by the original Kimodo installer

Python 3.12 is required for AMD's official Windows ROCm PyTorch wheels. Python 3.11 can work for Kimodo's original CUDA-oriented installer, but it is not enough for this ROCm environment.

## Folder Layout

Place these files in the same folder that contains Kimodo's original installer and the cloned `kimodo` source folder:

```text
kimodo/
  install_kimodo.bat
  start_kimodo.bat
  kimodo/
  KIMODO-Meta3_llm2vec_NF4/
  install_kimodo_rocm.bat
  repair_kimodo_rocm_bitsandbytes.bat
  verify_kimodo_rocm.bat
  start_kimodo_rocm.bat
  tools/
    rocm/
      rocminfo.bat
```

After installation, the ROCm environment is created at:

```text
venv-rocm/
```

## Install

First install Python 3.12 x64 from python.org. During installation, enable:

```text
Add python.exe to PATH
```

Open a new terminal and confirm:

```bat
python --version
```

You should see Python 3.12.x.

Then run:

```bat
install_kimodo_rocm.bat
```

The installer will:

- Create `venv-rocm`
- Install AMD ROCm runtime wheels
- Install AMD ROCm PyTorch wheels
- Install Kimodo and Viser into `venv-rocm`
- Install the ROCm-compatible bitsandbytes preview wheel
- Reapply the local text encoder override
- Verify that PyTorch sees your AMD GPU

## Verify

Run:

```bat
verify_kimodo_rocm.bat
```

Expected output should include something like:

```text
torch: 2.9.1+rocmsdk20260116
gpu available: True
device 0: AMD Radeon RX 9070 XT
bitsandbytes: 1.33.7.preview
```

PyTorch on ROCm still uses the `torch.cuda` namespace for compatibility. On AMD ROCm, `torch.cuda.is_available()` returning `True` is normal.

## Launch

Run:

```bat
start_kimodo_rocm.bat
```

You should see Kimodo load with:

```text
Using device: cuda:0
device: AMD Radeon RX 9070 XT
```

## Fix bitsandbytes

If Kimodo fails with:

```text
Configured ROCm binary not found
libbitsandbytes_rocm72.dll
```

run:

```bat
repair_kimodo_rocm_bitsandbytes.bat
```

Then rerun:

```bat
verify_kimodo_rocm.bat
start_kimodo_rocm.bat
```

## Notes

- Do not copy ZLUDA DLLs into `venv-rocm`.
- Do not mix this environment with the original `venv`.
- The local text encoder is a quantized NF4 model, so bitsandbytes support matters even when PyTorch ROCm itself is working.
- The `tools/rocm/rocminfo.bat` shim exists because bitsandbytes expects a `rocminfo` command on PATH. It reports `gfx1201` and wavefront size `32` for RX 9070 XT.

## References

- AMD ROCm Windows PyTorch install: https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/install/installryz/windows/install-pytorch.html
- AMD ROCm Windows compatibility matrix: https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityrad/windows/windows_compatibility.html
- bitsandbytes installation docs: https://huggingface.co/docs/bitsandbytes/main/installation
- Kimodo: https://github.com/Aero-Ex/kimodo
