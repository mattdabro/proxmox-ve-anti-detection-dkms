#!/usr/bin/env python3
"""Read Linux hwmon temperature, fan, and voltage sensors without changing them."""
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/sys/class/hwmon")
UNITS = {"temp": ("C", 1000), "fan": ("RPM", 1), "in": ("V", 1000)}
SUFFIX = {"temp": "_input", "fan": "_input", "in": "_input"}

def gather(root=ROOT):
    devices = []
    for device in sorted(root.glob("hwmon*")):
        if not device.is_dir():
            continue
        try:
            name = (device / "name").read_text().strip()
        except (OSError, UnicodeError):
            name = device.name
        sensors = []
        for category, suffix in SUFFIX.items():
            for file in sorted(device.glob(f"{category}[0-9]*{suffix}")):
                channel = file.name[:-len(suffix)]
                try:
                    raw = int(file.read_text().strip())
                except (OSError, ValueError):
                    continue
                label_file = device / f"{channel}_label"
                try:
                    label = label_file.read_text().strip()
                except (OSError, UnicodeError):
                    label = channel
                unit, divisor = UNITS[category]
                sensors.append({
                    "channel": channel, "label": label,
                    "kind": {"temp": "temperature", "fan": "fan", "in": "voltage"}[category],
                    "value": raw / divisor, "unit": unit,
                })
        if sensors:
            devices.append({"device": name, "sysfs": str(device), "sensors": sensors})
    return devices

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="sysfs hwmon root")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    result = {"time_utc": datetime.now(timezone.utc).isoformat(),
              "source": "Linux sysfs hwmon (physical host, not Windows guest)",
              "devices": gather(args.root)}
    output = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(output)
    else:
        print(output, end="")

if __name__ == "__main__":
    main()
