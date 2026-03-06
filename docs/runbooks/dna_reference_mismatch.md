# Runbook: observability_gap.dna_reference_mismatch

## Symptoms
- Rust реализация и reference canonicalization дают разные `canonical_hash`.

## Diagnosis
1. Прогнать `cargo test -p art-core dna_reference_implementation_parity_corpus`.
2. Выгрузить payload, на котором mismatch воспроизводится.
3. Проверить правила ignore-list volatile keys.

## Resolution
1. Исправить canonicalization в Rust или reference spec.
2. Обновить `docs/contracts/v2/dna_model/README.md` (Code Mapping).
3. Добавить/расширить corpus fixture.
4. Повторить stage29 deterministic gates.
