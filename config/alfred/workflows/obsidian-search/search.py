#!/usr/bin/python3
"""Search Markdown filenames in the configured vault using the macOS Spotlight index."""

import json
import os
from pathlib import Path
import subprocess
import sys


def show(message, detail):
    print(json.dumps({"items": [{"title": message, "subtitle": detail, "valid": False}]}))


vault_value = os.environ.get("vault_path", "").strip()
vault = Path(vault_value).expanduser() if vault_value else None
if not vault or not vault.is_dir():
    show("Choose a vault folder", "Set Vault folder in Configure Workflow")
    sys.exit(0)

query = " ".join(sys.argv[1:]).strip()
if not query:
    show("Search Obsidian notes", "Type part of a Markdown note filename in " + vault.name)
    sys.exit(0)

# Spotlight's filename and content-type metadata are queried; note contents are never read.
terms = query.split()
conditions = ['kMDItemContentType == "net.daringfireball.markdown"']
for term in terms:
    escaped = term.replace("\\", "\\\\").replace('"', '\\"').replace("*", "\\*").replace("?", "\\?")
    conditions.append('kMDItemFSName == "*' + escaped + '*"cd')

try:
    result = subprocess.run(
        ["/usr/bin/mdfind", "-0", "-onlyin", str(vault), " && ".join(conditions)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5, check=True,
    )
except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
    show("Spotlight search unavailable", "Check vault availability and Alfred File Search Troubleshooting")
    sys.exit(0)

items = []
for raw_path in result.stdout.split(b"\0"):
    if not raw_path:
        continue
    path = Path(os.fsdecode(raw_path))
    try:
        relative = path.relative_to(vault)
    except ValueError:
        continue
    if path.suffix.lower() != ".md" or any(part.startswith(".") for part in relative.parts):
        continue
    items.append({
        "title": path.name,
        "subtitle": str(Path(vault.name) / relative),
        "arg": str(path),
        "icon": {"type": "fileicon", "path": str(path)},
    })

items.sort(key=lambda item: (not item["title"].casefold().startswith(query.casefold()), item["title"].casefold(), item["subtitle"].casefold()))
if items:
    print(json.dumps({"items": items[:60]}, ensure_ascii=False))
else:
    show("No matching notes", "Check vault scope, iCloud availability, and Spotlight indexing")
