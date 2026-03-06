# CHECKLIST 43 — Safe Action Intelligence + Sandbox
Файл: CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md
Последняя актуализация: 2026-03-06
Дата последней проверки: не выполнялась
Триггер пересмотра: изменение action simulation, action sandbox, NRAC policy
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Довести action intelligence до безопасного и воспроизводимого состояния: before-execute simulation, bounded-regret reasoning и безопасная extensibility.

Важно:
- preflight-first, policy-as-ui, NRAC hooks и safe extensibility должны учитываться уже в этапах 31, 33, 34 и 37;
- stage43 закрывает специализированный intelligent-action hardening path.

## Границы
- Включено: Counterfactual Action Simulator, NRAC maturation, Wasm sandbox for actions.
- Исключено: скрытые side effects и silent plugin execution.

## Зависимости
- CHECKLIST 42 
- CHECKLIST 33 

## Шаги (строго линейно)
- [ ] 1. Сделать: внедрить Counterfactual Action Simulator для what-if анализа до execute.
  - [ ] Проверка (pass/fail): simulator даёт no-side-effect прогноз с evidence/assumptions/confidence.
  - [ ] Артефакт результата: simulator spec + integration log.
- [ ] 2. Сделать: расширить NRAC до enforceable production policy.
  - [ ] Проверка (pass/fail): destructive/high-impact action cannot execute without bounded-regret certificate or explicit policy exception.
  - [ ] Артефакт результата: NRAC policy report + negative test log.
- [ ] 3. Сделать: внедрить Wasm sandbox для расширяемых action adapters.
  - [ ] Проверка (pass/fail): sandbox blocks forbidden syscalls/capabilities and emits auditable execution record.
  - [ ] Артефакт результата: sandbox test log + audit artifact.
- [ ] 4. Сделать: связать simulator/NRAC/sandbox с preflight/audit/investigation chain.
  - [ ] Проверка (pass/fail): full chain `simulation -> certificate -> execution -> audit -> investigation attachment` воспроизводима.
  - [ ] Артефакт результата: e2e chain report.
- [ ] 5. Сделать: зарегистрировать observability-gap для деградации action-intelligence контура.
  - [ ] Событие: `observability_gap.action_intelligence_degraded`.
  - [ ] evidence_min: `action_id`, `policy_mode`, `simulation_status`, `sandbox_status`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/action_intelligence_degraded.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.

## Документация (RU)
- [ ] docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md
- [ ] docs/source/secure_actions_protocol_v2.md
- [ ] docs/runbooks/action_intelligence_degraded.md

## Тестирование
- [ ] unit: simulation model and sandbox capability policy.
- [ ] integration: NRAC + preflight + audit chain.
- [ ] e2e: blocked action without certificate.
- [ ] security: sandbox escape negative suite.
- [ ] soak: repeated simulation/execution consistency.
- [ ] perf: simulation path budget.

## CI gate
- [ ] `stage43-safe-action-intelligence-gate`

## DoD
- [ ] Action intelligence стал реально безопасным и auditable.
- [ ] Counterfactual simulation и NRAC стали enforceable, а не только описательными.
- [ ] observability-gap событие этапа 43 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_44 запрещён до полного закрытия CHECKLIST_43.
- Артефакты закрытия: simulation logs + NRAC logs + sandbox suite + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
