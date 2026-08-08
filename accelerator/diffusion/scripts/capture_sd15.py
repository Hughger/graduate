"""Capture one local SD1.5 U-Net ResNetBlock without downloading weights."""

from __future__ import annotations

import argparse
from pathlib import Path

from sd_accel.capture import capture_block


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-path", required=True, type=Path)
    parser.add_argument("--block-path", required=True)
    parser.add_argument("--timestep", required=True, type=int)
    parser.add_argument("--seed", required=True, type=int)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    capture_block(args.model_path, args.block_path, args.timestep, args.seed, args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
