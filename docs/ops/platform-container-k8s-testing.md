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
- Docker/K8s контуры проходят validate-режим как структурный контракт.
- Дополнительно Docker execute-smoke и Kubernetes execute-smoke уже исполняются на Ubuntu runner как production runtime gates.
- `ENABLE_NATURAL_MATRIX=true` по-прежнему нужен только для расширения native distro matrix, а не для контейнерных execute-path.

## Docker smoke
### Validate
```bash
MODE=validate tests/platform/container/run_docker_smoke.sh
```

### Execute
```bash
MODE=execute tests/platform/container/run_docker_smoke.sh
```

Execute-path обязан:
- собрать статические `art-core` и `art-agent`;
- собрать runtime images;
- поднять оба контейнера;
- пройти `health -> ingest -> snapshot/stream -> safe action(noop) -> audit verify`;
- сохранить evidence `EVIDENCE_DOCKER_SMOKE` и `EVIDENCE_CONTAINER_TEST_docker`.

## Kubernetes smoke
### Validate
```bash
MODE=validate K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

### Execute
```bash
MODE=execute K8S_PROVIDER=kind K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

Execute-path обязан:
- собрать статические runtime images;
- поднять ephemeral cluster (`kind` или `k3d`);
- задеплоить core/agent;
- пройти `health -> ingest -> snapshot/stream -> safe action(noop) -> audit verify` через port-forward;
- сохранить evidence `EVIDENCE_K8S_SMOKE` и `EVIDENCE_CONTAINER_TEST_kubernetes`.

## Evidence IDs
- `EVIDENCE_DOCKER_SMOKE`
- `EVIDENCE_K8S_SMOKE`
- `EVIDENCE_CONTAINER_TEST_docker`
- `EVIDENCE_CONTAINER_TEST_kubernetes`

## Критичное правило
Платформенная совместимость Docker/Kubernetes реализуется через packaging/deploy/tests. Логика `core/agent/browser` не должна ветвиться по среде запуска.
