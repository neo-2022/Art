# CHECKLIST 33 — Secure Actions Protocol v2
Файл: CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение preflight/policy/action protocol
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Сделать протокол действий строго безопасным: preflight обязателен, policy gate обязателен, audit attach обязателен.

## Границы
- Включено: Core API policy enforcement + Action Studio protocol + audit attachment.
- Исключено: произвольные внешние action executors.

## Зависимости
- CHECKLIST 15 (RBAC/actions baseline)
- CHECKLIST 32 (audit verify закрыт)

## Шаги (строго линейно)
- [ ] 1. Сделать: preflight log обязателен для каждого action execute.
  - [ ] Проверка (pass/fail): action без preflight получает deterministic deny.
  - [ ] Артефакт результата: integration test output.
- [ ] 2. Сделать: policy-as-ui в Action Studio (доступные поля/действия только по policy).
  - [ ] Проверка (pass/fail): UI policy tests PASS.
  - [ ] Артефакт результата: UI test logs.
- [ ] 3. Сделать: action result -> audit record -> merkle proof attach.
  - [ ] Проверка (pass/fail): chain integration tests PASS.
  - [ ] Артефакт результата: action chain fixtures.
- [ ] 4. Сделать: observability-gap контроль preflight/policy нарушений.
  - [ ] Событие: `observability_gap.action_preflight_missing`.
  - [ ] evidence_min: `action`, `target`, `actor_role`, `policy_id`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/action_preflight_missing.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 5. Сделать: добавить policy simulation mode (dry-run) перед action execute.
  - [ ] Проверка (pass/fail): simulation mode выдаёт preflight diff и policy verdict без side effects.
  - [ ] Артефакт результата: simulation test report + example output.
- [ ] 6. Сделать: внедрить экспериментальный NRAC (No-Regret Action Certificate) перед action execute.
  - [ ] Проверка (pass/fail): execute критичных action блокируется без NRAC или при regret выше policy threshold.
  - [ ] Артефакт результата: NRAC evaluation report + deny/allow fixtures.
- [ ] 7. Сделать: зафиксировать безразрывную эволюцию Action Studio в интерфейсной лестнице L1->L2.
  - [ ] Требование: `ActionRequest -> preflight -> policy verdict -> execute -> ActionResult -> audit verify` доступен из `Incident Room` и `Flow Mode` контекстов.
  - [ ] Требование: статусы шага (`pending|denied|approved|executed|rolled_back`) отображаются единообразно и локализуются EN/RU.
  - [ ] Проверка (pass/fail): e2e anti-breakage подтверждает, что после включения policy/NRAC сохраняется сквозной UX без “тупиковых” экранов.
  - [ ] Артефакт результата: action-flow anti-breakage report + screenshots.

## Документация (RU)
- [ ] docs/source/secure_actions_protocol_v2.md
- [ ] docs/runbooks/action_preflight_missing.md
- [ ] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [ ] Tier0 unit: policy/preflight validators.
- [ ] Tier1 integration: action->audit->proof chain.
- [ ] Tier2 e2e: Action Studio сценарии.
- [ ] Tier2 e2e: policy simulation сценарии без side effects.
- [ ] Tier2 e2e: NRAC allow/deny сценарии для критичных action.
- [ ] Tier2 e2e: anti-breakage маршруты Action Studio из `Incident Room` и `Flow Mode`.
- [ ] Tier2 i18n: EN/RU для статусов preflight/policy/NRAC/action-result.
- [ ] chaos: forced policy denial matrix.
- [ ] load: переносится в этап 34.
- [ ] soak: переносится в этап 34.

## CI gate
- [ ] `stage33-secure-actions-tests`
- [ ] `stage33-action-ux-anti-breakage`

## DoD
- [ ] Silent actions отсутствуют.
- [ ] Preflight/policy enforced во всех action ветках.
- [ ] Policy simulation mode доступен и проверяем для критичных action сценариев.
- [ ] NRAC enforced для action-классов, отмеченных как critical.
- [ ] Action Studio эволюционирует без интерфейсного разрыва между L1/L2 и подтверждён anti-breakage тестами.
- [ ] observability-gap событие этапа 33 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_34 запрещён до полного закрытия CHECKLIST_33.
- Артефакты закрытия: tests + policy matrix + registry/runbook diff.
