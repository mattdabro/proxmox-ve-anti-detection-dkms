#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1] / "inject-build-rule.py"
spec = importlib.util.spec_from_file_location("inject_build_rule", MODULE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

class BuildRuleTests(unittest.TestCase):
    def test_inserts_once_and_preserves_make_recipe(self):
        with tempfile.TemporaryDirectory() as temp:
            rules = Path(temp) / "rules"
            overlay = Path(temp) / "installer"
            overlay.write_text("#!/bin/sh\n")
            rules.write_text("all:\n\tpatch -p1 < /tmp/qemu.patch\n\t./configure\n")
            mod.inject(rules, "/tmp/qemu.patch", overlay)
            mod.inject(rules, "/tmp/qemu.patch", overlay)
            result = rules.read_text()
            self.assertEqual(result.count(str(overlay) + " ."), 1)
            self.assertLess(result.index("patch -p1"), result.index(str(overlay)))
            self.assertLess(result.index(str(overlay)), result.index("./configure"))

    def test_rejects_missing_patch_rule(self):
        with tempfile.TemporaryDirectory() as temp:
            rules = Path(temp) / "rules"
            rules.write_text("all:\n\t./configure\n")
            with self.assertRaises(ValueError):
                mod.inject(rules, "/tmp/unknown.patch", Path(temp) / "installer")

    def test_rejects_multiple_patch_rules(self):
        with tempfile.TemporaryDirectory() as temp:
            rules = Path(temp) / "rules"
            rules.write_text("all:\n\tpatch -p1 < /tmp/qemu.patch\n\tpatch -p1 < /tmp/qemu.patch\n")
            with self.assertRaises(ValueError):
                mod.inject(rules, "/tmp/qemu.patch", Path(temp) / "installer")

if __name__ == "__main__":
    unittest.main()
