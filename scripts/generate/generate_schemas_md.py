#!/usr/bin/env python3
import json
from pathlib import Path


INDEX = Path("docs/schemas/index.md")
OUT = Path("docs/api/schemas.md")


def parse_index_files(index_text: str) -> list[str]:
    files: list[str] = []
    for line in index_text.splitlines():
        if "| docs/schemas/" not in line:
            continue
        cells = [cell.strip() for cell in line.split("|")]
        if len(cells) < 5:
            continue
        path = cells[3]
        if path.startswith("docs/schemas/") and path.endswith(".json"):
            files.append(path)
    return files


def describe_schema(path: Path) -> str:
    data = json.loads(path.read_text(encoding="utf-8"))
    title = data.get("title", path.stem)
    properties = sorted((data.get("properties") or {}).keys())
    if not properties:
        return f"`{title}`: schema without explicit properties."
    preview = ", ".join(properties[:4])
    return f"`{title}`: fields `{preview}`."


def main() -> None:
    index_text = INDEX.read_text(encoding="utf-8")
    files = parse_index_files(index_text)
    lines = [
        "# Art schemas v1",
        "",
        "Source index: `docs/schemas/index.md`",
        "",
        "## Schemas",
    ]
    for rel in files:
        desc = describe_schema(Path(rel))
        lines.append(f"- `{rel}` — {desc}")
    lines.extend(["", "Generated from docs/schemas/index.md and docs/schemas/v1/*.json."])
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
