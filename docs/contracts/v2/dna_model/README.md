# DNA Formal Model (TLA+)

Последняя актуализация: 2026-03-06

## Назначение
Формально зафиксировать правила кластеризации DNA до и независимо от реализации на Rust.

## Файлы
- `dna_core_clusterization.tla` — модель состояния, операций и инвариантов.
- `dna_core_clusterization.cfg` — конфигурация model checking.

## Проверяемые свойства
1. Determinism: одинаковая последовательность входов даёт одинаковое состояние кластеров.
2. No false merge: события с разной канонической подписью не сливаются в один `dna_id`.
3. Append monotonicity: добавление нового события не удаляет существующие кластеры.
4. Replay stability: replay того же окна возвращает тот же набор `dna_id`.

## Code Mapping
- Canonicalization: `core/src/main.rs::canonical_json_v2`
- Signature: `core/src/main.rs::build_dna_signature`
- Cluster update: `core/src/main.rs::upsert_dna_cluster_locked`
- Snapshot materialization: `core/src/main.rs::sorted_dna_clusters_locked`

## Правило сопровождения
Любое изменение canonicalization/signature в Rust требует:
1. обновления модели,
2. повторной проверки инвариантов,
3. обновления checklist-артефактов stage29.
