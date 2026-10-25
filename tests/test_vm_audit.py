#!/usr/bin/env python3
"""Unit tests for host VM configuration analysis (no Proxmox needed)."""
import importlib.util
import pathlib
import unittest

path = pathlib.Path(__file__).resolve().parents[1] / "scripts" / "pve-vm-audit.py"
spec = importlib.util.spec_from_file_location("pve_vm_audit", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class VMConfigTests(unittest.TestCase):
    def test_windows_config(self):
        data = module.inspect_config("""ostype: win11
bios: ovmf
efidisk0: local-lvm:vm-101-disk-0
tpmstate0: local-lvm:vm-101-disk-1,version=v2.0
net0: virtio=00:11:22:33:44:55,bridge=vmbr0
virtio0: local-lvm:vm-101-disk-2
smbios1: uuid=test
""")
        self.assertTrue(data["windows_guest"])
        self.assertEqual(data["virtio_net_adapters"], ["net0"])
        self.assertEqual(data["virtio_disk_adapters"], ["virtio0"])
        self.assertEqual(data["findings"], [])

    def test_missing_security_configuration(self):
        data = module.inspect_config("ostype: win11\nnet0: e1000=00:11:22:33:44:55\n")
        self.assertEqual(len(data["findings"]), 4)
        self.assertEqual(data["virtio_net_adapters"], [])

    def test_comment_and_untrusted_custom_args(self):
        data = module.inspect_config("# args: fake\nargs: -cpu host\n")
        self.assertTrue(data["custom_qemu_args"])
        self.assertEqual(data["findings"][-1], "Custom QEMU args require manual compatibility review")

if __name__ == "__main__":
    unittest.main()
