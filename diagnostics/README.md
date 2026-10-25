# Main-project diagnostics integration

Imported from `mattdabro/pve-main-project` into `diagnostics/` to keep these read-only tools separate from QEMU patch installation. The original source repository retains its license and attribution; consult its README for project scope.

## Host tools

On a disposable Proxmox test node, run as root:

```bash
bash diagnostics/host/cpu-audit.sh
bash diagnostics/host/msr-audit.sh
bash diagnostics/host/firmware-audit.sh 110
bash diagnostics/host/timing-audit.sh 110 30
```

Inspect each script before execution and confirm its required host tools. The timing audit attaches `perf` to a running VM and may use `trace-cmd`. These are monitoring operations that can affect measurement overhead.

## Windows tools

Copy `diagnostics/windows/` to the test guest. Open an elevated PowerShell console in that directory:

```powershell
.\Build-NativeTools.ps1
.\Security-Audit.ps1
.\Timer-Audit.ps1
.\Firmware-Acpi-Audit.ps1 -OutputPath firmware-acpi.json
.\cpuid-audit.exe > cpuid.txt
.\tsc-bench.exe > tsc.txt
```

The C utilities need a Windows C compiler supported by the build helper. CPUID output and timing samples are *observations*, not proof of virtualization invisibility. Capture baseline results on a stock QEMU build and repeat under identical host load and affinity.

## Scope

This integration adds CPU/MSR/timing, security, firmware, and ACPI diagnostics; it does **not** bring in the other project's competing QEMU build/deploy scripts, virtual sensor hardware, or management UI. Existing `scripts/pve-qemu-anti-detection` remains the patch installer.

No CPUID concealment hooks, RDTSC manipulation, EFI vendor impersonation or fabricated physical sensors are introduced. Do not use the diagnostics to claim anti-cheat or DRM bypass support.

## Validation

The CI workflow checks syntax and statically verifies required files. It cannot validate real KVM exits, UEFI behavior, or a particular Windows guest; those require host/guest execution. Avoid sharing reports without reviewing hardware identifiers.
