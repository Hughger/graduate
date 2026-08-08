"""Canonical integer arithmetic used by the diffusion reference model and RTL."""

from __future__ import annotations

import numpy as np


def saturate_signed(x: np.ndarray | int, bits: int) -> np.ndarray:
    """Clamp values to the signed integer range represented by ``bits``."""
    if bits < 2:
        raise ValueError("signed saturation requires at least two bits")
    values = np.asarray(x, dtype=np.int64)
    return np.clip(values, -(1 << (bits - 1)), (1 << (bits - 1)) - 1)


def round_shift_away_from_zero(x: np.ndarray | int, shift: int) -> np.ndarray:
    """Arithmetic right shift with half values rounded away from zero."""
    if shift < 0:
        raise ValueError("shift must be non-negative")
    values = np.asarray(x, dtype=np.int64)
    if shift == 0:
        return values
    rounded_abs = (np.abs(values) + (1 << (shift - 1))) >> shift
    return np.where(values < 0, -rounded_abs, rounded_abs)


def requantize(
    x: np.ndarray | int, multiplier: np.ndarray | int, shift: int, bits: int
) -> np.ndarray:
    """Scale, canonically round, and saturate an integer tensor."""
    product = np.asarray(x, dtype=np.int64) * np.asarray(multiplier, dtype=np.int64)
    return saturate_signed(round_shift_away_from_zero(product, shift), bits)
