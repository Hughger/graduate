"""Reference W8A8 3x3 convolution with explicit INT32 accumulator checks."""

from __future__ import annotations

import numpy as np

from .fixedpoint import requantize, saturate_signed


def _per_output_channel(value: int | np.ndarray, channels: int) -> np.ndarray:
    values = np.asarray(value, dtype=np.int64)
    if values.ndim == 0:
        return values
    if values.shape != (channels,):
        raise ValueError("per-output-channel parameter must have shape [Cout]")
    return values.reshape(1, channels, 1, 1)


def conv3x3_int8(
    x: np.ndarray,
    weight: np.ndarray,
    *,
    bias: np.ndarray | None = None,
    multiplier: int | np.ndarray = 1,
    shift: int = 0,
    output_bits: int = 16,
) -> np.ndarray:
    """Run stride-1, padding-1 W8A8 convolution and requantize its INT32 sum."""
    values = np.asarray(x, dtype=np.int64)
    weights = np.asarray(weight, dtype=np.int64)
    if values.ndim != 4 or weights.ndim != 4 or weights.shape[2:] != (3, 3):
        raise ValueError("expected NCHW input and [Cout, Cin, 3, 3] weights")
    batch, channels_in, height, width = values.shape
    channels_out, weight_channels, _, _ = weights.shape
    if weight_channels != channels_in:
        raise ValueError("input and weight Cin must match")
    if np.any(weights < -128) or np.any(weights > 127):
        raise ValueError("weights must be signed INT8")
    activations = saturate_signed(values, 8)
    padded = np.pad(activations, ((0, 0), (0, 0), (1, 1), (1, 1)))
    accumulator = np.zeros((batch, channels_out, height, width), dtype=np.int64)
    for row in range(3):
        for column in range(3):
            accumulator += np.einsum(
                "nchw,oc->nohw",
                padded[:, :, row : row + height, column : column + width],
                weights[:, :, row, column],
                dtype=np.int64,
            )
    if bias is not None:
        bias_values = np.asarray(bias, dtype=np.int64)
        if bias_values.shape != (channels_out,):
            raise ValueError("bias must have shape [Cout]")
        accumulator += bias_values.reshape(1, channels_out, 1, 1)
    int32_min = -(1 << 31)
    int32_max = (1 << 31) - 1
    if accumulator.min() < int32_min or accumulator.max() > int32_max:
        raise OverflowError("W8A8 convolution accumulator exceeds signed INT32")
    quantized = requantize(
        accumulator, _per_output_channel(multiplier, channels_out), shift, output_bits
    )
    return quantized.astype(np.int16 if output_bits == 16 else np.int8)
