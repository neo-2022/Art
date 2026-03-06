# CHECKLIST 37 — Linux Production Hardening (Tier A/B)
Файл: CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение Linux rollout/rollback, readiness suites, alert gates, DNA canary policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Подготовить Linux-only production hardening для Tier A Panel0 и Tier B Console с обязательной безопасностью rollout DNA Core.
Дополнительно: заложить OS-матрицу (A/B/C), certified build profile и натурные test-skeletons так, чтобы текущий CI оставался Ubuntu-only, но переход на full natural matrix включался флагом без переработки архитектуры.

## Границы
- Включено: canary rollout, alert gates, rollback drills, readiness suites.
- Включено: dual-run контроль DNA на canary и feature-flag rollback.
- Включено: единый source-of-truth `formats/platform_support.yaml`.
- Включено: build profiles `general`/`certified`, contract tests `tests/platform/contract/*`, install skeletons `tests/platform/install/*`.
- Включено: CI workflow `stage37-platform-matrix` с Ubuntu active и natural jobs under flag.
- Исключено: non-linux production targets.

## Зависимости
- CHECKLIST 16 (Panel0 baseline закрыт)
- CHECKLIST 28 (Console foundation закрыт)
- CHECKLIST 34 (perf/load/coverage закрыт)
- CHECKLIST 36 (SaaS architecture закрыт)

## Шаги (строго линейно)
- [x] 1. Сделать: Linux canary protocol (1 инстанс, полный набор gates).
  - [x] Проверка (pass/fail): canary readiness suite PASS.
  - [x] Артефакт результата: canary report.
- [x] 2. Сделать: alert gate `observability_gap.console_boot_failed > 5/5m` на инстанс.
  - [x] Проверка (pass/fail): alert simulation PASS.
  - [x] Артефакт результата: simulation log.
- [x] 3. Сделать: DNA canary divergence control (new vs stable output compare).
  - [x] Проверка (pass/fail): divergence monitor включён; при расхождении rollout останавливается.
  - [x] Артефакт результата: canary divergence check log.
- [x] 4. Сделать: feature flag `dna_core_v2_enabled` и fallback режим raw-events.
  - [x] Проверка (pass/fail): при выключении флага Console остаётся работоспособной в режиме ограниченной функциональности.
  - [x] Артефакт результата: fallback test report.
- [x] 5. Сделать: rollback protocol до stable tag + consistency verify.
  - [x] Проверка (pass/fail): rollback drill PASS.
  - [x] Артефакт результата: rollback drill report.
- [x] 6. Сделать: Linux readiness suites для Panel0 и Console.
  - [x] Проверка (pass/fail): `scripts/tests/panel0_linux_prod_readiness.sh` и `scripts/tests/console_linux_prod_readiness.sh` PASS.
  - [x] Артефакт результата: readiness logs.
- [x] 7. Сделать: observability-gap контроль Linux readiness и canary divergence провалов.
  - [x] События:
    - `observability_gap.console_linux_readiness_failed`
    - `observability_gap.dna_canary_divergence`
  - [x] evidence_min:
    - `console_linux_readiness_failed`: `suite`, `scenario`, `error`, `build_id`, `trace_id`.
    - `dna_canary_divergence`: `canary_build_id`, `stable_build_id`, `dna_id`, `divergence_rate`, `trace_id`.
  - [x] action_ref:
    - `docs/runbooks/console_linux_readiness_failed.md`
    - `docs/runbooks/dna_canary_divergence.md`
  - [x] Проверка (pass/fail): registry запись + runbook файл.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 8. Сделать: добавить cross-repo contract parity check (Art <-> REGART) для интеграционного контура.
  - [x] Проверка (pass/fail): parity report подтверждает совместимость обязательных контрактов и примеров событий.
  - [x] Артефакт результата: parity report + gate log.
- [x] 9. Сделать: вести operational debt register для production-risk хвостов.
  - [x] Проверка (pass/fail): `docs/ops/operational_debt_register.md` существует и содержит `owner`, `risk`, `due_date`, `status`, `mitigation`.
  - [x] Артефакт результата: debt register diff + review log.
- [x] 10. Сделать: ввести Linux anti-breakage suite для интерфейсной лестницы L0/L1/L2.
  - [x] Проверка (pass/fail): suite подтверждает, что после rollout сохраняются базовые сценарии shell, truth modes, investigation library и flow mode inspectability.
  - [x] Артефакт результата: interface anti-breakage report.
- [x] 11. Сделать: ввести OS-матрицу как единый контракт поддержки платформ.
  - [x] Проверка (pass/fail): `formats/platform_support.yaml` существует и используется gate-скриптами.
  - [x] Артефакт результата: matrix yaml + gate log.
- [x] 12. Сделать: реализовать certified profile contract (без dynamic loading, allowlist deps, reproducible profile flags).
  - [x] Проверка (pass/fail): `scripts/ci/check_certified_profile.sh` PASS.
  - [x] Артефакт результата: certified gate log.
- [x] 13. Сделать: добавить platform contract tests и install skeletons под все distro из матрицы.
  - [x] Проверка (pass/fail): `tests/platform/contract/run_contract_suite.sh` PASS и `scripts/ci/check_platform_install_skeletons.sh` PASS.
  - [x] Проверка (pass/fail): `tests/platform/contract/check_docker_runtime_contract.sh` PASS.
  - [x] Артефакт результата: contract suite log + install skeleton validation log.
- [x] 14. Сделать: добавить CI-matrix jobs (Ubuntu enabled, остальные disabled через `ENABLE_NATURAL_MATRIX=false`).
  - [x] Проверка (pass/fail): `.github/workflows/platform_matrix_stage37.yml` валиден; `ubuntu-smoke` PASS; natural jobs помечены условием флага.
  - [x] Артефакт результата: workflow run log + job list.
- [x] 15. Сделать: обеспечить RU/EN docs sync для платформенной части.
  - [x] Проверка (pass/fail): `scripts/ci/check_platform_docs_sync.sh` PASS.
  - [x] Артефакт результата: docs sync gate log.
- [x] 16. Сделать: заложить VM-based natural testing для multi-Linux без железа.
  - [x] Проверка (pass/fail): `tests/platform/vm/run_vm_smoke.sh` существует, `MODE=validate` PASS для `DISTRO=ubuntu` и для профиля из level A (`DISTRO=astra_linux_se`).
  - [x] Проверка (pass/fail): `scripts/ci/check_platform_vm_skeletons.sh` PASS.
  - [x] Артефакт результата: VM harness plan/log + VM profile matrix.
- [x] 17. Сделать: включить Docker и Kubernetes как обязательные платформы тестирования.
  - [x] Проверка (pass/fail): `tests/platform/container/run_docker_smoke.sh` и `tests/platform/k8s/run_k8s_smoke.sh` существуют и проходят `MODE=validate`.
  - [x] Проверка (pass/fail): `scripts/ci/check_platform_container_k8s_skeletons.sh` PASS.
  - [x] Проверка (pass/fail): workflow содержит jobs `docker-smoke` и `kubernetes-smoke`.
  - [x] Артефакт результата: container/k8s smoke plan/log + workflow diff.
- [x] 18. Сделать: зафиксировать runtime compatibility version matrix (Linux/systemd/Docker/K8s/kind/k3d) как release policy.
  - [x] Проверка (pass/fail): `formats/platform_support.yaml` содержит `runtime_compatibility_matrix` и release blockers.
  - [x] Проверка (pass/fail): `scripts/ci/check_platform_runtime_compatibility.sh` PASS.
  - [x] Артефакт результата: matrix doc diff + gate log.
- [x] 19. Сделать: заложить обязательные Kubernetes production-сценарии (TLS ingress, persistent storage recovery, rolling update, node drain/pressure, RBAC audit).
  - [x] Проверка (pass/fail): сценарии зафиксированы в source-of-truth и runtime compatibility docs.
  - [x] Проверка (pass/fail): `MODE=validate K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh` PASS.
  - [x] Артефакт результата: k8s production scenarios matrix + smoke validate log.
- [x] 20. Сделать: зафиксировать строгие release-blockers для VM/Docker/K8s совместимости.
  - [x] Проверка (pass/fail): release-blockers описаны в `formats/platform_support.yaml` и `docs/ops/platform-runtime-compatibility-matrix.md`.
  - [x] Проверка (pass/fail): stage37 CI-gates проверяют наличие blocker policy.
  - [x] Артефакт результата: policy diff + CI gate log.

## Документация (RU)
- [x] docs/ops/panel0_linux_prod_readiness.md
- [x] docs/ops/console_linux_prod_readiness.md
- [x] docs/ops/platform-support.md
- [x] docs/en/ops/platform-support.md
- [x] docs/ops/platform-vm-testing.md
- [x] docs/en/ops/platform-vm-testing.md
- [x] docs/ops/platform-container-k8s-testing.md
- [x] docs/en/ops/platform-container-k8s-testing.md
- [x] docs/ops/platform-runtime-compatibility-matrix.md
- [x] docs/en/ops/platform-runtime-compatibility-matrix.md
- [x] docs/security/fstec-certified-profile.md
- [x] docs/en/security/fstec-certified-profile.md
- [x] docs/source/dna_core_determinism_performance_assurance.md
- [x] docs/ops/art_regart_contract_parity.md
- [x] docs/ops/operational_debt_register.md
- [x] docs/runbooks/console_linux_readiness_failed.md
- [x] docs/runbooks/dna_canary_divergence.md
- [x] docs/source/risk_register_v0_2.md

## Тестирование
- [x] e2e: Linux headless сценарии Panel0 + Console.
- [x] integration: alert gate и rollback consistency.
- [x] integration: DNA canary divergence stop condition.
- [x] integration: privacy alert gate по evidence access anomalies.
- [x] integration: Art <-> REGART contract parity check.
- [x] chaos: Core DOWN + Console DOWN + recovery.
- [x] load: readiness under sustained traffic.
- [x] soak: длительный backlog/recovery прогон.
- [x] regression: L0/L1/L2 interface anti-breakage под Linux canary.
- [x] vm: validate-mode smoke для Ubuntu и одного A-level distro в VM harness.
- [x] container: Docker smoke validate/execute сценарии.
- [x] container: Kubernetes smoke validate/execute сценарии (kind/k3d profile).
- [x] compatibility: version matrix checks (Linux/systemd/Docker/K8s/kind/k3d).
- [x] k8s: production scenarios checklist validate path.

## CI gate
- [x] `stage37-linux-hardening-gate`
- [x] `platform-matrix-contract-gate`
- [x] `platform-vm-skeleton-gate`
- [x] `platform-container-k8s-skeleton-gate`
- [x] `platform-runtime-compatibility-gate`
- [x] `docker-smoke`
- [x] `kubernetes-smoke`
- [x] `ubuntu-smoke` (stage37-platform-matrix workflow)

## DoD
- [x] Linux rollout/rollback воспроизводим и документирован.
- [x] OS-матрица закреплена в `formats/platform_support.yaml` и используется CI/docs/gates.
- [x] VM-матрица и VM-harness закреплены в source-of-truth и проходят validate-gates.
- [x] Docker и Kubernetes включены как обязательные test platforms и проходят validate-gates.
- [x] Version matrix и strict release-blockers закреплены и проверяются CI-gates.
- [x] `general`/`certified` профили сборки реализованы и проходят contract checks на Ubuntu.
- [x] Contract suite на Ubuntu генерирует evidence bundle, включая placeholders для natural matrix.
- [x] Alert gates блокируют rollout при превышении порога.
- [x] DNA divergence автоматически останавливает rollout.
- [x] observability-gap события этапа 37 зарегистрированы и имеют runbook.
- [x] Operational debt register ведётся и не содержит просроченных critical debt без mitigation.
- [x] Риски R5 и R9 из risk register закрыты rollout controls и alert gates.
- [x] Интерфейсная лестница L0/L1/L2 проходит Linux anti-breakage suite без регрессий.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_38 запрещён до полного закрытия CHECKLIST_37.
- Артефакты закрытия: readiness/rollback/canary logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
