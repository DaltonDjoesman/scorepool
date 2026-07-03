#!/usr/bin/env python3
"""Read openspec/github-delivery.yaml (stdlib only, minimal YAML subset)."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = REPO_ROOT / "openspec" / "github-delivery.yaml"


def load_config(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    config: dict = {}
    sections: dict = {}
    current_section: str | None = None

    for raw_line in text.splitlines():
        line = raw_line.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue

        if line.startswith("repo:"):
            config["repo"] = line.split(":", 1)[1].strip()
        elif line.startswith("project_owner:"):
            config["project_owner"] = line.split(":", 1)[1].strip()
        elif line.startswith("project_number:"):
            config["project_number"] = int(line.split(":", 1)[1].strip())
        elif line.startswith("project_title:"):
            config["project_title"] = line.split(":", 1)[1].strip()
        elif line.startswith("status_field:"):
            config["status_field"] = line.split(":", 1)[1].strip()
        elif line.startswith("status_done:"):
            config["status_done"] = line.split(":", 1)[1].strip()
        elif re.match(r'^  "\d+":\s*$', line):
            current_section = re.search(r'"(\d+)"', line).group(1)
            sections[current_section] = {}
        elif current_section and line.startswith("    title:"):
            sections[current_section]["title"] = line.split(":", 1)[1].strip()
        elif current_section and line.startswith("    branch:"):
            sections[current_section]["branch"] = line.split(":", 1)[1].strip()
        elif current_section and line.startswith("    done:"):
            sections[current_section]["done"] = line.split(":", 1)[1].strip() == "true"
        elif current_section and line.startswith("    issues:"):
            nums = re.findall(r"\d+", line.split(":", 1)[1])
            sections[current_section]["issues"] = [int(n) for n in nums]

    config["sections"] = sections
    return config


def get_section(config: dict, section: str) -> dict:
    sec = config.get("sections", {}).get(str(section))
    if not sec:
        raise SystemExit(f"Unknown section: {section}")
    return sec


def main() -> None:
    parser = argparse.ArgumentParser(description="Read openspec github-delivery.yaml")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    sub = parser.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("get-section")
    g.add_argument("section")

    sub.add_parser("list-sections")

    j = sub.add_parser("json")
    j.add_argument("section", nargs="?")

    args = parser.parse_args()
    config = load_config(args.config)

    if args.cmd == "list-sections":
        for num, sec in sorted(config["sections"].items(), key=lambda x: int(x[0])):
            done = "done" if sec.get("done") else "pending"
            print(f"{num}\t{sec.get('branch')}\t{done}\tissues={sec.get('issues')}")
        return

    if args.cmd == "get-section":
        sec = get_section(config, args.section)
        print(json.dumps({**sec, "repo": config["repo"]}, indent=2))
        return

    if args.cmd == "json":
        if args.section:
            payload = {**get_section(config, args.section), "repo": config["repo"], **{
                k: config[k]
                for k in (
                    "project_owner",
                    "project_number",
                    "status_field",
                    "status_done",
                )
                if k in config
            }}
            print(json.dumps(payload, indent=2))
        else:
            print(json.dumps(config, indent=2))


if __name__ == "__main__":
    main()
