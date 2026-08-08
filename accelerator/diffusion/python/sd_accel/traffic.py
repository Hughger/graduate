"""DDR traffic accounting for fused and materialized ResNetBlock execution."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


REQUIRED_SHAPES = ((1, 320, 64, 64), (1, 640, 32, 32), (1, 1280, 16, 16), (1, 1280, 8, 8))


def estimate_traffic(shape: tuple[int, int, int, int]) -> dict[str, object]:
    """Report bytes for one equal-channel 3x3 ResNetBlock execution."""
    batch, channels, height, width = shape
    if min(shape) <= 0 or channels % 32:
        raise ValueError("shape must be positive with a channel count divisible by 32")
    activation_bytes = batch * channels * height * width * 2
    common = {
        "input": activation_bytes,
        "weights": 2 * channels * channels * 3 * 3,
        "temb": batch * channels * 2,
        "output": activation_bytes,
    }
    materialized_stages = ("gn1", "silu1", "conv1_time", "gn2", "silu2")
    intermediate_unfused = len(materialized_stages) * activation_bytes * 2
    fused = sum(common.values())
    unfused = fused + intermediate_unfused
    return {
        "shape": list(shape),
        "common_bytes": common,
        "intermediate_bytes": {"fused": 0, "unfused": intermediate_unfused},
        "fused_bytes": fused,
        "unfused_bytes": unfused,
        "total_reduction": 1.0 - fused / unfused,
        "intermediate_reduction": 1.0,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all-required-shapes", action="store_true")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not args.all_required_shapes:
        parser.error("--all-required-shapes is required")
    report = {"shapes": [estimate_traffic(shape) for shape in REQUIRED_SHAPES]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
