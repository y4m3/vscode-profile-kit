#!/usr/bin/env python3
"""Filter extension list files (ignore comments/blank lines) and merge sources.
Usage:
    python filter_extensions.py output.list input1.txt [input2.txt ...]
"""
from __future__ import annotations

import sys
from pathlib import Path


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.stderr.write("Usage: python filter_extensions.py output.list input1.txt [input2.txt ...]\n")
        return 1

    out_path = Path(argv[0])
    sources = [Path(p) for p in argv[1:]]

    lines: list[str] = []
    for src in sources:
        if not src.exists():
            sys.stderr.write(f"Error: {src} not found\n")
            return 1
        for line in src.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                lines.append(line)

    out_path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
