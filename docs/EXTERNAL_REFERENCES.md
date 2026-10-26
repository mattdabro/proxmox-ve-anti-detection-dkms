# External reference integration review

This project was compared with the following public resources. These links are
**references**, not vendored code or endorsements of bypass claims.

| Reference | Applicable engineering insight | Disposition |
|---|---|---|
| https://github.com/AICodo/pve-emu-realpc | QEMU packaging and machine profile considerations | Use source/version checks; do not install prebuilt binaries |
| https://github.com/AICodo/pve-emu-realpc_edk2-firmware-ovmf | Separate OVMF firmware build pipeline | Validate package version and firmware signatures |
| https://github.com/CloverHackyColor/FakeSMC3_with_plugins | Temperature, voltage, and fan sensor interfaces | macOS kernel extensions not applicable to Windows; retain lab HWMON model |
| https://github.com/KBapna/PVE-QEMU-Anti-Detection-patch | QEMU and EDK2 builds have separate source dependencies | Separate audit and verification phases |
| https://github.com/swiglu/libvirt-stealth | Configurations illustrate interactions between CPU and hypervisor flags | No blind XML-to-qm conversion |
| https://forums.unraid.net/topic/198466-complete-2026-guide-windows-11-gaming-vm-with-secure-boot-tpm-20-and-anti-cheat-support-on-unraid-call-of-duty-ricochet-eac-vanguard-battleye/ | Secure Boot, TPM, CPU affinity, and hugepages | Unraid-specific steps require Proxmox adaptation; claims unverified |
| https://github.com/zhaodice/qemu-anti-detection | QEMU patches are bound to upstream release series | Do not combine incompatible patchsets |
| https://github.com/HikaruChang/proxmox-ve-anti-detection-dkms | Original rebuild/package hook | Compare changes against upstream rather than overwriting |

## Added preflight

The read-only `diagnostics/host/firmware-compatibility.py` checks the VM configuration for OVMF, Q35, EFI variables, TPM 2.0, and baseline CPU settings. It can work from an offline `qm config` export or query a VM ID on a Proxmox host.

```bash
python3 diagnostics/host/firmware-compatibility.py --vmid 110
python3 diagnostics/host/firmware-compatibility.py --config-file vm.conf
```

Successful preflight is **not** proof of actual Secure Boot enforcement. Verify from Windows using `Confirm-SecureBootUEFI`, `Get-Tpm`, Device Guard and the existing guest validation scripts.

## Non-adopted changes

No unverified firmware packages, hardware impersonation, RDTSC tampering, or CPUID concealment patches have been imported. Such changes can break Secure Boot/VBS or driver compatibility and have not been demonstrated to improve reliability on the target Proxmox release.

Always validate licensing and preserve original patch attributions before incorporating outside code.
