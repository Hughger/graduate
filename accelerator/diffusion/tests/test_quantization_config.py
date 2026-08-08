import json
from pathlib import Path


def test_quantization_and_layout_contract_is_locked() -> None:
    config_path = Path(__file__).parents[1] / "config" / "sd15_resnetblock.json"
    config = json.loads(config_path.read_text(encoding="utf-8"))

    assert config["layout"] == {"tensor": "[N,Cb,H,W,32]", "channel_block": 32}
    assert config["quantization"] == {
        "activation_zero_point": 0,
        "weight_zero_point": 0,
        "weight_scale": "per_output_channel",
        "activation_scale": "per_stage",
        "accumulator_dtype": "int32",
        "intermediate_dtype": "int16",
        "rounding": "away_from_zero",
    }
