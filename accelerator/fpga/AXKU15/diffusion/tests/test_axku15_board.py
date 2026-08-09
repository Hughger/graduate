from __future__ import annotations

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "extract_ddr4_pins", ROOT / "scripts" / "extract_ddr4_pins.py"
)
assert SPEC and SPEC.loader
pins = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(pins)


class Axku15BoardTest(unittest.TestCase):
    def test_manual_has_complete_unique_80_bit_ddr4_bus(self) -> None:
        mapping = pins.read_pins(pins.MANUAL)
        self.assertEqual(len([name for name in mapping if name.startswith("D") and name[1:].isdigit()]), 80)
        self.assertEqual(mapping["D0"], "AJ28")
        self.assertEqual(mapping["D79"], "AW35")
        self.assertEqual(mapping["CLKREF_P"], "AR32")
        self.assertEqual(mapping["CLKREF_N"], "AT32")

    def test_rendered_xdc_covers_dq_dm_dqs_and_control(self) -> None:
        rendered = pins.render_xdc(pins.read_pins(pins.MANUAL))
        self.assertEqual(rendered.count("ddr4_dq["), 80)
        self.assertEqual(rendered.count("ddr4_dm_dbi_n["), 10)
        self.assertEqual(rendered.count("ddr4_dqs_p["), 10)
        self.assertEqual(rendered.count("ddr4_dqs_n["), 10)
        self.assertIn("PACKAGE_PIN AR34 [get_ports {ddr4_ck_t[0]}]", rendered)
        self.assertIn("PACKAGE_PIN AR32 [get_ports {ddr4_ref_clk_p}]", rendered)
        self.assertIn("PACKAGE_PIN AT32 [get_ports {ddr4_ref_clk_n}]", rendered)