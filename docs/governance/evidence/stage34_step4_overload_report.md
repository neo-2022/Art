# Stage34 Overload Report (2x/3x)

| factor | events | requests | accepted | p95_ms | p99_ms | throughput_eps | budget_p95_ms | data_path_ok |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 2x | 20000 | 100 | 20000 | 46 | 54 | 6415.99 | 240 | PASS |
| 3x | 30000 | 150 | 30000 | 65 | 67 | 4792.41 | 360 | PASS |

- p95 degradation ratio (3x/2x): 1.413
- Verdict: PASS (controlled degradation, no data-path loss)
