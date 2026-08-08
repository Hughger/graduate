import numpy as np

from sd_accel.layout import blocked32_to_nchw, nchw_to_blocked32


def test_blocked32_round_trip_for_required_shapes() -> None:
    for shape in ((1, 320, 64, 64), (1, 640, 32, 32), (1, 1280, 16, 16), (1, 1280, 8, 8)):
        source = np.arange(np.prod(shape), dtype=np.int32).reshape(shape)
        blocked = nchw_to_blocked32(source)
        assert blocked.shape == (shape[0], shape[1] // 32, shape[2], shape[3], 32)
        np.testing.assert_array_equal(blocked32_to_nchw(blocked, shape[1]), source)


def test_blocked32_zeroes_padded_lanes() -> None:
    source = np.ones((1, 33, 2, 2), dtype=np.int8)
    blocked = nchw_to_blocked32(source)

    assert blocked.shape == (1, 2, 2, 2, 32)
    assert np.count_nonzero(blocked[:, 1, :, :, 1:]) == 0
    np.testing.assert_array_equal(blocked32_to_nchw(blocked, 33), source)
