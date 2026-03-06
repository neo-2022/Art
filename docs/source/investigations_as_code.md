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
- До завершения перехода допускается legacy поле `version` (string), но canonical схема фиксируется в `docs/contracts/v2/schemas/investigation_doc_v1.json`.

## Migration notes (v1 compatibility)
1. Legacy payload с `version` импортируется без потери replay/fork/verify.
2. При сериализации сохраняется канонический детерминированный output; подпись документа пересчитывается от canonical JSON.
3. Любой переход к `doc_version > 1` обязан сопровождаться migration note + backward-compatibility тестом.

## Compatibility matrix
См. `docs/source/investigation_doc_compatibility_matrix.md`.

## Проверка
- unit: parser/serializer
- integration: fork/replay/compare
- e2e: end-to-end incident trace
