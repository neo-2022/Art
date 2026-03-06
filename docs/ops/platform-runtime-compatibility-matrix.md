# Platform Runtime Compatibility Matrix

## Source of truth
- `formats/platform_support.yaml`
- `docs/ops/platform-support.md`
- `docs/ops/platform-container-k8s-testing.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Цель
Зафиксировать минимальные версии и обязательные production-сценарии, после прохождения которых можно заявлять runtime-совместимость платформ Linux/VM/Docker/Kubernetes.

## Версионная матрица (обязательная)
| Surface | Минимум | Целевой диапазон | Блокер релиза |
|---|---:|---:|---|
| Linux kernel | 5.10 | 5.10–6.8 | critical runtime mismatch |
| systemd | 247 | 247+ | unit contract failure |
| Docker Engine | 24.0 | 24.x–27.x | docker smoke execute FAIL |
| Kubernetes | 1.28 | 1.28–1.31 | k8s smoke execute FAIL |
| kind | 0.22 | 0.22+ | kind execute smoke FAIL |
| k3d | 5.6 | 5.6+ | k3d execute smoke FAIL |

## Обязательные production-сценарии Kubernetes
1. TLS ingress path (cert-manager secret wiring) проходит end-to-end.
2. Persistent storage path (stateful data path) проходит create/restart/recover.
3. Rolling update (zero-downtime gate) не нарушает health/stream contracts.
4. Node pressure/drain scenario сохраняет корректность recovery.
5. RBAC/policy path блокирует запрещённые действия и фиксирует audit evidence.

## Release blockers (strict)
- Любой FAIL в execute-smoke по surface, отмеченному как enabled/mandatory в текущем release scope из `formats/platform_support.yaml`.
- Любой mismatch матрицы версий вне допустимого диапазона.
- Любой FAIL production-сценариев Kubernetes.
- Любой отсутствующий evidence из списка:
  - `EVIDENCE_VM_MATRIX_READINESS`
  - `EVIDENCE_DOCKER_SMOKE`
  - `EVIDENCE_K8S_SMOKE`
  - `EVIDENCE_CONTAINER_TEST_docker`
  - `EVIDENCE_CONTAINER_TEST_kubernetes`

## CI сейчас
- `ENABLE_NATURAL_MATRIX=false`: native distro/VM matrix остаётся validate-only.
- Docker execute-smoke и Kubernetes execute-smoke уже обязательны на Ubuntu runner.
- `ENABLE_NATURAL_MATRIX=true`: дополнительные native distro jobs становятся mandatory release gates.
