"""Collect reproducible local environment and FLOOD baseline metadata."""

import platform
import re
import shutil
import subprocess
from pathlib import Path


KEYS = (
    "rowSize",
    "colSize",
    "dataWidth",
    "pipeline",
    "tLatency",
    "compressionFactor",
    "tileSize",
)


def _version(command: list[str]) -> str:
    """Return the first version line for *command*, or ``unavailable``."""
    executable = shutil.which(command[0])
    if executable is None:
        return "unavailable"

    result = subprocess.run(
        [executable, *command[1:]],
        text=True,
        capture_output=True,
        check=False,
    )
    lines = (result.stdout or result.stderr).splitlines()
    return lines[0].strip() if lines else "unavailable"


def collect(repo: Path | None = None) -> dict[str, object]:
    """Return tool versions and the immutable legacy FLOOD configuration."""
    root = repo or Path(__file__).resolve().parents[3]
    build_sbt_path = root / "build.sbt"
    if not build_sbt_path.is_file():
        raise RuntimeError("missing build.sbt")
    config_path = root / "src/main/scala/core/Config.scala"
    config_text = config_path.read_text(encoding="utf-8")
    legacy_config: dict[str, int] = {}

    for key in KEYS:
        match = re.search(rf"val\s+{key}\s*=\s*(\d+)", config_text)
        if match is None:
            raise RuntimeError(f"missing Config.{key}")
        legacy_config[key] = int(match.group(1))

    import numpy

    try:
        import torch

        torch_version = torch.__version__
    except ImportError:
        torch_version = "unavailable"

    return {
        "legacy_build_sbt": build_sbt_path.relative_to(root).as_posix(),
        "python": platform.python_version(),
        "numpy": numpy.__version__,
        "torch": torch_version,
        "java": _version(["java", "-version"]),
        "sbt": _version(["sbt", "--script-version"]),
        "vivado": _version(["vivado", "-version"]),
        "legacy_config": legacy_config,
    }
