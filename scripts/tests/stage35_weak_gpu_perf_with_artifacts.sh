#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
JSON_FILE="$OUT_DIR/stage35_step6_weak_gpu_perf_report.json"
MD_FILE="$OUT_DIR/stage35_step6_weak_gpu_perf_report.md"
LOG_FILE="$OUT_DIR/stage35_step6_weak_gpu_perf.log"

mkdir -p "$OUT_DIR"

node - <<'NODE' > "$LOG_FILE"
const fs = require('fs');
const { createLocalStores } = require('./packages/local-stores/dist/index.js');

function percentile(values, q) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.floor(sorted.length * q);
  return sorted[Math.min(idx, sorted.length - 1)];
}

const stores = createLocalStores();
const layoutId = 'weak-gpu-layout';
const nodeCount = 1000;
for (let i = 0; i < nodeCount; i += 1) {
  stores.setPosition(`wg-${i}`, { x: i % 100, y: Math.floor(i / 100) * 2 }, layoutId);
}
stores.spatialBuildGridIndex(layoutId, 16);

const pickSamples = [];
for (let i = 0; i < 600; i += 1) {
  const x = (i * 7) % 100;
  const y = ((i * 5) % 20) * 2;
  const started = process.hrtime.bigint();
  stores.spatialPick(layoutId, x, y, 10);
  pickSamples.push(Number(process.hrtime.bigint() - started) / 1e6);
}

const scenePerf = stores.benchmarkFlowPanZoom(nodeCount, 180);
const pickP95 = percentile(pickSamples, 0.95);
const pickP99 = percentile(pickSamples, 0.99);
const sceneP95 = scenePerf.p95_ms;
const budget = 50;

const normalGuard = stores.applyFlowGuardrail({ p95_ms: sceneP95, budget_ms: budget, error_count: 0 });
const overloadGuard = stores.applyFlowGuardrail({ p95_ms: budget + 15, budget_ms: budget, error_count: 1 });

const result = {
  profile: {
    name: 'weak-gpu',
    target_device_class: 'Intel UHD 620 / equivalent VM GPU'
  },
  budget_ms: budget,
  metrics: {
    picking_p95_ms: Number(pickP95.toFixed(3)),
    picking_p99_ms: Number(pickP99.toFixed(3)),
    scene_update_p95_ms: Number(sceneP95.toFixed(3))
  },
  guardrail: {
    normal_mode: normalGuard.mode,
    normal_downgrade_applied: normalGuard.downgrade_applied,
    overload_mode: overloadGuard.mode,
    overload_downgrade_applied: overloadGuard.downgrade_applied
  }
};

result.pass =
  result.metrics.picking_p95_ms < budget &&
  result.metrics.scene_update_p95_ms < budget &&
  result.guardrail.overload_mode === 'read-only' &&
  result.guardrail.overload_downgrade_applied === true;

fs.writeFileSync('docs/governance/evidence/stage35_step6_weak_gpu_perf_report.json', JSON.stringify(result, null, 2));
fs.writeFileSync(
  'docs/governance/evidence/stage35_step6_weak_gpu_perf_report.md',
  '# Stage35 Weak-GPU Perf Report\n\n' +
  `- profile: ${result.profile.name} (${result.profile.target_device_class})\n` +
  `- picking_p95_ms: ${result.metrics.picking_p95_ms} (budget < ${budget})\n` +
  `- scene_update_p95_ms: ${result.metrics.scene_update_p95_ms} (budget < ${budget})\n` +
  `- overload_mode: ${result.guardrail.overload_mode}\n` +
  `- overload_downgrade_applied: ${result.guardrail.overload_downgrade_applied}\n` +
  `- verdict: ${result.pass ? 'PASS' : 'FAIL'}\n`
);

console.log(JSON.stringify(result));
if (!result.pass) {
  process.exit(1);
}
NODE

cat "$LOG_FILE"
