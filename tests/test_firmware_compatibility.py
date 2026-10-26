import importlib.util
import unittest
from pathlib import Path

src = Path(__file__).resolve().parents[1] / "diagnostics/host/firmware-compatibility.py"
spec = importlib.util.spec_from_file_location("firmware_compatibility", src)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

class CompatibilityTests(unittest.TestCase):
    def test_good_windows_profile(self):
        cfg = mod.parse_qm("ostype: win11\nbios: ovmf\nmachine: q35\ncpu: host\nefidisk0: local:1\ntpmstate0: local:2,version=v2.0\n")
        self.assertEqual(mod.evaluate(cfg), [])

    def test_missing_firmware_and_tpm(self):
        cfg = mod.parse_qm("ostype: win11\nmachine: i440fx\ncpu: qemu64\n")
        findings = mod.evaluate(cfg)
        self.assertTrue(any("OVMF" in x for x in findings))
        self.assertTrue(any("TPM" in x for x in findings))
        self.assertTrue(any("EFI" in x for x in findings))

    def test_raw_arguments_flagged(self):
        cfg = mod.parse_qm("bios: ovmf\nmachine: q35\ncpu: host\nefidisk0: x\nargs: -cpu host\n")
        self.assertTrue(any("Raw QEMU" in x for x in mod.evaluate(cfg)))

if __name__ == "__main__":
    unittest.main()
