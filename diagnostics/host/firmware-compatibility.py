#!/usr/bin/env python3
"""Read-only Proxmox QEMU/OVMF compatibility preflight; no patch application."""
import argparse
import json
import re
import subprocess
from pathlib import Path

def run(*argv):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=15, check=False)
        return p.stdout.strip() if p.returncode == 0 else None
    except (OSError, subprocess.TimeoutExpired):
        return None

def parse_qm(text):
    result = {}
    for line in text.splitlines():
        if ":" in line and not line.lstrip().startswith("#"):
            k, v = line.split(":", 1)
            result[k.strip()] = v.strip()
    return result

def evaluate(config):
    findings = []
    if config.get("bios") != "ovmf":
        findings.append("OVMF firmware not selected")
    if not config.get("machine", "").startswith(("q35", "pc-q35")):
        findings.append("Q35 chipset not selected")
    if "efidisk0" not in config:
        findings.append("Persistent EFI variable disk absent")
    if config.get("ostype", "").startswith("win") and "tpmstate0" not in config:
        findings.append("Windows VM has no configured virtual TPM")
    if config.get("ostype", "").startswith("win") and "version=v2.0" not in config.get("tpmstate0", ""):
        findings.append("Windows VM TPM 2.0 configuration not verified")
    if config.get("cpu", "").split(",")[0] != "host":
        findings.append("CPU configuration differs from host passthrough baseline")
    raw = config.get("args", "")
    if raw:
        findings.append("Raw QEMU args present: review duplicate -cpu/-smp/-machine and firmware flags")
    return findings

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--vmid", type=int)
    p.add_argument("--config-file", type=Path, help="Offline input: output of qm config")
    p.add_argument("--output", type=Path)
    args = p.parse_args()
    if (args.vmid is None) == (args.config_file is None):
        p.error("select exactly one of --vmid or --config-file")
    if args.config_file:
        content = args.config_file.read_text()
    else:
        content = run("qm", "config", str(args.vmid))
        if content is None:
            p.error("qm config failed")
    config = parse_qm(content)
    observed = {}
    if args.vmid is not None:
        for package in ("pve-qemu-kvm", "pve-edk2-firmware-ovmf", "pve-edk2-firmware"):
            observed[package] = run("dpkg-query", "-W", "-f=${Version}", package)
        observed["pveversion"] = run("pveversion")
        observed["effective_qemu_command_available"] = run("qm", "showcmd", str(args.vmid), "--pretty") is not None
    report = {"vmid": args.vmid, "packages": observed,
              "selected": {k: config.get(k) for k in ("ostype", "bios", "machine", "cpu", "efidisk0", "tpmstate0")},
              "findings": evaluate(config),
              "limitations": ["Secure Boot enforcement and vTPM attestation must be checked inside the guest.",
                              "Version matching and feature availability require a source-matched build.",
                              "This tool does not claim anti-cheat support or hide virtualization."]}
    payload = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.write_text(payload)
    else:
        print(payload, end="")

if __name__ == "__main__":
    main()
