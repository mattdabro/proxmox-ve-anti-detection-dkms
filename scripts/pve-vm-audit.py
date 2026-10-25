#!/usr/bin/env python3
"""Read-only audit of Proxmox VM configuration and hardware compatibility."""
import argparse
import json
import re
import subprocess
from pathlib import Path

def run(*args):
    p = subprocess.run(args, capture_output=True, text=True, timeout=15, check=False)
    return {"ok": p.returncode == 0, "output": p.stdout.strip(), "error": p.stderr.strip()}

def inspect_config(text):
    fields = {}
    for line in text.splitlines():
        if ":" in line and not line.lstrip().startswith("#"):
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip()
    net = {k: v for k, v in fields.items() if re.fullmatch(r"net\d+", k)}
    disks = {k: v for k, v in fields.items() if re.fullmatch(r"(scsi|virtio|sata|ide)\d+", k)}
    is_windows = fields.get("ostype", "").startswith("win")
    return {
        "windows_guest": is_windows,
        "cpu": fields.get("cpu", ""),
        "bios": fields.get("bios", "seabios"),
        "machine": fields.get("machine", ""),
        "tpmstate0": fields.get("tpmstate0", ""),
        "efidisk0": fields.get("efidisk0", ""),
        "smbios1_configured": "smbios1" in fields,
        "virtio_net_adapters": sorted(k for k, v in net.items() if "virtio" in v.lower()),
        "virtio_disk_adapters": sorted(k for k in disks if k.startswith("virtio")),
        "scsi_controller": fields.get("scsihw", ""),
        "hostpci_devices": sorted(k for k in fields if k.startswith("hostpci")),
        "custom_qemu_args": "args" in fields,
        "findings": [
            *([] if fields.get("bios") == "ovmf" else ["OVMF UEFI firmware is not selected"]),
            *([] if not is_windows or "tpmstate0" in fields else ["Windows guest has no configured virtual TPM"]),
            *([] if not is_windows or "efidisk0" in fields else ["Windows guest has no EFI variables disk"]),
            *([] if "smbios1" in fields else ["SMBIOS Type 1 is not explicitly configured; QEMU/PVE defaults apply"]),
            *([] if "args" not in fields else ["Custom QEMU args require manual compatibility review"]),
        ],
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("vmid", type=int, help="Proxmox VM ID")
    parser.add_argument("--output", help="Save JSON report to this file")
    args = parser.parse_args()
    if not 100 <= args.vmid <= 999999999:
        parser.error("VM ID out of range")
    q = run("qm", "config", str(args.vmid))
    if not q["ok"]:
        parser.exit(1, "Unable to read VM configuration: " + q["error"] + "\n")
    result = {"vmid": args.vmid, "config": inspect_config(q["output"])}
    result["host"] = {
        "pveversion": run("pveversion")["output"],
        "kvm_module": Path("/sys/module/kvm").exists(),
        "cpu_vmx_or_svm": bool(re.search(r"\b(vmx|svm)\b", Path("/proc/cpuinfo").read_text(errors="replace"))),
    }
    data = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        Path(args.output).write_text(data)
    else:
        print(data, end="")

if __name__ == "__main__":
    main()
