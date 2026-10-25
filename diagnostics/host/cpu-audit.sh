#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/var/log/pve-main-project/cpu-$(date -u +%Y%m%dT%H%M%SZ)}"
install -d -m 0700 "$OUT"

lscpu > "$OUT/lscpu.txt"
lscpu -e=CPU,NODE,SOCKET,CORE,ONLINE > "$OUT/topology.txt"
grep -m1 '^flags' /proc/cpuinfo > "$OUT/flags.txt" || true

if command -v cpuid >/dev/null 2>&1; then
  cpuid -1 -r > "$OUT/cpuid-raw.txt"
else
  echo "cpuid utility not installed" > "$OUT/cpuid-raw.txt"
fi

for f in   /sys/devices/system/clocksource/clocksource0/current_clocksource   /sys/devices/system/clocksource/clocksource0/available_clocksource; do
  [[ -r "$f" ]] && { echo "== $f =="; cat "$f"; }
done > "$OUT/clocksources.txt"

cpupower frequency-info > "$OUT/frequency.txt" 2>&1 || true

echo "$OUT"
