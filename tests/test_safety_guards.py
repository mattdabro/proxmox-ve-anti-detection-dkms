#!/usr/bin/env python3
"""Regression checks for dangerous build and install fallbacks.

These tests are static checks, not a substitute for a Proxmox integration test.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / "scripts/pve-qemu-anti-detection").read_text()

class SafetyTests(unittest.TestCase):
    def test_no_forced_package_install(self):
        self.assertNotIn("dpkg -i --force-all", SCRIPT)

    def test_no_checkout_of_latest_on_version_mismatch(self):
        self.assertIn('No source revision matching', SCRIPT)
        self.assertNotIn('using latest commit', SCRIPT)

    def test_build_errors_stop_installation(self):
        self.assertIn('Refusing to install potentially stale artifacts', SCRIPT)

    def test_failed_dependencies_stop_build(self):
        self.assertIn('Could not install build dependencies; aborting', SCRIPT)

    def test_failed_package_upgrade_stops_rebuild(self):
        self.assertIn('Package upgrade failed; refusing to rebuild', SCRIPT)

    def test_mutating_commands_take_lock(self):
        for command in ("install", "rebuild", "upgrade"):
            self.assertIn(f'    {command})\n        acquire_lock', SCRIPT)
        self.assertIn('flock -n 9', SCRIPT)

if __name__ == "__main__":
    unittest.main()
