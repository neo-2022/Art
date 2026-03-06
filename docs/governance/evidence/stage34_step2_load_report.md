# Stage34 Load Report (ingest v2 + dna clustering)

| scenario | profile | events | requests | p95_ms | p99_ms | throughput_eps | budget_p95_ms | pass |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| steady-10k | steady | 10000 | 50 | 26 | 30 | 9468.14 | 120 | PASS |
| steady-100k | steady | 100000 | 500 | 193 | 199 | 1847.50 | 350 | PASS |
| burst-10k | burst | 10000 | 50 | 25 | 28 | 9675.87 | 120 | PASS |
| burst-100k | burst | 100000 | 500 | 191 | 198 | 1846.79 | 350 | PASS |
| skewed-10k | skewed | 10000 | 50 | 26 | 29 | 9463.77 | 120 | PASS |
| skewed-100k | skewed | 100000 | 500 | 187 | 195 | 1850.52 | 350 | PASS |
