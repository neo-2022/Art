#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="docs/governance/evidence"
JSON_FILE="$OUT_DIR/stage34_step8_local_stores_perf_report.json"
MD_FILE="$OUT_DIR/stage34_step8_local_stores_perf_report.md"

mkdir -p "$OUT_DIR"

node - "$JSON_FILE" "$MD_FILE" <<'NODE'
const fs = require('fs');
const { Worker } = require('worker_threads');
const path = require('path');

const jsonPath = process.argv[2];
const mdPath = process.argv[3];

function percentile(values, q) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.floor(sorted.length * q);
  return sorted[Math.min(idx, sorted.length - 1)];
}

const workerScript = `
const { parentPort } = require('worker_threads');
const { createLocalStores } = require(${JSON.stringify(path.resolve('packages/local-stores/dist/index.js'))});

function percentile(values, q) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.floor(sorted.length * q);
  return sorted[Math.min(idx, sorted.length - 1)];
}

const stores = createLocalStores();
const insertSamples = [];
const lookupSamples = [];

for (let i = 0; i < 30000; i++) {
  const started = process.hrtime.bigint();
  stores.cachePut({ id: 'evt-' + i, dna_id: 'dna-' + (i % 300), payload: { seq: i, v: i % 17 } });
  const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;
  insertSamples.push(elapsedMs);
}

for (let i = 0; i < 4000; i++) {
  const started = process.hrtime.bigint();
  stores.findSimilarByDna('dna-' + (i % 300));
  const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;
  lookupSamples.push(elapsedMs);
}

parentPort.postMessage({
  insert_p95_ms: percentile(insertSamples, 0.95),
  insert_p99_ms: percentile(insertSamples, 0.99),
  lookup_p95_ms: percentile(lookupSamples, 0.95),
  lookup_p99_ms: percentile(lookupSamples, 0.99),
  records: 30000,
  lookups: 4000
});
`;

const worker = new Worker(workerScript, { eval: true });
const tickSamples = [];
let stopped = false;
let expected = Date.now() + 10;

const timer = setInterval(() => {
  const now = Date.now();
  tickSamples.push(Math.max(0, now - expected));
  expected += 10;
}, 10);

worker.on('message', (msg) => {
  stopped = true;
  clearInterval(timer);
  const mainLagP95 = percentile(tickSamples, 0.95);
  const mainLagP99 = percentile(tickSamples, 0.99);

  const result = {
    budgets: {
      find_similar_p95_ms: 50,
      index_update_p95_ms: 50,
      main_thread_lag_p95_ms: 20
    },
    metrics: {
      lookup_p95_ms: Number(msg.lookup_p95_ms.toFixed(3)),
      lookup_p99_ms: Number(msg.lookup_p99_ms.toFixed(3)),
      insert_p95_ms: Number(msg.insert_p95_ms.toFixed(3)),
      insert_p99_ms: Number(msg.insert_p99_ms.toFixed(3)),
      main_thread_lag_p95_ms: Number(mainLagP95.toFixed(3)),
      main_thread_lag_p99_ms: Number(mainLagP99.toFixed(3)),
      records: msg.records,
      lookups: msg.lookups
    }
  };

  result.status = {
    lookup_budget_pass: result.metrics.lookup_p95_ms <= result.budgets.find_similar_p95_ms,
    insert_budget_pass: result.metrics.insert_p95_ms <= result.budgets.index_update_p95_ms,
    main_thread_pass: result.metrics.main_thread_lag_p95_ms <= result.budgets.main_thread_lag_p95_ms
  };

  if (!Object.values(result.status).every(Boolean)) {
    console.error('Stage34 local-stores perf budget failed', result);
    process.exitCode = 1;
  }

  fs.writeFileSync(jsonPath, JSON.stringify(result, null, 2));
  const md = [
    '# Stage34 Local-Stores Perf Report',
    '',
    `- lookup_p95_ms: ${result.metrics.lookup_p95_ms} (budget <= ${result.budgets.find_similar_p95_ms})`,
    `- insert_p95_ms: ${result.metrics.insert_p95_ms} (budget <= ${result.budgets.index_update_p95_ms})`,
    `- main_thread_lag_p95_ms: ${result.metrics.main_thread_lag_p95_ms} (budget <= ${result.budgets.main_thread_lag_p95_ms})`,
    '- offload mode: heavy operations executed in Worker thread',
    `- verdict: ${Object.values(result.status).every(Boolean) ? 'PASS' : 'FAIL'}`,
    ''
  ].join('\n');
  fs.writeFileSync(mdPath, md);

  if (process.exitCode) {
    process.exit(process.exitCode);
  }
  console.log('stage34 local-stores perf report written:', mdPath);
});

worker.on('error', (err) => {
  clearInterval(timer);
  console.error(err);
  process.exit(1);
});

worker.on('exit', (code) => {
  if (!stopped && code !== 0) {
    clearInterval(timer);
    process.exit(code);
  }
});
NODE
