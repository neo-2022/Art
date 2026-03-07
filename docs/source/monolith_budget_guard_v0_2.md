# Monolith Budget Guard v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`

## Что это такое
Это предохранитель против опасной монолитности ключевых файлов и runtime entrypoint-модулей.

## Почему это важно
Слишком большой файл — это не просто вопрос стиля.

Это риск:
- bus factor;
- дорогих изменений;
- сложного review;
- плохой локализации дефектов;
- невозможности быстро ввести нового инженера.

## Что guard обязан отслеживать
- line count критичных файлов;
- concentration of responsibilities;
- отсутствие module split plan при превышении бюджета.

## Что считается нарушением
Нарушение есть, если:
- файл перерос свой бюджет;
- в нём смешаны несколько несущих ответственностей;
- нет decomposition plan и stage-binding на исправление.

## Observability и реакция
Gap:
- `observability_gap.monolith_budget_exceeded`

## Связанные runbooks
- `docs/runbooks/monolith_budget_exceeded.md`
