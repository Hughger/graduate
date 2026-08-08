"""Integer GroupNorm reference with a Q2.30 reciprocal-square-root path."""

from __future__ import annotations

import math
from typing import Any

import numpy as np

from .fixedpoint import round_shift_away_from_zero, saturate_signed


Q30 = 1 << 30
_INV_SQRT2_Q30 = 759_250_125
_MANTISSA_LUT_Q30 = tuple(
    int(math.floor((Q30 / math.sqrt(1.0 + (index + 0.5) / 256.0)) + 0.5))
    for index in range(256)
)


def _divide_round_away_from_zero(numerator: int, denominator: int) -> int:
    if denominator <= 0:
        raise ValueError("denominator must be positive")
    magnitude = (abs(numerator) + denominator // 2) // denominator
    return -magnitude if numerator < 0 else magnitude


def _rsqrt_scalar_q30(value: int, epsilon: int) -> int:
    scaled = max(0, value) + epsilon
    exponent = scaled.bit_length() - 1
    mantissa_q31 = (
        scaled << (31 - exponent)
        if exponent <= 31
        else scaled >> (exponent - 31)
    )
    index = min(255, (mantissa_q31 - (1 << 31)) >> 23)
    estimate = _MANTISSA_LUT_Q30[index]

    for _ in range(2):
        square_q30 = (estimate * estimate + (1 << 29)) >> 30
        product_q31 = (mantissa_q31 * square_q30 + (1 << 29)) >> 30
        factor_q30 = (3 << 29) - ((product_q31 + 2) >> 2)
        estimate = (estimate * factor_q30 + (1 << 29)) >> 30

    if exponent & 1:
        estimate = (estimate * _INV_SQRT2_Q30 + (1 << 29)) >> 30
    shift = exponent // 2
    return (estimate + (1 << (shift - 1))) >> shift if shift else estimate


def rsqrt_q30(x: np.ndarray | int, epsilon: int = 1) -> np.ndarray:
    """Return ``1 / sqrt(max(x, 0) + epsilon)`` in unsigned Q2.30."""
    if epsilon <= 0:
        raise ValueError("epsilon must be positive")
    values = np.asarray(x, dtype=np.int64)
    output = np.empty(values.shape, dtype=np.int64)
    for index, value in np.ndenumerate(values):
        output[index] = _rsqrt_scalar_q30(int(value), epsilon)
    return output


def groupnorm_int16(
    x: np.ndarray,
    gamma: np.ndarray,
    beta: np.ndarray,
    *,
    groups: int = 32,
    epsilon: int = 1,
    affine_shift: int = 8,
    trace: bool = False,
) -> np.ndarray | tuple[np.ndarray, dict[str, Any]]:
    """Apply NCHW GroupNorm using integer statistics and INT16 saturation."""
    values = np.asarray(x, dtype=np.int64)
    if values.ndim != 4:
        raise ValueError("GroupNorm expects an NCHW rank-4 tensor")
    batch, channels, height, width = values.shape
    if groups <= 0 or channels % groups:
        raise ValueError("groups must divide the channel count")
    if affine_shift < 0:
        raise ValueError("affine_shift must be non-negative")
    gamma_values = np.asarray(gamma, dtype=np.int64)
    beta_values = np.asarray(beta, dtype=np.int64)
    if gamma_values.shape != (channels,) or beta_values.shape != (channels,):
        raise ValueError("gamma and beta must have one value per channel")

    channels_per_group = channels // groups
    output = np.empty_like(values)
    sums = np.empty((batch, groups), dtype=np.int64)
    sum_squares = np.empty((batch, groups), dtype=np.int64)
    means = np.empty((batch, groups), dtype=np.int64)
    variances = np.empty((batch, groups), dtype=np.int64)
    inverse_stddev = np.empty((batch, groups), dtype=np.int64)
    count = channels_per_group * height * width

    for batch_index in range(batch):
        for group_index in range(groups):
            first = group_index * channels_per_group
            last = first + channels_per_group
            group = values[batch_index, first:last]
            total = int(group.sum(dtype=np.int64))
            total_squares = int((group * group).sum(dtype=np.int64))
            mean = _divide_round_away_from_zero(total, count)
            variance = max(0, _divide_round_away_from_zero(total_squares, count) - mean * mean)
            inverse = int(rsqrt_q30(variance, epsilon))
            centered = group - mean
            normalized = round_shift_away_from_zero(centered * inverse, 30)
            affine = round_shift_away_from_zero(
                normalized * gamma_values[first:last, None, None], affine_shift
            ) + beta_values[first:last, None, None]
            output[batch_index, first:last] = saturate_signed(affine, 16)
            sums[batch_index, group_index] = total
            sum_squares[batch_index, group_index] = total_squares
            means[batch_index, group_index] = mean
            variances[batch_index, group_index] = variance
            inverse_stddev[batch_index, group_index] = inverse

    result = output.astype(np.int16)
    if not trace:
        return result
    return result, {
        "sum": sums,
        "sum_square": sum_squares,
        "mean": means,
        "variance": variances,
        "rsqrt_q30": inverse_stddev,
    }
