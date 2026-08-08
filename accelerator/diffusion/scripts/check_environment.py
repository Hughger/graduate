"""Write a deterministic local toolchain and FLOOD baseline report."""

import json
import sys
from pathlib import Path


DIFFUSION_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(DIFFUSION_ROOT / "python"))

from sd_accel.environment import collect


def main() -> Path:
    report_path = DIFFUSION_ROOT / "results/baseline/environment.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        json.dumps(collect(), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return report_path


if __name__ == "__main__":
    print(main())
