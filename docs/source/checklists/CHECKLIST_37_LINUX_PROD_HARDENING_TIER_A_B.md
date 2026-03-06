# CHECKLIST 37 — Linux Production Hardening (Tier A/B)
Файл: CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение Linux rollout/rollback, readiness suites, alert gates, DNA canary policy

## Цель
Подготовить Linux-only production hardening для Tier A Panel0 и Tier B Console с обязательной безопасностью rollout DNA Core.

## Границы
- Включено: canary rollout, alert gates, rollback drills, readiness suites.
- Включено: dual-run контроль DNA на canary и feature-flag rollback.
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

## Документация (RU)
- [ ] docs/ops/panel0_linux_prod_readiness.md
- [ ] docs/ops/console_linux_prod_readiness.md
- [ ] docs/source/dna_core_determinism_performance_assurance.md
- [ ] docs/ops/art_regart_contract_parity.md
- [ ] docs/ops/operational_debt_register.md
- [ ] docs/runbooks/console_linux_readiness_failed.md
- [ ] docs/runbooks/dna_canary_divergence.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] e2e: Linux headless сценарии Panel0 + Console.
- [ ] integration: alert gate и rollback consistency.
- [ ] integration: DNA canary divergence stop condition.
- [ ] integration: privacy alert gate по evidence access anomalies.
- [ ] integration: Art <-> REGART contract parity check.
- [ ] chaos: Core DOWN + Console DOWN + recovery.
- [ ] load: readiness under sustained traffic.
- [ ] soak: длительный backlog/recovery прогон.

## CI gate
- [ ] `stage37-linux-hardening-gate`

## DoD
- [ ] Linux rollout/rollback воспроизводим и документирован.
- [ ] Alert gates блокируют rollout при превышении порога.
- [ ] DNA divergence автоматически останавливает rollout.
- [ ] observability-gap события этапа 37 зарегистрированы и имеют runbook.
- [ ] Operational debt register ведётся и не содержит просроченных critical debt без mitigation.
- [ ] Риски R5 и R9 из risk register закрыты rollout controls и alert gates.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_38 запрещён до полного закрытия CHECKLIST_37.
- Артефакты закрытия: readiness/rollback/canary logs + registry/runbook diff.
