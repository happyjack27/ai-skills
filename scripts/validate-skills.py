#!/usr/bin/env python3
"""Validate skill structure, local Markdown links, indexes, and catalog consistency."""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "SKILL-CATALOG.json"


def frontmatter(text):
    match = re.match(r"^---\r?\n(.*?)\r?\n---(?:\r?\n|$)", text, re.DOTALL)
    if not match:
        return {}
    values = {}
    for line in match.group(1).splitlines():
        field = re.match(r"^([A-Za-z0-9_-]+):\s*(.*?)\s*$", line)
        if field:
            values[field.group(1)] = field.group(2).strip().strip("'\"")
    return values


def local_links(markdown_file):
    text = markdown_file.read_text(encoding="utf-8")
    text = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", text):
        target = target.strip().split("#", 1)[0]
        if not target or target.startswith(("http://", "https://", "mailto:", "<", "[")):
            continue
        resolved = (markdown_file.parent / target).resolve()
        try:
            resolved.relative_to(ROOT)
        except ValueError:
            continue
        yield resolved


def main():
    errors = []
    skills = sorted(ROOT.rglob("SKILL.md"))
    skill_records = {}

    for skill_file in skills:
        relative = skill_file.relative_to(ROOT).as_posix()
        metadata = frontmatter(skill_file.read_text(encoding="utf-8"))
        expected_name = skill_file.parent.name
        if not metadata:
            errors.append(f"{relative}: missing or malformed frontmatter")
            continue
        if metadata.get("name") != expected_name:
            errors.append(f"{relative}: name must be {expected_name!r}")
        if not metadata.get("description"):
            errors.append(f"{relative}: missing description")
        skill_records[relative] = metadata.get("name")

        for link in local_links(skill_file):
            if not link.exists():
                errors.append(f"{relative}: broken link {link.relative_to(ROOT).as_posix()}")

        index = skill_file.parent.parent / "SKILLS.md"
        index_text = index.read_text(encoding="utf-8") if index.exists() else ""
        index_link = f"({skill_file.parent.name}/SKILL.md)"
        if index_link not in index_text:
            errors.append(f"{relative}: missing from {index.relative_to(ROOT).as_posix()}")

    for markdown_file in ROOT.rglob("*.md"):
        if ".git" in markdown_file.parts:
            continue
        for link in local_links(markdown_file):
            if not link.exists():
                errors.append(
                    f"{markdown_file.relative_to(ROOT).as_posix()}: broken link "
                    f"{link.relative_to(ROOT).as_posix()}"
                )

    if not CATALOG.exists():
        errors.append("SKILL-CATALOG.json: file is missing; run scripts/generate-catalog.py")
    else:
        try:
            catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            errors.append(f"SKILL-CATALOG.json: invalid JSON ({error})")
        else:
            catalog_records = {
                record.get("path"): record.get("name")
                for record in catalog
                if isinstance(record, dict)
            }
            if catalog_records != skill_records:
                missing = sorted(set(skill_records) - set(catalog_records))
                extra = sorted(set(catalog_records) - set(skill_records))
                if missing:
                    errors.append(f"SKILL-CATALOG.json: missing entries {missing}")
                if extra:
                    errors.append(f"SKILL-CATALOG.json: stale entries {extra}")

    if errors:
        print("Skill validation failed:")
        for error in sorted(set(errors)):
            print(f"- {error}")
        return 1

    print(f"Skill validation passed: {len(skills)} skills, links and catalog are consistent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
