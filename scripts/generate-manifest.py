#!/usr/bin/env python3
"""Regenerate content/manifest.json from the day files in content/days/.

Usage:
    python3 scripts/generate-manifest.py

Each day lives in content/days/YYYY/MM/DD.md with YAML frontmatter. The
manifest is the only file the app needs to know about — every day is
discovered through it, so this script is the single source of truth.

Output is deterministic (entries sorted by date) so diffs stay clean.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1

EXPECTED_SECTIONS = {
    "morning.prayer",
    "morning.scripture",
    "morning.comment",
    "morning.thought",
    "evening.prayer",
    "evening.examination",
    "evening.psalm",
    "evening.word",
}

# Matches files at content/days/YYYY/MM/DD.md exactly.
_DAY_PATH_RE = re.compile(r"^days/(\d{4})/(\d{2})/(\d{2})\.md$")

# Matches '## section.name' lines (used only for validation).
_SECTION_RE = re.compile(r"^##\s+([a-z]+\.[a-z]+)\s*$", re.MULTILINE)

_FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_frontmatter(text: str) -> dict[str, str | None]:
    """Minimal YAML-ish parser. Supports `key: value` with `null` and quoted strings."""
    match = _FRONTMATTER_RE.match(text)
    if not match:
        return {}
    out: dict[str, str | None] = {}
    for raw_line in match.group(1).splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()
        if value == "" or value.lower() == "null" or value == "~":
            out[key] = None
        else:
            if (value.startswith('"') and value.endswith('"')) or (
                value.startswith("'") and value.endswith("'")
            ):
                value = value[1:-1]
            out[key] = value
    return out


def validate_day(rel_path: str, text: str) -> None:
    """Raise ValueError if the day file is malformed.

    Why: a missing section would render as an empty card in the app — catching
    it here is cheaper than debugging on device.
    """
    fm = parse_frontmatter(text)
    if not fm:
        raise ValueError(f"{rel_path}: missing YAML frontmatter")
    if "date" not in fm or not fm["date"]:
        raise ValueError(f"{rel_path}: frontmatter must include `date`")
    sections = set(_SECTION_RE.findall(text))
    missing = EXPECTED_SECTIONS - sections
    if missing:
        raise ValueError(
            f"{rel_path}: missing sections: {', '.join(sorted(missing))}"
        )
    extras = sections - EXPECTED_SECTIONS
    if extras:
        raise ValueError(
            f"{rel_path}: unknown sections: {', '.join(sorted(extras))}"
        )


def collect_days(content_root: Path) -> list[dict]:
    entries: list[dict] = []
    for path in sorted((content_root / "days").rglob("*.md")):
        if not path.is_file():
            continue
        rel = str(path.relative_to(content_root)).replace("\\", "/")
        m = _DAY_PATH_RE.match(rel)
        if not m:
            raise ValueError(
                f"{rel}: expected layout days/YYYY/MM/DD.md"
            )
        year, month, day = m.group(1), m.group(2), m.group(3)
        date = f"{year}-{month}-{day}"
        text = path.read_text(encoding="utf-8")
        validate_day(rel, text)
        fm = parse_frontmatter(text)
        # Sanity check: filename date matches frontmatter date.
        if fm.get("date") != date:
            raise ValueError(
                f"{rel}: filename date {date} != frontmatter date {fm.get('date')}"
            )
        entries.append({
            "date": date,
            "path": rel,
            "sha256": sha256(path),
            "size": path.stat().st_size,
            "feast": fm.get("feast"),
            "season": fm.get("season"),
        })
    return entries


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    content_dir = repo_root / "content"
    if not content_dir.is_dir():
        print(f"error: {content_dir} not found", file=sys.stderr)
        return 1

    entries = collect_days(content_dir)
    manifest = {
        "schemaVersion": SCHEMA_VERSION,
        "title": "Zamyslenia",
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "entries": entries,
    }

    out_path = content_dir / "manifest.json"
    out_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out_path} ({len(entries)} days)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
