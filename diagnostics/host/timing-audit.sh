#!/usr/bin/env bash
set -euo pipefail

VMID="${1:?Usage: $0 VMID [seconds]}"
SECONDS="${2:-30}"
OUT="${OUT:-/var/log/pve-main-project/timing-${VMID}-$(date -u +%Y%m%dT%H%M%SZ)}"

install -d -m 0700 "$OUT"

PIDFILE="/run/qemu-server/${VMID}.pid"
[[ -r "$PIDFILE" ]] || { echo "VM $VMID is not running." >&2; exit 1; }
PID="$(cat "$PIDFILE")"

cat /sys/devices/system/clocksource/clocksource0/current_clocksource > "$OUT/clocksource.txt"
lscpu -e=CPU,NODE,SOCKET,CORE,ONLINE > "$OUT/topology.txt"
qm config "$VMID" > "$OUT/vm.conf"
qm showcmd "$VMID" --pretty > "$OUT/qemu-command.txt"

perf stat   -e cycles,instructions,cache-misses,context-switches,cpu-migrations   -p "$PID"   -- sleep "$SECONDS"   2> "$OUT/perf-stat.txt"

if trace-cmd list -e kvm | grep -q 'kvm:kvm_exit'; then
  trace-cmd record -o "$OUT/kvm.dat"     -e kvm:kvm_entry     -e kvm:kvm_exit     -- sleep "$SECONDS"
  trace-cmd report -i "$OUT/kvm.dat" > "$OUT/kvm-exits.txt"
fi

echo "$OUT"
