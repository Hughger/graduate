import json
from pathlib import Path

from sd_accel.capture import _resolve_module


class _Tree:
    def __init__(self) -> None:
        self.layers = ["first", "second"]


def test_resolve_module_indexes_numeric_path_components() -> None:
    assert _resolve_module(_Tree(), "layers.1") == "second"


def test_sd15_capture_config_has_expected_contract() -> None:
    config_path = Path(__file__).parents[1] / "config" / "sd15_resnetblock.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))

    assert config["activation_layout"] == "NCHW"
    assert config["group_norm_groups"] == 32
    assert config["capture"] == {
        "dtype": "float16",
        "timestep": 500,
        "seed": 921,
        "local_files_only": True,
    }
