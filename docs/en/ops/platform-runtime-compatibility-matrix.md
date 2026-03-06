# Platform Runtime Compatibility Matrix

## Source of truth
- `formats/platform_support.yaml`
- `docs/en/ops/platform-support.md`
- `docs/en/ops/platform-container-k8s-testing.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Goal
Define minimum versions and mandatory production scenarios required to claim runtime compatibility across Linux/VM/Docker/Kubernetes surfaces.

## Version matrix (mandatory)
| Surface | Minimum | Target range | Release blocker |
|---|---:|---:|---|
| Linux kernel | 5.10 | 5.10–6.8 | critical runtime mismatch |
| systemd | 247 | 247+ | unit contract failure |
| Docker Engine | 24.0 | 24.x–27.x | docker smoke execute FAIL |
| Kubernetes | 1.28 | 1.28–1.31 | k8s smoke execute FAIL |
| kind | 0.22 | 0.22+ | kind execute smoke FAIL |
| k3d | 5.6 | 5.6+ | k3d execute smoke FAIL |

## Mandatory Kubernetes production scenarios
1. TLS ingress path (cert-manager secret wiring) passes end-to-end.
2. Persistent storage path passes create/restart/recover.
3. Rolling update (zero-downtime gate) preserves health/stream contracts.
4. Node pressure/drain scenario preserves recovery correctness.
5. RBAC/policy path blocks forbidden actions and emits audit evidence.

## Release blockers (strict)
- Any execute-smoke FAIL on mandatory surfaces defined in `formats/platform_support.yaml`.
- Any version-matrix mismatch outside allowed ranges.
- Any Kubernetes production scenario FAIL.
- Any missing evidence from:
  - `EVIDENCE_VM_MATRIX_READINESS`
  - `EVIDENCE_DOCKER_SMOKE`
  - `EVIDENCE_K8S_SMOKE`
  - `EVIDENCE_CONTAINER_TEST_docker`
  - `EVIDENCE_CONTAINER_TEST_kubernetes`

## CI now
- `ENABLE_NATURAL_MATRIX=false`: validate gates are mandatory, execute jobs are skipped.
- `ENABLE_NATURAL_MATRIX=true`: execute smokes become mandatory release gates.
