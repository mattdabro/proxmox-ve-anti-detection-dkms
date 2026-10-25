#!/usr/bin/env bash
set -euo pipefail
umask 077
OUT="${1:-./edid-report}"
mkdir -p "$OUT"
count=0
for input in /sys/class/drm/card*-*/edid; do
  [[ -s "$input" ]] || continue
  connector="$(basename "$(dirname "$input")")"
  cp "$input" "$OUT/$connector.bin"
  sha256sum "$OUT/$connector.bin" > "$OUT/$connector.bin.sha256"
  if command -v edid-decode >/dev/null 2>&1; then
    edid-decode "$OUT/$connector.bin" > "$OUT/$connector.txt" 2>&1 || true
  fi
  count=$((count + 1))
done
printf 'Captured %d EDID blobs in %s\n' "$count" "$OUT"
