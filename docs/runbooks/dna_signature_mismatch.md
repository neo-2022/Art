# Runbook: observability_gap.dna_signature_mismatch

## Symptoms
- Одинаковые события получают разные `dna_id`.
- Regression в canonicalization tests.

## Diagnosis
1. Запустить `cargo test -p art-core dna_canonicalization_determinism_corpus_tests`.
2. Сравнить `canonical_hash/payload_hash/dna_schema_version` из evidence.
3. Проверить ignore-list volatile полей.

## Resolution
1. Исправить canonicalization rules.
2. При breaking change поднять `dna_schema_version`.
3. Обновить fixtures и повторить stage29 tests.

## Rollback
- Вернуть предыдущий алгоритм canonicalization и отключить новый ingest v2 path.
