#!/usr/bin/env bash
# Compile the lab thermal/fan SSDT in a user-selected output directory.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:?Usage: $0 /path/to/output-dir}"
command -v iasl >/dev/null || { echo "Install acpica-tools first" >&2; exit 1; }
mkdir -p "$OUT"
cp "$ROOT/acpi/PVEHWMON.dsl" "$OUT/PVEHWMON.dsl"
(cd "$OUT" && iasl -tc PVEHWMON.dsl)
test -s "$OUT/PVEHWMON.aml"
printf '%s\n' "$OUT/PVEHWMON.aml"
