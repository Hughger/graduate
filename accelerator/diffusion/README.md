# SD1.5 ResNetBlock Accelerator Tooling

This directory contains the Python-side reference tooling for the AXKU15
Stable Diffusion 1.5 U-Net ResNetBlock accelerator. Task 1 freezes the
legacy FLOOD configuration and records the local toolchain rather than
changing the existing CNN accelerator behavior.

## Environment baseline

Use Python 3.10 or newer. Install the base test/runtime dependencies and,
when local SD1.5 tensor capture is required, the optional model dependencies:

```powershell
python -m pip install -e .
python -m pip install -e ".[model]"
```

Run the environment contract test and write the local baseline report:

```powershell
python -m pytest tests/test_environment.py -v
python scripts/check_environment.py
```

The report is written to `results/baseline/environment.json`. It captures
Python, NumPy, PyTorch, Java, SBT, and Vivado versions. Missing external
tools are represented as `"unavailable"`; they do not make the collector
non-deterministic or prevent later software-only work.

The frozen legacy FLOOD settings are read directly from
`../src/main/scala/core/Config.scala`: `rowSize=32`, `colSize=32`,
`dataWidth=8`, `pipeline=2`, `tLatency=4`, `compressionFactor=4`, and
`tileSize=16`.
