# Art <-> REGART Contract Parity Report

Последняя актуализация: 2026-03-06
Статус: TEMPLATE

## Цель
Подтверждать совместимость обязательных контрактов между Art (`docs/contracts/v2/*`) и REGART (`docs/integration/REGART_ART_CONTRACT.md`).

## Обязательные проверки
1. Совпадают базовые поля RawEvent и semantic mapping.
2. Совпадают правила unknown fields / schema_version compatibility.
3. Совпадают retry/timeout и partial-ack семантики.
4. Совпадает набор критичных `observability_gap.*` для интеграционного контура.

## Формат отчёта
- verification_date
- art_commit
- regart_commit
- parity_result (`pass|fail`)
- mismatches[]
- remediation_plan

## Последний прогон
- verification_date: --
- art_commit: --
- regart_commit: --
- parity_result: --
- mismatches: --
- remediation_plan: --
