# Action Execution Safety Guard v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/source/checklists/CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
- `docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
- `docs/source/checklists/CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md`

## Что это такое
Это предохранитель, который не даёт системе выполнить опасное действие только потому, что запрос выглядит технически правильным.

Проще говоря: действие может быть валидным по схеме и всё равно быть слишком рискованным для выполнения.

## Зачем он нужен
Он защищает проект от трёх классов ошибок:
- оператор или агент просит разрушительное действие без достаточных оснований;
- система видит только форму запроса, но не понимает его реальный риск;
- автоматизация слишком быстро доходит до `execute`, минуя смысловую проверку.

## Что он обязан делать
1. Отделять `можно технически выполнить` от `можно безопасно выполнять сейчас`.
2. Требовать `preflight` и объяснимую причину выполнения.
3. Для destructive и high-impact действий требовать:
- bounded-regret / no-regret сертификат;
- либо явное policy exception с audit trail.
4. При отсутствии достаточного основания блокировать действие fail-closed.

## Где применяется
- API действий `Art Core`.
- UI и Console слой, где человек видит и подтверждает действие.
- Agent/AI контур, где действие может быть предложено автоматически.
- Release и production hardening, где нельзя silently ослаблять safety barrier.

## Что считается dangerous action
Это любое действие, которое может:
- удалить данные;
- остановить сервис;
- изменить состояние расследования или evidence;
- поменять runtime policy;
- повлиять на доступность, целостность или compliance-состояние.

## Обязательный минимум реализации
- `preflight-first` как единственный допустимый путь.
- Явное различение:
  - safe action;
  - high-impact action;
  - destructive action.
- Запрет прямого `execute` без semantic safety proof.
- Отдельный gap-сигнал при блокировке.

## Observability и реакция
При срабатывании guard должен появляться:
- `observability_gap.action_safety_guard_blocked`

Оператор должен видеть:
- какое действие заблокировано;
- почему оно заблокировано;
- чего не хватает для безопасного выполнения;
- есть ли допустимый путь через policy exception.

## Что считается зрелостью
`materialized`:
- есть runtime preflight;
- есть semantic blocker;
- есть audit trail;
- есть negative-path tests.

`planned`:
- контур описан, но destructive path ещё можно обойти через слабый runtime.

## Связанные runbooks
- `docs/runbooks/action_safety_guard_blocked.md`
