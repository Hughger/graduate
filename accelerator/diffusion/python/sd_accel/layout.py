"""Channel-blocked tensor layouts shared by the host model and RTL vectors."""

from __future__ import annotations

import numpy as np


CHANNEL_BLOCK = 32


def nchw_to_blocked32(x: np.ndarray) -> np.ndarray:
    """Convert NCHW to ``[N, Cb, H, W, 32]`` with zero-filled tail lanes."""
    values = np.asarray(x)
    if values.ndim != 4:
        raise ValueError(f"expected NCHW rank 4, got rank {values.ndim}")
    batch, channels, height, width = values.shape
    channel_blocks = (channels + CHANNEL_BLOCK - 1) // CHANNEL_BLOCK
    padded = np.zeros((batch, channel_blocks * CHANNEL_BLOCK, height, width), dtype=values.dtype)
    padded[:, :channels] = values
    return padded.reshape(batch, channel_blocks, CHANNEL_BLOCK, height, width).transpose(0, 1, 3, 4, 2)


def blocked32_to_nchw(x: np.ndarray, channels: int) -> np.ndarray:
    """Convert ``[N, Cb, H, W, 32]`` back to its unpadded NCHW tensor."""
    values = np.asarray(x)
    if values.ndim != 5 or values.shape[-1] != CHANNEL_BLOCK:
        raise ValueError("expected [N, Cb, H, W, 32] blocked tensor")
    if not 0 < channels <= values.shape[1] * CHANNEL_BLOCK:
        raise ValueError("channels must select one or more available blocked lanes")
    batch, channel_blocks, height, width, _ = values.shape
    nchw = values.transpose(0, 1, 4, 2, 3).reshape(
        batch, channel_blocks * CHANNEL_BLOCK, height, width
    )
    return nchw[:, :channels]
