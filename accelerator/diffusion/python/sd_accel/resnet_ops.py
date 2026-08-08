"""Integer elementwise operations used by the ResNetBlock reference model."""

from __future__ import annotations

import numpy as np

from .fixedpoint import round_shift_away_from_zero, saturate_signed


def add_time_embedding_int16(
    x: np.ndarray, temb: np.ndarray, *, shift: int = 0
) -> np.ndarray:
    """Broadcast a per-channel time embedding across N/H/W and saturate to INT16."""
    values = np.asarray(x, dtype=np.int64)
    embedding = np.asarray(temb, dtype=np.int64)
    if values.ndim != 4:
        raise ValueError("activation must be an NCHW rank-4 tensor")
    if embedding.shape != values.shape[:2]:
        raise ValueError("time embedding must have shape [N, C]")
    if shift < 0:
        raise ValueError("shift must be non-negative")
    summed = values + embedding[:, :, None, None]
    return saturate_signed(round_shift_away_from_zero(summed, shift), 16).astype(np.int16)
