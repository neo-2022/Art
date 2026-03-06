# Platform Container/Kubernetes Testing (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `tests/platform/container/run_docker_smoke.sh`
- `tests/platform/k8s/run_k8s_smoke.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Why this matters
Docker and Kubernetes are first-class runtime platforms. Native Linux-only testing is not sufficient: container-runtime and k8s-runtime compatibility must be explicitly validated for production-grade deployments.

## What is already in place
- Docker smoke harness: `tests/platform/container/run_docker_smoke.sh`.
- Kubernetes smoke harness: `tests/platform/k8s/run_k8s_smoke.sh`.
- K8s profiles: `tests/platform/k8s/profiles/kind-default.env`, `tests/platform/k8s/profiles/k3d-default.env`.
- CI gate: `scripts/ci/check_platform_container_k8s_skeletons.sh`.

## Current CI mode
- Current mode: `ENABLE_NATURAL_MATRIX=false`.
- Docker/K8s tracks run in mandatory validate mode for structure.
- Docker execute-smoke and Kubernetes execute-smoke also run on the Ubuntu runner as production runtime gates.
- `ENABLE_NATURAL_MATRIX=true` is still reserved for expanding the native distro matrix, not for container execute paths.

## Docker smoke
### Validate
```bash
MODE=validate tests/platform/container/run_docker_smoke.sh
```

### Execute
```bash
MODE=execute tests/platform/container/run_docker_smoke.sh
```

Execute path must:
- build static `art-core` and `art-agent`;
- build runtime images;
- start both containers;
- pass `health -> ingest -> snapshot/stream -> safe action(noop) -> audit verify`;
- emit `EVIDENCE_DOCKER_SMOKE` and `EVIDENCE_CONTAINER_TEST_docker`.

## Kubernetes smoke
### Validate
```bash
MODE=validate K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

### Execute
```bash
MODE=execute K8S_PROVIDER=kind K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh
```

Execute path must:
- build static runtime images;
- create an ephemeral cluster (`kind` or `k3d`);
- deploy core/agent;
- pass `health -> ingest -> snapshot/stream -> safe action(noop) -> audit verify` through port-forward;
- emit `EVIDENCE_K8S_SMOKE` and `EVIDENCE_CONTAINER_TEST_kubernetes`.

## Evidence IDs
- `EVIDENCE_DOCKER_SMOKE`
- `EVIDENCE_K8S_SMOKE`
- `EVIDENCE_CONTAINER_TEST_docker`
- `EVIDENCE_CONTAINER_TEST_kubernetes`

## Critical rule
Docker/Kubernetes compatibility must be implemented via packaging/deploy/tests layers only. `core/agent/browser` runtime logic must remain environment-agnostic.
