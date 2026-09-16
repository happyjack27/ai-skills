#!/usr/bin/env python3
"""Generate the compact, routing-only skill catalog."""

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "SKILL-CATALOG.json"
RESOURCE_DIRS = ("references", "templates", "examples", "archetypes", "scripts", "assets")


def frontmatter(text):
    match = re.match(r"^---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.DOTALL)
    if not match:
        return {}
    values = {}
    for line in match.group(1).splitlines():
        field = re.match(r"^([A-Za-z0-9_-]+):\s*(.*?)\s*$", line)
        if field:
            value = field.group(2).strip().strip("'\"")
            values[field.group(1)] = value
    return values


def section_bullets(text, heading):
    match = re.search(
        rf"^##\s+{re.escape(heading)}\s*$([\s\S]*?)(?=^##\s+|\Z)",
        text,
        re.MULTILINE,
    )
    if not match:
        return []
    return [
        re.sub(r"\s+", " ", line[2:].strip())
        for line in match.group(1).splitlines()
        if line.startswith("- ")
    ]


def related_paths(text):
    return sorted(
        set(
            link
            for link in re.findall(r"\[[^]]+\]\(([^)]+)\)", text)
            if not re.match(r"(?:https?|mailto):", link) and "shared/" not in link
        )
    )


def resource_files(skill_dir):
    resources = {}
    for directory in RESOURCE_DIRS:
        path = skill_dir / directory
        if path.is_dir():
            files = sorted(
                str(file.relative_to(skill_dir)).replace("\\", "/")
                for file in path.rglob("*")
                if file.is_file() and file.name != ".gitkeep"
            )
            if files:
                resources[directory] = files
    return resources


def build_catalog():
    records = []
    for skill_file in sorted(ROOT.rglob("SKILL.md")):
        if ".git" in skill_file.parts:
            continue
        text = skill_file.read_text(encoding="utf-8")
        metadata = frontmatter(text)
        skill_dir = skill_file.parent
        records.append(
            {
                "name": metadata.get("name", skill_dir.name),
                "skillset": skill_dir.parent.name,
                "path": str(skill_file.relative_to(ROOT)).replace("\\", "/"),
                "description": metadata.get("description", ""),
                "routing": section_bullets(text, "Routing Boundaries"),
                "resources": resource_files(skill_dir),
                "related": related_paths(text),
            }
        )
    return records


if __name__ == "__main__":
    catalog = build_catalog()
    OUTPUT.write_text(
        "[\n"
        + ",\n".join(json.dumps(record, ensure_ascii=True, separators=(",", ":")) for record in catalog)
        + "\n]\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Wrote {len(catalog)} skills to {OUTPUT}")
