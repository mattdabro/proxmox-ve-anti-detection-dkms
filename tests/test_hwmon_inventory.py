#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path

MOD = Path(__file__).resolve().parents[1] / "diagnostics" / "host" / "hwmon-inventory.py"
spec = importlib.util.spec_from_file_location("hwmon_inventory", MOD)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class HwmonTests(unittest.TestCase):
    def test_scales_and_labels(self):
        with tempfile.TemporaryDirectory() as tmp:
            dev = Path(tmp) / "hwmon0"
            dev.mkdir()
            for name, value in {
                "name": "test-chip", "temp1_input": "45321",
                "temp1_label": "CPU Package", "fan1_input": "1250",
                "in1_input": "12123", "in1_label": "+12V",
            }.items():
                (dev / name).write_text(value)
            sensors = module.gather(Path(tmp))[0]["sensors"]
            indexed = {s["channel"]: s for s in sensors}
            self.assertEqual(indexed["temp1"]["value"], 45.321)
            self.assertEqual(indexed["fan1"]["value"], 1250)
            self.assertEqual(indexed["in1"]["value"], 12.123)
            self.assertEqual(indexed["temp1"]["label"], "CPU Package")

    def test_invalid_or_missing_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            dev = Path(tmp) / "hwmon1"
            dev.mkdir()
            (dev / "name").write_text("broken")
            (dev / "fan1_input").write_text("not a number")
            self.assertEqual(module.gather(Path(tmp)), [])

if __name__ == "__main__":
    unittest.main()
