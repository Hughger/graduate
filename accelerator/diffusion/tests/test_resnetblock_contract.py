import numpy as np
import pytest

from sd_accel.resnetblock import resnetblock_int


def test_resnetblock_rejects_projection_weights() -> None:
    values = np.zeros((1, 32, 2, 2), dtype=np.int16)
    affine = np.zeros(32, dtype=np.int16)
    projection = np.zeros((16, 32, 3, 3), dtype=np.int8)
    square = np.zeros((32, 32, 3, 3), dtype=np.int8)

    with pytest.raises(ValueError, match="Cin == Cout"):
        resnetblock_int(
            values,
            gamma1=affine,
            beta1=affine,
            conv1_weight=projection,
            temb=np.zeros((1, 32), dtype=np.int16),
            gamma2=affine,
            beta2=affine,
            conv2_weight=square,
        )
