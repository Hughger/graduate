import numpy as np

from sd_accel.fixedpoint import requantize, round_shift_away_from_zero, saturate_signed


def test_fixed_boundaries() -> None:
    values = np.array([-40000, -32768, 32767, 40000], dtype=np.int64)
    np.testing.assert_array_equal(
        saturate_signed(values, 16), [-32768, -32768, 32767, 32767]
    )
    np.testing.assert_array_equal(
        round_shift_away_from_zero(np.array([-7, -5, 5, 7]), 1), [-4, -3, 3, 4]
    )


def test_requantize_rounds_then_saturates() -> None:
    values = np.array([-500, -3, 3, 500], dtype=np.int64)
    np.testing.assert_array_equal(requantize(values, 3, 1, 8), [-128, -5, 5, 127])
