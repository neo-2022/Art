# Investigations-as-Code v0.2

Последняя актуализация: 2026-03-06

## Цель
Формализовать расследование как версионируемый артефакт `InvestigationDoc`, пригодный для fork/replay/compare и комплаенс-аудита.

## Обязательные поля документа
- `doc_id`, `doc_version`, `created_at`, `updated_at`
- `claims[]`
- `decisions[]`
- `actions[]`
- `results[]`
- `evidence_refs[]`
- `audit_refs[]`
- `proof_refs[]`

## Инварианты
- Каждый claim связан с `evidence_refs[]`.
- Каждый action связан с `audit_refs[]`.
- Replay не меняет исходный документ.
- Compare возвращает детерминированный diff.

## Совместимость версий
- Minor upgrade не ломает replay старых документов.
- Любой breaking change требует bump `doc_version`.

## Проверка
- unit: parser/serializer
- integration: fork/replay/compare
- e2e: end-to-end incident trace
