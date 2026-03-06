# Audit + Merkle Verify v0.2

Последняя актуализация: 2026-03-06

## Цель
Обеспечить криптографически проверяемую цепочку действий и отображение результата verify в UI.

## Контракт
- Каждый audit entry содержит `prev_hash` и `entry_hash`.
- Verify endpoint возвращает `ok|failed` и причину.
- UI показывает цепочку доказательств по одному действию.

## Инварианты
- Цепочка append-only.
- Tampering детектируется детерминированно.
- Proof refs экспортируются в InvestigationDoc.

## Проверка
- unit hash/proof
- integration verify endpoint
- e2e UI verify
