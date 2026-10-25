#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-/var/log/pve-main-project/msr-$(date -u +%Y%m%dT%H%M%SZ)}"
install -d -m 0700 "$OUT"

{
  echo "ignore_msrs=$(cat /sys/module/kvm/parameters/ignore_msrs 2>/dev/null || echo unavailable)"
  echo "report_ignored_msrs=$(cat /sys/module/kvm/parameters/report_ignored_msrs 2>/dev/null || echo unavailable)"
} > "$OUT/policy.txt"

dmesg | grep -Ei 'kvm.*msr|unhandled.*msr|ignored.*msr' > "$OUT/kernel-msr-log.txt" || true

if trace-cmd list -e kvm | grep -qi msr; then
  trace-cmd list -e kvm | grep -i msr > "$OUT/available-msr-tracepoints.txt"
fi

if [[ -r /sys/module/kvm/parameters/ignore_msrs ]] &&
   [[ "$(cat /sys/module/kvm/parameters/ignore_msrs)" =~ ^[Y1]$ ]]; then
  echo "WARNING: kvm.ignore_msrs is enabled; this project expects fail-closed MSR handling." >&2
fi

echo "$OUT"
