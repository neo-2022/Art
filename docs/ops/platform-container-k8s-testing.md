# Platform Container/Kubernetes Testing (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `tests/platform/container/run_docker_smoke.sh`
- `tests/platform/k8s/run_k8s_smoke.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Зачем это нужно
Docker и Kubernetes — отдельные рабочие платформы запуска продукта. Проверка только "native Linux" недостаточна: нужна отдельная совместимость container-runtime и k8s-runtime, чтобы продукт был предсказуем в production-контурах orchestrated deployment.

## Что уже заложено
- Docker smoke harness: `tests/platform/container/run_docker_smoke.sh`.
- Kubernetes smoke harness: `tests/platform/k8s/run_k8s_smoke.sh`.
- K8s профили: `tests/platform/k8s/profiles/kind-default.env`, `tests/platform/k8s/profiles/k3d-default.env`.
- CI-gate: `scripts/ci/check_platform_container_k8s_skeletons.sh`.

## Режим CI сейчас
- Текущий режим: `ENABLE_NATURAL_MATRIX=false`.
- Docker/K8s контуры проходят validate-режим в CI как обязательные контракты.
- Execute-режим (реальный runtime smoke) включается на выделенных runner-ах, без изменений продуктового кода.

## Docker smoke
### Validate
```bash
MODE=validate tests/platform/container/run_docker_smoke.sh
```

### Execute
```bash
MODE=execute tests/platform/container/run_docker_smoke.sh
```

## Kubernetes smoke
### Validate
```bash
MODE=validate K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

### Execute
```bash
MODE=execute K8S_PROVIDER=kind K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

## Evidence IDs
- `EVIDENCE_DOCKER_SMOKE`
- `EVIDENCE_K8S_SMOKE`
- `EVIDENCE_CONTAINER_TEST_docker`
- `EVIDENCE_CONTAINER_TEST_kubernetes`

## Критичное правило
Платформенная совместимость Docker/Kubernetes реализуется через packaging/deploy/tests. Логика `core/agent/browser` не должна ветвиться по среде запуска.
