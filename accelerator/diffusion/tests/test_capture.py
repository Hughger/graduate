from pathlib import Path

from sd_accel.manifest import CaptureManifest


def test_manifest_round_trip(tmp_path: Path) -> None:
    item = CaptureManifest(
        "local-sd15",
        "down_blocks.0.resnets.1",
        500,
        921,
        (1, 320, 64, 64),
        (1, 320, 64, 64),
        "float16",
    )
    path = tmp_path / "manifest.json"
    item.save(path)
    assert CaptureManifest.load(path) == item
