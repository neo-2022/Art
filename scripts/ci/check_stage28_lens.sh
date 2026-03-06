#!/usr/bin/env bash
set -euo pipefail

FOUNDATION="docs/source/FOUNDATION_CONSTITUTION_V0_2.md"
LENS_REPORT="docs/foundation/lens_audit_report.md"

test -s "$FOUNDATION"
test -s "$LENS_REPORT"

appendix_text="$(awk '/^# APPENDIX A — LENS CATALOG \(обязательный аудит полноты\)$/{flag=1} flag{print}' "$FOUNDATION")"
test -n "$appendix_text"

printf '%s\n' "$appendix_text" | grep -q "A0.0 Classification rule"
printf '%s\n' "$appendix_text" | grep -q "A0.1 Primary / Secondary / Anti-pattern mapping"
printf '%s\n' "$appendix_text" | grep -q "Primary (обязательные)"
printf '%s\n' "$appendix_text" | grep -q "Secondary (по месту, без ослабления требований)"
printf '%s\n' "$appendix_text" | grep -q "Anti-pattern (запрещено как стиль работы)"
printf '%s\n' "$appendix_text" | grep -q "Code-and-Fix"
printf '%s\n' "$appendix_text" | grep -q "Timeboxing (без снижения требований качества/безопасности)"
printf '%s\n' "$appendix_text" | grep -q "Evidence-anchored AI"
printf '%s\n' "$appendix_text" | grep -q "AI не имеет права генерировать claims без evidence_refs"

if printf '%s\n' "$appendix_text" | rg -n "быстро накидать" >/dev/null; then
  printf '%s\n' "$appendix_text" | grep -q 'Никаких "быстро накидать"'
fi

if printf '%s\n' "$appendix_text" | rg -n "ослаб(ить|ления).*(качеств|безопасност).*ради скорост" >/dev/null; then
  echo "forbidden weakening phrase detected in Lens Catalog appendix"
  exit 1
fi

grep -q "^Class: Primary$" "$LENS_REPORT"
grep -q "^Class: Secondary$" "$LENS_REPORT"
grep -q "^Class: Anti-pattern$" "$LENS_REPORT"
grep -q "Primary: отсутствие артефактов = блокирующий gap" "$LENS_REPORT"
grep -q "Secondary: gap фиксируется только если мы решили использовать" "$LENS_REPORT"
grep -q "Anti-pattern: фиксируются только признаки/риски, без плана внедрения" "$LENS_REPORT"

echo "stage28 lens gate: OK"
