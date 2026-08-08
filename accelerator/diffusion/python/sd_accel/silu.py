"""Deterministic integer SiLU piecewise-linear approximation."""

from __future__ import annotations

import math
from typing import Any

import numpy as np

from .fixedpoint import round_shift_away_from_zero, saturate_signed


INPUT_FRACTION_BITS = 8
SLOPE_FRACTION_BITS = 16
DOMAIN_LIMIT_Q8 = 8 << INPUT_FRACTION_BITS
_SILU_MINIMUM_X = -1.278_464_542_761_073_7


def _round_away(value: float) -> int:
    return math.floor(value + 0.5) if value >= 0 else math.ceil(value - 0.5)


def _silu(value: float) -> float:
    return value / (1.0 + math.exp(-value))


_SILU_MINIMUM = _silu(_SILU_MINIMUM_X)


def _monotonic_silu(value: float) -> float:
    return _SILU_MINIMUM if value <= _SILU_MINIMUM_X else _silu(value)


def build_coefficients(segments: int) -> dict[str, Any]:
    """Build uniform Q8/Q16 PWL coefficients without model-dependent state."""
    if segments not in (16, 32):
        raise ValueError("only 16- and 32-segment SiLU tables are supported")
    width = (2 * DOMAIN_LIMIT_Q8) // segments
    coefficients: list[dict[str, int]] = []
    prior_last: int | None = None
    for index in range(segments):
        start = -DOMAIN_LIMIT_Q8 + index * width
        end = start + width
        start_real = start / float(1 << INPUT_FRACTION_BITS)
        end_real = end / float(1 << INPUT_FRACTION_BITS)
        start_value = _monotonic_silu(start_real)
        end_value = _monotonic_silu(end_real)
        slope = (end_value - start_value) / (end_real - start_real)
        slope_q16 = _round_away(slope * (1 << SLOPE_FRACTION_BITS))
        start_output = _round_away(start_value * (1 << INPUT_FRACTION_BITS))
        if prior_last is not None:
            start_output = max(start_output, prior_last)
        intercept_q8 = start_output - int(
            round_shift_away_from_zero(slope_q16 * start, SLOPE_FRACTION_BITS)
        )
        prior_last = int(
            round_shift_away_from_zero(slope_q16 * (end - 1), SLOPE_FRACTION_BITS)
        ) + intercept_q8
        coefficients.append(
            {
                "start_q8": start,
                "end_q8": end,
                "slope_q16": slope_q16,
                "intercept_q8": intercept_q8,
            }
        )
    return {
        "segments": segments,
        "input_fraction_bits": INPUT_FRACTION_BITS,
        "output_fraction_bits": INPUT_FRACTION_BITS,
        "slope_fraction_bits": SLOPE_FRACTION_BITS,
        "domain_limit_q8": DOMAIN_LIMIT_Q8,
        "negative_output_cap_q8": 0,
        "coefficients": coefficients,
    }


def silu_pwl_int16(x: np.ndarray | int, *, segments: int = 16) -> np.ndarray:
    """Approximate Q8 SiLU using canonical PWL coefficients and INT16 saturation."""
    values = np.asarray(x, dtype=np.int64)
    table = build_coefficients(segments)
    coefficients = table["coefficients"]
    output = np.empty(values.shape, dtype=np.int64)
    lower = coefficients[0]
    output.fill(
        int(
            round_shift_away_from_zero(
                lower["slope_q16"] * lower["start_q8"], SLOPE_FRACTION_BITS
            )
            + lower["intercept_q8"]
        )
    )
    for coefficient in coefficients:
        mask = (values >= coefficient["start_q8"]) & (values < coefficient["end_q8"])
        output[mask] = (
            round_shift_away_from_zero(
                values[mask] * coefficient["slope_q16"], SLOPE_FRACTION_BITS
            )
            + coefficient["intercept_q8"]
        )
    output[values >= coefficients[-1]["end_q8"]] = values[
        values >= coefficients[-1]["end_q8"]
    ]
    non_positive = values <= 0
    output[non_positive] = np.minimum(
        output[non_positive], int(table["negative_output_cap_q8"])
    )
    return saturate_signed(output, 16).astype(np.int16)
