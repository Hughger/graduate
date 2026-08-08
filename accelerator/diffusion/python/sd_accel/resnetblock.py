"""Integer SD1.5 equal-channel ResNetBlock reference sequence."""

from __future__ import annotations

from typing import Any

import numpy as np

from .conv import conv3x3_int8
from .fixedpoint import saturate_signed
from .groupnorm import groupnorm_int16
from .resnet_ops import add_time_embedding_int16
from .silu import silu_pwl_int16


def resnetblock_int(
    x: np.ndarray,
    *,
    gamma1: np.ndarray,
    beta1: np.ndarray,
    conv1_weight: np.ndarray,
    temb: np.ndarray,
    gamma2: np.ndarray,
    beta2: np.ndarray,
    conv2_weight: np.ndarray,
    conv1_bias: np.ndarray | None = None,
    conv2_bias: np.ndarray | None = None,
    conv1_multiplier: int | np.ndarray = 1,
    conv2_multiplier: int | np.ndarray = 1,
    conv1_shift: int = 0,
    conv2_shift: int = 0,
    groups: int = 32,
    trace: bool = False,
) -> np.ndarray | tuple[np.ndarray, dict[str, Any]]:
    """Execute GN1→SiLU→Conv1→time→GN2→SiLU→Conv2→residual in integers."""
    residual = np.asarray(x, dtype=np.int16)
    if residual.ndim != 4:
        raise ValueError("input must be an NCHW tensor")
    channels = residual.shape[1]
    for weight in (np.asarray(conv1_weight), np.asarray(conv2_weight)):
        if weight.shape != (channels, channels, 3, 3):
            raise ValueError("this first-stage model requires Cin == Cout 3x3 weights")

    gn1 = groupnorm_int16(residual, gamma1, beta1, groups=groups)
    silu1 = silu_pwl_int16(gn1)
    conv1 = conv3x3_int8(
        silu1,
        conv1_weight,
        bias=conv1_bias,
        multiplier=conv1_multiplier,
        shift=conv1_shift,
    )
    timed = add_time_embedding_int16(conv1, temb)
    gn2 = groupnorm_int16(timed, gamma2, beta2, groups=groups)
    silu2 = silu_pwl_int16(gn2)
    conv2 = conv3x3_int8(
        silu2,
        conv2_weight,
        bias=conv2_bias,
        multiplier=conv2_multiplier,
        shift=conv2_shift,
    )
    output = saturate_signed(conv2.astype(np.int64) + residual.astype(np.int64), 16).astype(
        np.int16
    )
    if not trace:
        return output
    return output, {
        "gn1": gn1,
        "silu1": silu1,
        "conv1": conv1,
        "time": timed,
        "gn2": gn2,
        "silu2": silu2,
        "conv2": conv2,
        "residual": residual,
        "output": output,
    }
