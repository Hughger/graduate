import numpy as np

from sd_accel.groupnorm import groupnorm_int16, rsqrt_q30


def test_constant_groups_normalize_to_beta() -> None:
    values = np.full((1, 32, 2, 2), 17, dtype=np.int16)
    gamma = np.full(32, 256, dtype=np.int16)
    beta = np.arange(-16, 16, dtype=np.int16)

    output, trace = groupnorm_int16(values, gamma, beta, groups=32, trace=True)

    expected = np.broadcast_to(beta.reshape(1, 32, 1, 1), values.shape)
    np.testing.assert_array_equal(output, expected)
    np.testing.assert_array_equal(trace["variance"], np.zeros((1, 32), dtype=np.int64))
    np.testing.assert_array_equal(trace["rsqrt_q30"], np.full((1, 32), 1 << 30))


def test_variance_is_nonnegative_and_output_saturates() -> None:
    values = np.empty((1, 32, 1, 2), dtype=np.int16)
    values[..., 0] = -32768
    values[..., 1] = 32767
    gamma = np.full(32, 32767, dtype=np.int16)
    beta = np.zeros(32, dtype=np.int16)

    output, trace = groupnorm_int16(values, gamma, beta, groups=32, trace=True)

    assert np.all(trace["variance"] >= 0)
    assert output.min() >= -32768
    assert output.max() <= 32767


def test_rsqrt_q30_matches_integer_inputs() -> None:
    np.testing.assert_array_equal(rsqrt_q30(np.array([0, 3, 15])), [1 << 30, 536870912, 268435456])
