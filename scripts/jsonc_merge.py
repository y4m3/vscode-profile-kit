#!/usr/bin/env python3
from __future__ import annotations

"""Merge one or more JSONC files (comments allowed) and emit JSON.
- Supports // line comments and /* ... */ block comments.
- Deep merge: dicts are merged recursively; arrays and scalars are overwritten by later files.
Usage:
    python3 scripts/jsonc_merge.py base.jsonc [delta1.jsonc ...] > merged.json
"""

import json
import re
import sys
from pathlib import Path
from typing import Any, Annotated

try:  # PEP 727: documentation in Annotated metadata
    from typing_extensions import Doc  # type: ignore
except ImportError:  # Fallback when typing_extensions is unavailable
    class Doc:  # minimal runtime stub
        def __init__(self, documentation: str, /):
            self.documentation = documentation


JSONScalar = str | int | float | bool | None
JSONValue = JSONScalar | list["JSONValue"] | dict[str, "JSONValue"]


def strip_jsonc(text: Annotated[str, Doc("JSONC text (may include comments)")]) -> str:
    """Remove // and /* */ comments and trailing commas from JSONC text.
    
    Preserves // inside quoted strings by tracking string state.
    """
    # First remove /* */ block comments (they can't appear in strings naively)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    
    # Remove // line comments, but preserve them inside strings
    result = []
    in_string = False
    escape_next = False
    i = 0
    while i < len(text):
        char = text[i]
        
        # Handle string state
        if char == '"' and not escape_next:
            in_string = not in_string
        
        # Handle escape sequences
        escape_next = (char == '\\' and not escape_next and in_string)
        
        # Check for comment start
        if not in_string and i + 1 < len(text) and text[i:i+2] == '//':
            # Skip to end of line
            while i < len(text) and text[i] != '\n':
                i += 1
            continue
        
        result.append(char)
        i += 1
    
    text = ''.join(result)
    # Remove trailing commas before } or ]
    text = re.sub(r",\s*([}\]])", r"\1", text)
    return text


def load_jsonc(path: Annotated[Path, Doc("Path to a JSONC file")]) -> JSONValue:
    raw = path.read_text(encoding="utf-8")
    return json.loads(strip_jsonc(raw))


def deep_merge(
    a: Annotated[JSONValue, Doc("Base value")],
    b: Annotated[JSONValue, Doc("Override value")],
) -> JSONValue:
    """Recursively merge two JSON values. Arrays/scalars are overwritten by b."""
    if isinstance(a, dict) and isinstance(b, dict):
        merged = dict(a)
        for k, v in b.items():
            merged[k] = deep_merge(merged[k], v) if k in merged else v
        return merged
    return b


def main(
    argv: Annotated[list[str], Doc("JSONC file paths, earlier = base, later = overrides")]
) -> int:
    if len(argv) < 1:
        sys.stderr.write("Usage: jsonc_merge.py base.jsonc [delta1.jsonc ...] > out.json\n")
        return 1
    paths = [Path(p) for p in argv]
    data = load_jsonc(paths[0])
    for p in paths[1:]:
        data = deep_merge(data, load_jsonc(p))
    # Write as UTF-8 to stdout.buffer to handle non-ASCII characters on Windows
    sys.stdout.buffer.write(json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8"))
    sys.stdout.buffer.write(b"\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
