#!/usr/bin/env python3
"""Merge base keybindings with role-specific delta.
Usage:
    python merge_keybindings.py base.jsonc [delta.jsonc] output.json
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Annotated

try:
    from typing_extensions import Doc
except ImportError:
    class Doc:
        def __init__(self, documentation: str, /):
            self.documentation = documentation

from jsonc_merge import strip_jsonc


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.stderr.write("Usage: python merge_keybindings.py base.jsonc [delta.jsonc] output.json\n")
        return 1
    
    base_path = Path(argv[0])
    output_path = Path(argv[-1])
    
    if not base_path.exists():
        sys.stderr.write(f"Error: {base_path} not found\n")
        return 1
    
    # Load base keybindings
    base_content = base_path.read_text(encoding="utf-8")
    data = json.loads(strip_jsonc(base_content))
    
    # If delta exists, merge it (simple replacement for keybindings)
    if len(argv) > 2:
        delta_path = Path(argv[1])
        if delta_path.exists():
            delta_content = delta_path.read_text(encoding="utf-8")
            delta_data = json.loads(strip_jsonc(delta_content))
            # For keybindings, we replace (don't deep merge)
            data = delta_data if isinstance(delta_data, list) else data
    
    # Write output as UTF-8
    output_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
