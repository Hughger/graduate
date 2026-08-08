import numpy as np

from sd_accel.conv import conv3x3_int8
from sd_accel.groupnorm import groupnorm_int16
from sd_accel.resnet_ops import add_time_embedding_int16
from sd_accel.resnetblock import resnetblock_int
from sd_accel.silu import silu_pwl_int16


def _center_identity_weights() -> np.ndarray:
    weights = np.zeros((32, 32, 3, 3), dtype=np.int8)
    for channel in range(32):
        weights[channel, channel, 1, 1] = 1
    return weights


def test_toy_resnetblock_matches_explicit_stage_composition() -> None:
    source = (np.arange(1 * 32 * 4 * 4, dtype=np.int16).reshape(1, 32, 4, 4) % 17) - 8
    gamma = np.full(32, 256, dtype=np.int16)
    beta = np.zeros(32, dtype=np.int16)
    temb = np.zeros((1, 32), dtype=np.int16)
    weights = _center_identity_weights()

    output, trace = resnetblock_int(
        source,
        gamma1=gamma,
        beta1=beta,
        conv1_weight=weights,
        temb=temb,
        gamma2=gamma,
        beta2=beta,
        conv2_weight=weights,
        trace=True,
    )

    gn1 = groupnorm_int16(source, gamma, beta)
    silu1 = silu_pwl_int16(gn1)
    conv1 = conv3x3_int8(silu1, weights)
    timed = add_time_embedding_int16(conv1, temb)
    gn2 = groupnorm_int16(timed, gamma, beta)
    silu2 = silu_pwl_int16(gn2)
    conv2 = conv3x3_int8(silu2, weights)
    expected = np.clip(conv2.astype(np.int64) + source.astype(np.int64), -32768, 32767).astype(np.int16)

    np.testing.assert_array_equal(output, expected)
    assert set(trace) == {"gn1", "silu1", "conv1", "time", "gn2", "silu2", "conv2", "residual", "output"}
    np.testing.assert_array_equal(trace["output"], expected)


def test_conv_rejects_int32_accumulator_overflow() -> None:
    source = np.full((1, 32, 1, 1), 127, dtype=np.int16)
    weights = np.full((1, 32, 3, 3), 127, dtype=np.int8)

    output = conv3x3_int8(source, weights)

    assert output.shape == (1, 1, 1, 1)
    assert output.dtype == np.int16
