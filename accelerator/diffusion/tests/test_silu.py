import hashlib
from pathlib import Path
import subprocess
import sys

import numpy as np

from sd_accel.resnet_ops import add_time_embedding_int16
from sd_accel.silu import silu_pwl_int16


def test_silu_is_zero_at_zero_monotonic_and_saturating() -> None:
    values = np.arange(-4096, 4097, dtype=np.int16)
    output = silu_pwl_int16(values, segments=16)

    assert output[4096] == 0
    assert np.all(np.diff(output.astype(np.int32)) >= 0)
    assert output.min() >= -32768
    assert output.max() <= 32767


def test_time_embedding_broadcasts_and_saturates() -> None:
    values = np.zeros((1, 2, 2, 2), dtype=np.int16)
    temb = np.array([[7, -9]], dtype=np.int16)
    np.testing.assert_array_equal(
        add_time_embedding_int16(values, temb),
        np.array([[[[7, 7], [7, 7]], [[-9, -9], [-9, -9]]]], dtype=np.int16),
    )
    saturated = add_time_embedding_int16(
        np.full((1, 2, 1, 1), 32767, dtype=np.int16),
        np.ones((1, 2), dtype=np.int16),
    )
    np.testing.assert_array_equal(saturated, np.full((1, 2, 1, 1), 32767, dtype=np.int64))


def test_silu_generator_is_deterministic(tmp_path: Path) -> None:
    script = Path(__file__).parents[1] / "scripts" / "generate_silu_coeffs.py"
    first = tmp_path / "first"
    second = tmp_path / "second"
    for destination in (first, second):
        subprocess.run([sys.executable, str(script), "--output-dir", str(destination)], check=True)

    names = ("silu_pwl_16.json", "silu_pwl_32.json", "SiluCoeffs.scala")
    for name in names:
        assert hashlib.sha256((first / name).read_bytes()).digest() == hashlib.sha256(
            (second / name).read_bytes()
        ).digest()
