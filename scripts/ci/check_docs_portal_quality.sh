#!/usr/bin/env bash
set -euo pipefail

required_ru=(
  docs/portal/INDEX.md
  docs/portal/NAVIGATION.md
  docs/portal/DOC_STYLE_GUIDE.md
  docs/portal/DOC_AUTHORITY.md
  docs/portal/GLOSSARY.md
  docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md
  docs/portal/PRODUCT_GUARANTEES.md
  docs/portal/SECURITY_POSTURE.md
  docs/rag/README.md
  docs/rag/context_packs.md
  docs/rag/security_policy.md
  docs/rag/sources.yaml
)

required_en=(
  docs/en/README.md
  docs/en/ARCHITECTURE.md
  docs/en/INTEGRATION.md
  docs/en/portal/INDEX.md
  docs/en/portal/NAVIGATION.md
  docs/en/portal/DOC_STYLE_GUIDE.md
  docs/en/portal/DOC_AUTHORITY.md
  docs/en/portal/GLOSSARY.md
  docs/en/portal/COMPATIBILITY_MATRIX_ART_REGART.md
  docs/en/portal/PRODUCT_GUARANTEES.md
  docs/en/portal/SECURITY_POSTURE.md
  docs/en/rag/README.md
  docs/en/rag/context_packs.md
  docs/en/rag/security_policy.md
  docs/en/rag/sources.yaml
)

for f in "${required_ru[@]}" "${required_en[@]}"; do
  test -s "$f"
done

# RU/EN path parity for portal/rag markdown and yaml docs.
while IFS= read -r rel; do
  test -s "docs/en/${rel}"
done < <(cd docs && find portal rag -type f \( -name "*.md" -o -name "*.yaml" \) | sort)

# Mandatory source-of-truth marker in markdown docs.
while IFS= read -r md; do
  grep -qi "source of truth" "$md"
done < <(find docs/portal docs/rag docs/en/portal docs/en/rag docs/en -maxdepth 2 -type f -name "*.md" | sort)

# Negative ambiguity markers.
if rg -n "быстро накидать|ослабить качество|ослабить безопасность" docs/portal docs/rag docs/en/portal docs/en/rag >/dev/null; then
  echo "Forbidden ambiguity markers found in portal/rag docs"
  exit 1
fi

# Lightweight relative link check for markdown files in portal/rag trees.
python3 - <<'PY'
from pathlib import Path
import re
import sys

roots = [Path("docs/portal"), Path("docs/rag"), Path("docs/en/portal"), Path("docs/en/rag")]
link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
missing = []

for root in roots:
    for md in root.rglob("*.md"):
        text = md.read_text(encoding="utf-8")
        for raw in link_re.findall(text):
            target = raw.strip()
            if not target or target.startswith("#"):
                continue
            if "://" in target or target.startswith("mailto:"):
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            if target.startswith("/"):
                p = Path(target.lstrip("/"))
            else:
                p = (md.parent / target).resolve()
                try:
                    p = p.relative_to(Path.cwd())
                except Exception:
                    pass
            if not Path(p).exists():
                missing.append(f"{md}: {raw}")

if missing:
    print("Broken local markdown links:")
    for item in missing:
        print(item)
    sys.exit(1)
PY

echo "docs portal quality gate: OK"
