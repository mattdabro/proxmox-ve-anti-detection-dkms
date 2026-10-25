#!/usr/bin/env bash
# Install an opt-in lab HWMON source overlay into a checked-out QEMU tree.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU="${1:?Usage: $0 /path/to/qemu-source}"
[[ -d "$QEMU/hw/misc" && -f "$QEMU/hw/misc/meson.build" ]] || {
  echo "Expected a QEMU source tree containing hw/misc/meson.build" >&2
  exit 2
}
TARGET="$QEMU/hw/misc/pve-lab-hwmon.c"
MESON="$QEMU/hw/misc/meson.build"
if [[ -e "$TARGET" ]] && ! cmp -s "$ROOT/qemu/pve-lab-hwmon.c" "$TARGET"; then
  echo "Existing HWMON source differs; refusing overwrite: $TARGET" >&2
  exit 1
fi
install -m 0644 "$ROOT/qemu/pve-lab-hwmon.c" "$TARGET"
LINE="system_ss.add(files('pve-lab-hwmon.c'))"
if ! grep -Fxq "$LINE" "$MESON"; then
  printf '\n%s\n' "$LINE" >> "$MESON"
fi
printf 'Staged HWMON source at %s\n' "$TARGET"
printf 'This does not compile or install QEMU. Review the diff first.\n'
