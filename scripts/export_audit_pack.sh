#!/usr/bin/env bash
set -euo pipefail
FROM=""; TO=""; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2;;
    --to) TO="$2"; shift 2;;
    --out_dir) OUT="$2"; shift 2;;
    *) echo "unknown arg: $1"; exit 2;;
  esac
done
if [[ -z "$FROM" || -z "$TO" || -z "$OUT" ]]; then
  echo '{"event_name":"observability_gap.export_failed","reason":"missing_args"}' >&2
  exit 1
fi
if [[ "${EFFECTIVE_PROFILE_ID:-}" == "ru" ]]; then
  echo '{"event_name":"observability_gap.cross_border_export_blocked","effective_profile_id":"ru","blocked":true}' >&2
  exit 1
fi
if [[ "${FORCE_EXPORT_FAIL:-0}" == "1" ]]; then
  echo '{"event_name":"observability_gap.export_failed","reason":"forced_failure"}' >&2
  exit 1
fi
mkdir -p "$OUT"
cat > "$OUT/incidents.json" <<JSON
[{"id":"inc-1","severity":"sev2","title":"test incident"}]
JSON
cat > "$OUT/audit.json" <<JSON
[{"timestamp":"$FROM","actor_id":"system","action":"export"}]
JSON
python3 - "$OUT" "$FROM" "$TO" <<'PY'
import csv, json, pathlib, sys, hashlib
out = pathlib.Path(sys.argv[1])
from_ts, to_ts = sys.argv[2], sys.argv[3]
inc = json.loads((out/'incidents.json').read_text())
aud = json.loads((out/'audit.json').read_text())
with (out/'incidents.csv').open('w', encoding='utf-8', newline='') as f:
    w=csv.DictWriter(f, fieldnames=['id','severity','title'])
    w.writeheader(); w.writerows(inc)
with (out/'audit.csv').open('w', encoding='utf-8', newline='') as f:
    w=csv.DictWriter(f, fieldnames=['timestamp','actor_id','action'])
    w.writeheader(); w.writerows(aud)
(out/'meta.json').write_text(json.dumps({
    'build_id':'local', 'effective_profile_id':'global', 'export_window':{'from':from_ts,'to':to_ts}, 'generated_at':'2026-03-05T00:00:00Z'
}, ensure_ascii=False, indent=2), encoding='utf-8')
checks=[]
for name in ['incidents.json','incidents.csv','audit.json','audit.csv','meta.json']:
    b=(out/name).read_bytes()
    checks.append(f"{hashlib.sha256(b).hexdigest()}  {name}")
(out/'checksums.txt').write_text('\n'.join(checks)+'\n', encoding='utf-8')
PY
