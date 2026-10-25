#!/usr/bin/env bash
set -euo pipefail
umask 077
OUT="${1:-./host-baseline}"
mkdir -p "$OUT"
pveversion -v > "$OUT/pveversion.txt"
uname -a > "$OUT/kernel.txt"
dpkg-query -W -f='${Package}\t${Version}\n' pve-qemu-kvm > "$OUT/qemu-package.txt"
lscpu > "$OUT/cpu.txt"
qm list > "$OUT/vms.txt"
apt-mark showhold > "$OUT/holds.txt"
if [[ -r /sys/devices/system/clocksource/clocksource0/current_clocksource ]]; then
  cat /sys/devices/system/clocksource/clocksource0/current_clocksource > "$OUT/clocksource.txt"
fi
(
  cd "$OUT"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 |
    sort -z | xargs -0 -r sha256sum > SHA256SUMS
)
printf 'Baseline captured in %s\n' "$OUT"
