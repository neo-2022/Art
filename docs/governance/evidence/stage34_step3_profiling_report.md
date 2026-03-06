# Stage34 Profiling Report (CPU/Memory hot paths)

## Profiling context
- Toolchain: runtime load profile test + `/usr/bin/time -v`.
- `perf`/flamegraph direct capture unavailable in this environment (`perf_event_paranoid=4`).
- Target workload: `/api/v2/ingest` with `steady/burst/skewed` at `10k` and `100k`.

## Runtime resource summary
- User CPU time (s): 163.70
- System CPU time (s): 4.86
- Max RSS (KB): 215668

## Top CPU hotspots (by request p95 latency)
1. `steady-100k`: p95=193ms, p99=201ms, throughput=1830.02 eps
2. `burst-100k`: p95=192ms, p99=199ms, throughput=1821.10 eps
3. `skewed-100k`: p95=192ms, p99=197ms, throughput=1821.30 eps

## Top heap pressure profiles (by event volume)
1. `steady-100k`: events=100000, p95=193ms
2. `burst-100k`: events=100000, p95=192ms
3. `skewed-100k`: events=100000, p95=192ms

## Remediation actions
1. Keep burst/skewed scenarios on dedicated CI workers to avoid noisy-neighbor variance.
2. Prioritize optimization of DNA canonicalization path used by 100k profiles.
3. Add memory snapshots around local-store-heavy profile in Stage34 step 11 to bound heap growth.
4. Enable perf/flamegraph capture on privileged runner and attach `perf.data` artifacts in nightly runs.
