#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-./iommu-report}"
mkdir -p "$OUT"
lspci -nnk > "$OUT/pci.txt"
: > "$OUT/groups.txt"
for group in /sys/kernel/iommu_groups/*; do
  [[ -d "$group" ]] || continue
  printf 'IOMMU group %s\n' "${group##*/}" >> "$OUT/groups.txt"
  for dev in "$group"/devices/*; do
    [[ -e "$dev" ]] || continue
    lspci -nnk -s "${dev##*/}" >> "$OUT/groups.txt"
  done
done
printf '%s\n' "$OUT"
