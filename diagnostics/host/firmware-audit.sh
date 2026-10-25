#!/usr/bin/env bash
# Read-only OVMF/EDK2 package and image provenance audit.
set -euo pipefail
umask 077

VMID="${1:?Usage: $0 VMID [output-directory]}"
[[ "$VMID" =~ ^[0-9]+$ ]] || { echo "Invalid VMID" >&2; exit 2; }
OUT="${2:-/var/log/pve-main-project/firmware-${VMID}-$(date -u +%Y%m%dT%H%M%SZ)}"
install -d -m 0700 "$OUT"
command -v qm >/dev/null || { echo "qm missing" >&2; exit 1; }
qm config "$VMID" > "$OUT/vm.conf"
qm showcmd "$VMID" --pretty > "$OUT/qemu-command.txt"
dpkg-query -W -f='${Package}\t${Version}\n' 'pve-edk2-firmware*' 'ovmf*' 2> "$OUT/package-query-errors.txt" > "$OUT/packages.txt" || true
pveversion -v > "$OUT/pveversion.txt"
: > "$OUT/firmware-images.sha256"
for root in /usr/share/pve-edk2-firmware /usr/share/OVMF /usr/share/qemu; do
    [[ -d "$root" ]] || continue
    while IFS= read -r -d '' file; do
        sha256sum "$file" >> "$OUT/firmware-images.sha256"
    done < <(find "$root" -type f \( -iname '*.fd' -o -iname '*.rom' \) -print0)
done
echo "Firmware package identity and image hashes recorded in $OUT"
echo "SMBIOS Type 0 does not establish the UEFI EFI_SYSTEM_TABLE FirmwareVendor value."
echo "No firmware was rewritten or installed."
