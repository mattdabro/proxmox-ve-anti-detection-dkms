# Build safety and recovery

The tool rebuilds `pve-qemu-kvm`; it is not a Linux kernel DKMS module.
Run it only on a disposable Proxmox test host before deploying to production.

## Failure behavior

- A package version without a matching source revision now aborts rather than compiling a potentially unrelated HEAD revision.
- Missing build dependencies, submodule update errors, or failed builds abort installation.
- Debian package installation no longer uses `--force-all`.
- Concurrent `install`, `rebuild`, and `upgrade` processes are rejected with exit code 75.

This is fail-closed packaging behavior, not proof that patches are compatible with any given QEMU release.

## Before testing

Record `pveversion -v`, `dpkg-query -W pve-qemu-kvm`, `qm list`, and the current package hold state.
Maintain a host backup and a rollback copy of the **unmodified, matching-version** QEMU package.
Avoid rebuilding while production VMs are running; schedule a maintenance window.

## Diagnosis

Run `pve-qemu-anti-detection status`.
Inspect `/var/log/pve-qemu-anti-detection.log`.
Inspect `journalctl -u pve-qemu-anti-detection-rebuild.service`.
Check availability of exact source tags and submodule revisions before retrying.

## Known limitations

- Tag/commit-message matching is not an authoritative package-to-source mapping; the source revision must be verified before production use.
- Debian package build success does not establish hypervisor feature correctness.
- The existing APT hook and service still require real Proxmox integration tests.
- VM fingerprint modifications are outside the scope of this safety change.
