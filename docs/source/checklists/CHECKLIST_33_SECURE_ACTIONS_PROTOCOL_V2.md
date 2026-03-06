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
- [x] 1. Сделать: preflight log обязателен для каждого action execute.
  - [x] Проверка (pass/fail): action без preflight получает deterministic deny.
  - [x] Артефакт результата: integration test output.
- [x] 2. Сделать: policy-as-ui в Action Studio (доступные поля/действия только по policy).
  - [x] Проверка (pass/fail): UI policy tests PASS.
  - [x] Артефакт результата: UI test logs.
- [x] 3. Сделать: action result -> audit record -> merkle proof attach.
  - [x] Проверка (pass/fail): chain integration tests PASS.
  - [x] Артефакт результата: action chain fixtures.
- [x] 4. Сделать: observability-gap контроль preflight/policy нарушений.
  - [x] Событие: `observability_gap.action_preflight_missing`.
  - [x] evidence_min: `action`, `target`, `actor_role`, `policy_id`, `trace_id`.
  - [x] action_ref: `docs/runbooks/action_preflight_missing.md`.
  - [x] Проверка (pass/fail): registry запись + runbook файл.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 5. Сделать: добавить policy simulation mode (dry-run) перед action execute.
  - [x] Проверка (pass/fail): simulation mode выдаёт preflight diff и policy verdict без side effects.
  - [x] Артефакт результата: simulation test report + example output.
- [x] 6. Сделать: внедрить экспериментальный NRAC (No-Regret Action Certificate) перед action execute.
  - [x] Проверка (pass/fail): execute критичных action блокируется без NRAC или при regret выше policy threshold.
  - [x] Артефакт результата: NRAC evaluation report + deny/allow fixtures.
- [x] 7. Сделать: зафиксировать безразрывную эволюцию Action Studio в интерфейсной лестнице L1->L2.
  - [x] Требование: `ActionRequest -> preflight -> policy verdict -> execute -> ActionResult -> audit verify` доступен из `Incident Room` и `Flow Mode` контекстов.
  - [x] Требование: статусы шага (`pending|denied|approved|executed|rolled_back`) отображаются единообразно и локализуются EN/RU.
  - [x] Проверка (pass/fail): e2e anti-breakage подтверждает, что после включения policy/NRAC сохраняется сквозной UX без “тупиковых” экранов.
  - [x] Артефакт результата: action-flow anti-breakage report + screenshots.

## Документация (RU)
- [x] docs/source/secure_actions_protocol_v2.md
- [x] docs/runbooks/action_preflight_missing.md
- [x] docs/foundation/revolutionary_hypotheses.md

## Тестирование
- [x] Tier0 unit: policy/preflight validators.
- [x] Tier1 integration: action->audit->proof chain.
- [x] Tier2 e2e: Action Studio сценарии.
- [x] Tier2 e2e: policy simulation сценарии без side effects.
- [x] Tier2 e2e: NRAC allow/deny сценарии для критичных action.
- [x] Tier2 e2e: anti-breakage маршруты Action Studio из `Incident Room` и `Flow Mode`.
- [x] Tier2 i18n: EN/RU для статусов preflight/policy/NRAC/action-result.
- [x] chaos: forced policy denial matrix.
- [x] load: переносится в этап 34.
- [x] soak: переносится в этап 34.

## CI gate
- [x] `stage33-secure-actions-tests`
- [x] `stage33-action-ux-anti-breakage`

## DoD
- [x] Silent actions отсутствуют.
- [x] Preflight/policy enforced во всех action ветках.
- [x] Policy simulation mode доступен и проверяем для критичных action сценариев.
- [x] NRAC enforced для action-классов, отмеченных как critical.
- [x] Action Studio эволюционирует без интерфейсного разрыва между L1/L2 и подтверждён anti-breakage тестами.
- [x] observability-gap событие этапа 33 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_34 запрещён до полного закрытия CHECKLIST_33.
- Артефакты закрытия: tests + policy matrix + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
