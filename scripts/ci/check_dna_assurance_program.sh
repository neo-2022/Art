#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "docs/source/dna_core_determinism_performance_assurance.md"
  "docs/contracts/v2/dna_model/README.md"
  "docs/contracts/v2/dna_model/dna_core_clusterization.tla"
  "docs/contracts/v2/dna_model/dna_core_clusterization.cfg"
  "docs/runbooks/dna_determinism_violation.md"
  "docs/runbooks/dna_reference_mismatch.md"
  "docs/runbooks/dna_canary_divergence.md"
  "docs/runbooks/dna_replay_mismatch.md"
  "scripts/ci/run_stage29_dna_tests.sh"
  "scripts/ci/run_stage29_dna_property_million.sh"
  "scripts/tests/stage34_perf_load_smoke.sh"
  "scripts/tests/dna_reference_impl.py"
  "docs/ops/runtime_incident_status.json"
)

for file in "${required_files[@]}"; do
  test -s "$file"
done

python3 - "docs/ops/runtime_incident_status.json" <<'PY'
import json, pathlib, sys
obj = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
for key in ("open_determinism_incidents", "open_canary_divergence_incidents"):
    if key not in obj:
        raise SystemExit(f"missing key in runtime incident status: {key}")
PY

DOC="docs/source/dna_core_determinism_performance_assurance.md"

grep -q "## Этап 0" "$DOC"
grep -q "## Этап 1" "$DOC"
grep -q "## Этап 2" "$DOC"
grep -q "## Этап 3" "$DOC"
grep -q "## Этап 4" "$DOC"
grep -q "## Этап 5" "$DOC"
grep -q "## Этап 6" "$DOC"
grep -q "## Этап 7" "$DOC"
grep -q "1 000 000" "$DOC"
grep -q "10k/сек" "$DOC"
grep -q "100k/сек" "$DOC"
grep -q "5%" "$DOC"

grep -q "dna_property_determinism_million_sequences_gate" core/src/main.rs
grep -q "dna_property_determinism_proptest" core/src/main.rs
grep -q "dna_reference_implementation_parity_corpus" core/src/main.rs
grep -q "dna_mutation_resilience_sentinel_test" core/src/main.rs

grep -q "stage29-dna-assurance-gate" .github/workflows/ci.yml
grep -q "stage29-dna-property-million" .github/workflows/ci.yml
grep -q "stage34-perf-load-tests" .github/workflows/ci.yml
grep -q "stage37-linux-hardening-gate" .github/workflows/ci.yml

for event in \
  observability_gap.dna_determinism_violation \
  observability_gap.dna_reference_mismatch \
  observability_gap.dna_canary_divergence \
  observability_gap.dna_replay_mismatch
  do
  grep -q "^| ${event} |" docs/governance/observability_gap_registry.md
done

echo "dna assurance program gate: OK"
