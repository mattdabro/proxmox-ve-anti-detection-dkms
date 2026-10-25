#!/usr/bin/env python3
"""Insert the opt-in HWMON source overlay stage after the existing QEMU patch step."""
import argparse
import shlex
from pathlib import Path

def inject(rules, patch, overlay):
    data = rules.read_text()
    needle = "patch -p1 < " + patch
    matches = [line for line in data.splitlines(keepends=True) if needle in line and not line.lstrip().startswith("#")]
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one QEMU patch command, found {len(matches)}")
    line = matches[0]
    if not line.startswith("\t"):
        raise ValueError("Patch command must be in a make recipe")
    inserted = "\t" + shlex.quote(str(overlay)) + " .\n"
    if inserted in data:
        return
    rules.write_text(data.replace(line, line + inserted, 1))

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("rules", type=Path)
    p.add_argument("patch")
    p.add_argument("overlay", type=Path)
    args = p.parse_args()
    if not args.overlay.is_file():
        p.error("Overlay installer not found")
    inject(args.rules, args.patch, args.overlay)

if __name__ == "__main__":
    main()
