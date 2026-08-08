"""Immutable metadata for a captured SD1.5 ResNetBlock invocation."""

from __future__ import annotations

from dataclasses import asdict, dataclass
import json
from pathlib import Path


@dataclass(frozen=True)
class CaptureManifest:
    model_id: str
    block_path: str
    timestep: int
    seed: int
    input_shape: tuple[int, ...]
    output_shape: tuple[int, ...]
    dtype: str

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(asdict(self), indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    @classmethod
    def load(cls, path: Path) -> "CaptureManifest":
        data = json.loads(path.read_text(encoding="utf-8"))
        data["input_shape"] = tuple(data["input_shape"])
        data["output_shape"] = tuple(data["output_shape"])
        return cls(**data)
