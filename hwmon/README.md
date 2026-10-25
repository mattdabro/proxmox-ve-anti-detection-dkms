# Optional QEMU PCI lab hardware monitor

This is a source-level port of the **explicitly virtual** `pve-lab-hwmon` PCI
device and ACPI SSDT from `mattdabro/pve-main-project`.

The device models:
- CPU and board temperatures in decikelvin;
- CPU and chassis fan speed in RPM;
- fan duty as a percentage;
- CPU Vcore and +12 V / +5 V / +3.3 V rails in millivolts.

The 4 KiB MMIO BAR uses the register addresses defined in
`hwmon/qemu/pve-lab-hwmon.c`. The values are simulated lab telemetry and
**are not physical host readings**. The PCI IDs remain test-device IDs.

## Stage into a matching QEMU checkout

```bash
bash hwmon/install-source-overlay.sh /path/to/pve-qemu/qemu
git -C /path/to/pve-qemu/qemu diff -- hw/misc/meson.build
```

This stages source only. Building a Proxmox QEMU package requires a source-matched
checkout and build process. Existing `pve-qemu-anti-detection` package rebuilds
may reinitialize/clean the upstream submodule and discard this overlay; the
standalone source installer is **not wired into automatic DKMS-like rebuilds**.
Do not assume the installed QEMU binary contains the device until `-device help`
shows `pve-lab-hwmon`.

## ACPI table

```bash
bash hwmon/compile-acpi.sh ./hwmon-build
```

The SSDT assumes `HWM0` is on Q35 root bus at address `1e.0`.
Validate the actual PCI topology and ACPI namespace; using a different
location requires changing and recompiling the DSL.

After **building and installing a compatible custom QEMU binary**, a standalone
lab QEMU invocation can include, for example:

```text
-device pve-lab-hwmon,bus=pcie.0,addr=1e.0,cpu-temp-dk=3132,board-temp-dk=3042,cpu-fan-rpm=900,case-fan-rpm=700,fan-control=30,vcore-mv=1100,v12-mv=12040,v5-mv=5020,v33-mv=3310
-acpitable file=/absolute/path/to/PVEHWMON.aml
```

Do not put raw `-device` args into a production Proxmox VM before validating
the final `qm showcmd VMID --pretty`, possible PCI conflicts, and Windows
guest boot. A guest driver may be needed to read the voltage MMIO registers;
WMI fan/voltage classes do not automatically expose them.

## Validation limitations

This code has been ported, not compiled against the target QEMU version.
QEMU object model, Meson, reset, timer migration, and ACPI behavior can change
by version. Static review and a disposable host build/boot test are mandatory
before production deployment. No physical hardware spoofing or bypass claim
is made.
