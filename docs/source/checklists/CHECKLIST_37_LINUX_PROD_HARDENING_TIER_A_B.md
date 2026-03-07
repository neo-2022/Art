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
- [ ] 1. Сделать: Linux canary protocol (1 инстанс, полный набор gates).
  - [ ] Проверка (pass/fail): canary readiness suite PASS.
  - [ ] Артефакт результата: canary report.
- [ ] 2. Сделать: alert gate `observability_gap.console_boot_failed > 5/5m` на инстанс.
  - [ ] Проверка (pass/fail): alert simulation PASS.
  - [ ] Артефакт результата: simulation log.
- [ ] 3. Сделать: DNA canary divergence control (new vs stable output compare).
  - [ ] Проверка (pass/fail): divergence monitor включён; при расхождении rollout останавливается.
  - [ ] Артефакт результата: canary divergence check log.
- [ ] 4. Сделать: feature flag `dna_core_v2_enabled` и fallback режим raw-events.
  - [ ] Проверка (pass/fail): при выключении флага Console остаётся работоспособной в режиме ограниченной функциональности.
  - [ ] Артефакт результата: fallback test report.
- [ ] 5. Сделать: rollback protocol до stable tag + consistency verify.
  - [ ] Проверка (pass/fail): rollback drill PASS.
  - [ ] Артефакт результата: rollback drill report.
- [ ] 6. Сделать: Linux readiness suites для Panel0 и Console.
  - [ ] Проверка (pass/fail): `scripts/tests/panel0_linux_prod_readiness.sh` и `scripts/tests/console_linux_prod_readiness.sh` PASS.
  - [ ] Артефакт результата: readiness logs.
- [ ] 7. Сделать: observability-gap контроль Linux readiness и canary divergence провалов.
  - [ ] События:
    - `observability_gap.console_linux_readiness_failed`
    - `observability_gap.dna_canary_divergence`
  - [ ] evidence_min:
    - `console_linux_readiness_failed`: `suite`, `scenario`, `error`, `build_id`, `trace_id`.
    - `dna_canary_divergence`: `canary_build_id`, `stable_build_id`, `dna_id`, `divergence_rate`, `trace_id`.
  - [ ] action_ref:
    - `docs/runbooks/console_linux_readiness_failed.md`
    - `docs/runbooks/dna_canary_divergence.md`
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 8. Сделать: добавить cross-repo contract parity check (Art <-> REGART) для интеграционного контура.
  - [ ] Проверка (pass/fail): parity report подтверждает совместимость обязательных контрактов и примеров событий.
  - [ ] Артефакт результата: parity report + gate log.
- [ ] 9. Сделать: вести operational debt register для production-risk хвостов.
  - [ ] Проверка (pass/fail): `docs/ops/operational_debt_register.md` существует и содержит `owner`, `risk`, `due_date`, `status`, `mitigation`.
  - [ ] Артефакт результата: debt register diff + review log.
- [ ] 10. Сделать: ввести Linux anti-breakage suite для интерфейсной лестницы L0/L1/L2.
  - [ ] Проверка (pass/fail): suite подтверждает, что после rollout сохраняются базовые сценарии shell, truth modes, investigation library и flow mode inspectability.
  - [ ] Артефакт результата: interface anti-breakage report.
- [ ] 11. Сделать: ввести OS-матрицу как единый контракт поддержки платформ.
  - [ ] Проверка (pass/fail): `formats/platform_support.yaml` существует и используется gate-скриптами.
  - [ ] Артефакт результата: matrix yaml + gate log.
- [ ] 12. Сделать: реализовать certified profile contract (без dynamic loading, allowlist deps, reproducible profile flags).
  - [ ] Проверка (pass/fail): `scripts/ci/check_certified_profile.sh` PASS.
  - [ ] Артефакт результата: certified gate log.
- [ ] 13. Сделать: добавить platform contract tests и install skeletons под все distro из матрицы.
  - [ ] Проверка (pass/fail): `tests/platform/contract/run_contract_suite.sh` PASS и `scripts/ci/check_platform_install_skeletons.sh` PASS.
  - [ ] Проверка (pass/fail): `tests/platform/contract/check_docker_runtime_contract.sh` PASS.
  - [ ] Артефакт результата: contract suite log + install skeleton validation log.
- [ ] 14. Сделать: добавить CI-matrix jobs (Ubuntu enabled, остальные disabled через `ENABLE_NATURAL_MATRIX=false`).
  - [ ] Проверка (pass/fail): `.github/workflows/platform_matrix_stage37.yml` валиден; `ubuntu-smoke` PASS; natural jobs помечены условием флага.
  - [ ] Артефакт результата: workflow run log + job list.
- [ ] 15. Сделать: обеспечить RU/EN docs sync для платформенной части.
  - [ ] Проверка (pass/fail): `scripts/ci/check_platform_docs_sync.sh` PASS.
  - [ ] Артефакт результата: docs sync gate log.
- [ ] 16. Сделать: заложить VM-based natural testing для multi-Linux без железа.
  - [ ] Проверка (pass/fail): `tests/platform/vm/run_vm_smoke.sh` существует, `MODE=validate` PASS для `DISTRO=ubuntu` и для профиля из level A (`DISTRO=astra_linux_se`).
  - [ ] Проверка (pass/fail): `scripts/ci/check_platform_vm_skeletons.sh` PASS.
  - [ ] Артефакт результата: VM harness plan/log + VM profile matrix.
- [ ] 17. Сделать: включить Docker и Kubernetes как обязательные платформы тестирования.
  - [ ] Проверка (pass/fail): `tests/platform/container/run_docker_smoke.sh` и `tests/platform/k8s/run_k8s_smoke.sh` существуют и проходят `MODE=validate`.
  - [ ] Проверка (pass/fail): `scripts/ci/check_platform_container_k8s_skeletons.sh` PASS.
  - [ ] Проверка (pass/fail): workflow содержит jobs `docker-smoke` и `kubernetes-smoke`.
  - [ ] Артефакт результата: container/k8s smoke plan/log + workflow diff.
- [ ] 18. Сделать: зафиксировать runtime compatibility version matrix (Linux/systemd/Docker/K8s/kind/k3d) как release policy.
  - [ ] Проверка (pass/fail): `formats/platform_support.yaml` содержит `runtime_compatibility_matrix` и release blockers.
  - [ ] Проверка (pass/fail): `scripts/ci/check_platform_runtime_compatibility.sh` PASS.
  - [ ] Артефакт результата: matrix doc diff + gate log.
- [ ] 19. Сделать: заложить обязательные Kubernetes production-сценарии (TLS ingress, persistent storage recovery, rolling update, node drain/pressure, RBAC audit).
  - [ ] Проверка (pass/fail): сценарии зафиксированы в source-of-truth и runtime compatibility docs.
  - [ ] Проверка (pass/fail): `MODE=validate K8S_PROFILE=kind-default tests/platform/k8s/run_k8s_smoke.sh` PASS.
  - [ ] Артефакт результата: k8s production scenarios matrix + smoke validate log.
- [ ] 20. Сделать: зафиксировать строгие release-blockers для VM/Docker/K8s совместимости.
  - [ ] Проверка (pass/fail): release-blockers описаны в `formats/platform_support.yaml` и `docs/ops/platform-runtime-compatibility-matrix.md`.
  - [ ] Проверка (pass/fail): stage37 CI-gates проверяют наличие blocker policy.
  - [ ] Артефакт результата: policy diff + CI gate log.
 - [ ] 21. Сделать: зафиксировать Linux-ready контур agent/bridge interaction для REGART и Console.
   - [ ] Проверка (pass/fail): systemd/Linux readiness учитывает `Level0 -> Art bridge`, `UI Proxy -> Art`, `agent backlog/recovery`, `human-agent interaction safety`.
   - [ ] Проверка (pass/fail): anti-breakage suite подтверждает, что locale, agent proposal path и evidence-first labels не ломаются в Linux headless/profiled режиме.
   - [ ] Артефакт результата: Linux agent-interaction readiness report.
- [ ] 22. Сделать: заложить Linux policy boundary для будущего forensic/ebpf/sandbox контура.
  - [ ] Проверка (pass/fail): platform docs и risk register фиксируют kernel/profile/privacy ограничения для `eBPF evidence linking` и capability policy для `Wasm sandbox`.
  - [ ] Проверка (pass/fail): production hardening описывает opt-in boundary и release blockers до stage45.
  - [ ] Артефакт результата: Linux policy boundary diff + risk update log.
- [ ] 23. Сделать: зафиксировать Linux multi-site/WAN/segmented deployment boundary для Art Agent.
  - [ ] Проверка (pass/fail): platform docs фиксируют:
    - [ ] agent install path для `systemd`, `container`, `DaemonSet`, `air-gapped package`
    - [ ] transport path через direct Core ingest или relay/approved bridge
    - [ ] обязательный локальный spool/outbox при WAN/segment break
    - [ ] запрет молчаливой потери данных при network partition
    - [ ] Linux-ready команды проверки backlog/health/replay
  - [ ] Проверка (pass/fail): `docs/ops/agent_multisite_deploy.md` и `docs/source/agent_deployment_transport_v0_2.md` согласованы с `formats/platform_support.yaml`.
  - [ ] Артефакт результата: multi-site Linux deployment report.
- [ ] 24. Сделать: зафиксировать и проверить Linux ingress/perimeter shield baseline для internet-exposed deployments.
  - [ ] reference architecture определяет front-door / reverse-proxy / ingress shield до `art-core`
  - [ ] Linux production profile содержит:
    - [ ] per-IP/per-source rate policy
    - [ ] connection limits
    - [ ] burst limits
    - [ ] controlled degraded mode при деградации shield
  - [ ] hostile ingress validate-path фиксирует:
    - [ ] `observability_gap.ddos_suspected`
    - [ ] `observability_gap.ingress_shield_degraded`
  - [ ] internet-exposed Linux rollout без shield baseline считается release blocker
  - [ ] **Проверка (pass/fail):** docs, registry, runbooks и Linux hostile-ingress validate log согласованы.
  - [ ] Артефакт результата: perimeter hardening report + hostile ingress validate log.
- [ ] 25. Сделать: зафиксировать production blockers Linux-профиля по trust boundary и browser surface hardening.
  - [ ] Linux production profile запрещён без trusted actor context proof для privileged paths.
  - [ ] Linux internet-exposed browser/profile path запрещён без browser surface hardening baseline.
  - [ ] `stage37-linux-hardening-gate` валится при отсутствии этих proof/doc/runbook связок.
  - [ ] **Проверка (pass/fail):** Linux hardening gate подтверждает trust boundary/browser surface blockers как production baseline.
  - [ ] Артефакт результата: stage37 protective contour gate log.

## Документация (RU)
- [ ] docs/ops/panel0_linux_prod_readiness.md
- [ ] docs/ops/console_linux_prod_readiness.md
- [ ] docs/ops/platform-support.md
- [ ] docs/en/ops/platform-support.md
- [ ] docs/ops/platform-vm-testing.md
- [ ] docs/en/ops/platform-vm-testing.md
- [ ] docs/ops/platform-container-k8s-testing.md
- [ ] docs/en/ops/platform-container-k8s-testing.md
- [ ] docs/ops/platform-runtime-compatibility-matrix.md
- [ ] docs/en/ops/platform-runtime-compatibility-matrix.md
- [ ] docs/security/fstec-certified-profile.md
- [ ] docs/en/security/fstec-certified-profile.md
- [ ] docs/source/dna_core_determinism_performance_assurance.md
- [ ] docs/ops/art_regart_contract_parity.md
- [ ] docs/ops/operational_debt_register.md
- [ ] docs/runbooks/console_linux_readiness_failed.md
- [ ] docs/runbooks/dna_canary_divergence.md
- [ ] docs/source/risk_register_v0_2.md
- [ ] docs/source/console_agent_interaction_model_v0_2.md
- [ ] docs/source/agent_deployment_transport_v0_2.md
- [ ] docs/ops/agent_multisite_deploy.md
- [ ] docs/source/ingress_perimeter_protection_v0_2.md
- [ ] docs/runbooks/ddos_suspected.md
- [ ] docs/runbooks/ingress_shield_degraded.md
- [ ] docs/source/trust_boundary_hardening_v0_2.md
- [ ] docs/source/browser_surface_hardening_v0_2.md
- [ ] docs/runbooks/trust_boundary_violation.md
- [ ] docs/runbooks/browser_surface_policy_degraded.md

## Тестирование
- [ ] e2e: Linux headless сценарии Panel0 + Console.
- [ ] integration: alert gate и rollback consistency.
- [ ] integration: DNA canary divergence stop condition.
- [ ] integration: privacy alert gate по evidence access anomalies.
- [ ] integration: Art <-> REGART contract parity check.
- [ ] chaos: Core DOWN + Console DOWN + recovery.
- [ ] load: readiness under sustained traffic.
- [ ] soak: длительный backlog/recovery прогон.
- [ ] regression: L0/L1/L2 interface anti-breakage под Linux canary.
- [ ] regression: Linux headless agent interaction and locale/evidence labels anti-breakage.
- [ ] vm: validate-mode smoke для Ubuntu и одного A-level distro в VM harness.
- [ ] container: Docker smoke validate/execute сценарии.
- [ ] container: Kubernetes smoke validate/execute сценарии (kind/k3d profile).
- [ ] compatibility: version matrix checks (Linux/systemd/Docker/K8s/kind/k3d).
- [ ] k8s: production scenarios checklist validate path.

## CI gate
- [ ] `stage37-linux-hardening-gate`
- [ ] `platform-matrix-contract-gate`
- [ ] `platform-vm-skeleton-gate`
- [ ] `platform-container-k8s-skeleton-gate`
- [ ] `platform-runtime-compatibility-gate`
- [ ] `docker-smoke`
- [ ] `kubernetes-smoke`
- [ ] `ubuntu-smoke` (stage37-platform-matrix workflow)

## DoD
- [ ] Linux rollout/rollback воспроизводим и документирован.
- [ ] OS-матрица закреплена в `formats/platform_support.yaml` и используется CI/docs/gates.
- [ ] VM-матрица и VM-harness закреплены в source-of-truth и проходят validate-gates.
- [ ] Docker и Kubernetes включены как обязательные test platforms и проходят validate-gates.
- [ ] Version matrix и strict release-blockers закреплены и проверяются CI-gates.
- [ ] `general`/`certified` профили сборки реализованы и проходят contract checks на Ubuntu.
- [ ] Contract suite на Ubuntu генерирует evidence bundle, включая placeholders для natural matrix.
- [ ] Alert gates блокируют rollout при превышении порога.
- [ ] DNA divergence автоматически останавливает rollout.
- [ ] observability-gap события этапа 37 зарегистрированы и имеют runbook.
- [ ] Operational debt register ведётся и не содержит просроченных critical debt без mitigation.
- [ ] Риски R5 и R9 из risk register закрыты rollout controls и alert gates.
- [ ] Интерфейсная лестница L0/L1/L2 проходит Linux anti-breakage suite без регрессий.
- [ ] Linux-ready контур agent/bridge interaction подтверждён как production-safe.
- [ ] Linux policy boundary для будущих `eBPF`/`Wasm sandbox` возможностей зафиксирован до их финального внедрения.
- [ ] Linux multi-site/WAN/segmented deployment boundary Art Agent зафиксирован и согласован с platform matrix.
- [ ] Internet-exposed Linux production profile имеет perimeter shield baseline и hostile ingress validate-path.
- [ ] Linux production perimeter и privileged paths блокируются без trust boundary и browser surface hardening proof.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_38 запрещён до полного закрытия CHECKLIST_37.
- Артефакты закрытия: readiness/rollback/canary logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
