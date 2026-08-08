"""Generate deterministic 16/32-segment SiLU PWL JSON and Scala tables."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

PYTHON_ROOT = Path(__file__).resolve().parents[1] / "python"
if str(PYTHON_ROOT) not in sys.path:
    sys.path.insert(0, str(PYTHON_ROOT))

from sd_accel.silu import build_coefficients


def _scala_table(name: str, table: dict[str, object]) -> str:
    rows = table["coefficients"]
    assert isinstance(rows, list)
    entries = ",\n    ".join(
        f"SiluSegment({row['start_q8']}, {row['end_q8']}, {row['slope_q16']}, {row['intercept_q8']})"
        for row in rows
        if isinstance(row, dict)
    )
    return f"  val {name}: Seq[SiluSegment] = Seq(\n    {entries}\n  )\n"


def generate(output_dir: Path, scala_output: Path | None = None) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    tables = {segments: build_coefficients(segments) for segments in (16, 32)}
    for segments, table in tables.items():
        (output_dir / f"silu_pwl_{segments}.json").write_text(
            json.dumps(table, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
    scala = (
        "package FLOOD_Accelerator.diffusion\n\n"
        "object SiluCoeffs {\n"
        "  final case class SiluSegment(startQ8: Int, endQ8: Int, slopeQ16: Int, interceptQ8: Int)\n\n"
        f"{_scala_table('segments16', tables[16])}\n"
        f"{_scala_table('segments32', tables[32])}"
        "}\n"
    )
    target = scala_output or output_dir / "SiluCoeffs.scala"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(scala, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--scala-output", type=Path)
    args = parser.parse_args()
    generate(args.output_dir, args.scala_output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
