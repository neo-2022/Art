# CHECKLIST 29 — Event DNA Core v2
Файл: CHECKLIST_29_EVENT_DNA_CORE_V2.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение canonicalization, dna_schema_version, v2 API/migration, DNA assurance program
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Реализовать DNA Core v2 как детерминированный и производительно-устойчивый фундамент Incident OS: контракты, runtime API, formal model, property-based проверка, reference parity, canary-safety.

## Границы
- Включено: `core/src/main.rs`, `docs/contracts/v2/*`, `docs/contracts/v2/dna_model/*`, stage29 CI gates.
- Исключено: удаление `/api/v1/*`.
- Исключено: UI Incident Room реализация (этап 30+).

## Зависимости
- CHECKLIST 08 (contracts)
- CHECKLIST 12 (ingest)
- CHECKLIST 14 (snapshot/stream)
- CHECKLIST 28 (workspace foundation закрыт)
- docs/source/dna_core_determinism_performance_assurance.md

## Шаги (строго линейно)
- [x] 1. Сделать: добавить `/api/v2/ingest`, `/api/v2/snapshot`, `/api/v2/stream`.
  - [x] Проверка (pass/fail): `cargo test -p art-core v2_ingest_snapshot_stream_integration` PASS.
  - [x] Артефакт результата: test log + пример `curl` ответа snapshot/stream.
- [x] 2. Сделать: реализовать deterministic canonicalization с ignore-list volatile полей.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_canonicalization_determinism_corpus_tests` PASS.
  - [x] Артефакт результата: corpus fixtures и test output.
- [x] 3. Сделать: зафиксировать `dna_schema_version` и compatibility поведение.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_schema_version_migration_compatibility_tests` PASS.
  - [x] Артефакт результата: обновлённая schema-документация + test log.
- [x] 4. Сделать: добавить `/api/v2/dna/clusters`, `/api/v2/dna/{dna_id}`, `/api/v2/dna/{dna_id}/similar`.
  - [x] Проверка (pass/fail): `cargo test -p art-core v2_dna_clusters_and_similar_lookup` PASS.
  - [x] Артефакт результата: API fixtures (lookup/similar).
- [x] 5. Сделать: обеспечить deterministic error codes для invalid payload.
  - [x] Проверка (pass/fail): `cargo test -p art-core v2_invalid_payload_returns_deterministic_error_codes` PASS.
  - [x] Артефакт результата: negative test output.
- [x] 6. Сделать: оформить migration plan + rollback plan для v2 data path.
  - [x] Проверка (pass/fail): документ `docs/contracts/v2/migrations_v2.md` содержит разделы `Forward`, `Rollback`, `Verification`.
  - [x] Артефакт результата: утверждённый migration document.
- [x] 7. Сделать: формализовать DNA model в TLA+.
  - [x] Проверка (pass/fail): `docs/contracts/v2/dna_model/dna_core_clusterization.tla`, `dna_core_clusterization.cfg`, `README.md` существуют и содержат инварианты + code mapping.
  - [x] Артефакт результата: model files + model README.
- [x] 8. Сделать: добавить property-based deterministic tests.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_property_determinism_proptest` PASS.
  - [x] Артефакт результата: test log.
- [x] 9. Сделать: ввести heavy deterministic gate на `1 000 000` прогонов.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_property_determinism_million_sequences_gate -- --ignored` PASS.
  - [x] Артефакт результата: heavy test log.
- [x] 10. Сделать: добавить reference parity tests для canonicalization/signature.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_reference_implementation_parity_corpus` PASS.
  - [x] Артефакт результата: parity test log.
- [x] 11. Сделать: ввести mutation-resilience sentinel тесты для критичных правил canonicalization.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_mutation_resilience_sentinel_test` PASS.
  - [x] Артефакт результата: mutation sentinel test log.
- [x] 12. Сделать: ввести monotonicity check append-only sequence.
  - [x] Проверка (pass/fail): `cargo test -p art-core dna_clusters_are_monotonic_for_append_only_sequence` PASS.
  - [x] Артефакт результата: monotonicity test log.
- [x] 13. Сделать: внедрить observability-gap контроль DNA determinism/canary/replay/rollback сбоев.
  - [x] События:
    - `observability_gap.dna_signature_mismatch`
    - `observability_gap.v2_migration_failed`
    - `observability_gap.dna_determinism_violation`
    - `observability_gap.dna_reference_mismatch`
    - `observability_gap.dna_canary_divergence`
    - `observability_gap.dna_replay_mismatch`
    - `observability_gap.api_dual_write_mismatch`
    - `observability_gap.dna_traceability_gap`
  - [x] evidence_min:
    - `dna_signature_mismatch`: `dna_id`, `canonical_hash`, `payload_hash`, `dna_schema_version`, `reason`, `trace_id`.
    - `v2_migration_failed`: `migration_id`, `db_path`, `error`, `stage`, `trace_id`.
    - `dna_determinism_violation`: `build_id`, `dna_id`, `canonical_hash`, `payload_hash`, `replay_window`, `trace_id`.
    - `dna_reference_mismatch`: `dna_id`, `canonical_hash`, `reference_hash`, `dna_schema_version`, `trace_id`.
    - `dna_canary_divergence`: `canary_build_id`, `stable_build_id`, `dna_id`, `divergence_rate`, `trace_id`.
    - `dna_replay_mismatch`: `window_start`, `window_end`, `expected_hash`, `actual_hash`, `trace_id`.
    - `api_dual_write_mismatch`: `endpoint`, `trace_id`, `v1_hash`, `v2_hash`, `mismatch_reason`.
    - `dna_traceability_gap`: `dna_id`, `incident_id`, `replay_window`, `law_version`, `trace_id`.
  - [x] action_ref:
    - `docs/runbooks/dna_signature_mismatch.md`
    - `docs/runbooks/v2_migration_failed.md`
    - `docs/runbooks/dna_determinism_violation.md`
    - `docs/runbooks/dna_reference_mismatch.md`
    - `docs/runbooks/dna_canary_divergence.md`
    - `docs/runbooks/dna_replay_mismatch.md`
    - `docs/runbooks/api_dual_write_mismatch.md`
    - `docs/runbooks/dna_traceability_gap.md`
  - [x] Проверка (pass/fail): registry содержит все записи и runbook файлы существуют.
  - [x] Артефакт результата: diff registry + runbooks.
- [x] 14. Сделать: зафиксировать разделение API путей `v1` и `v2` и dual-write verifier policy.
  - [x] Проверка (pass/fail): `docs/contracts/v2/migrations_v2.md` содержит разделы `Dual-write verification` и `v1 sunset criteria`, release-blocker `normalized mismatch rate > 0` после `delivery_lag_grace_window` (default `10s` для Linux prod).
  - [x] Артефакт результата: migration doc diff.
- [x] 15. Сделать: зафиксировать fingerprint v2 контрактов и CI-контроль незадокументированных изменений.
  - [x] Проверка (pass/fail): `bash scripts/ci/check_v2_contract_fingerprint.sh` PASS.
  - [x] Артефакт результата: `docs/contracts/v2/contract_fingerprint.sha256` + gate log.
- [x] 16. Сделать: оформить dual-write lag profile как конфиг и провести граничные проверки.
  - [x] Проверка (pass/fail): migration docs содержат `delivery_lag_grace_window` и test matrix для `5s/10s/15s`.
  - [x] Артефакт результата: migration doc diff + test log matrix.
- [x] 17. Сделать: добавить периодический replay-determinism suite для контроля drift.
  - [x] Проверка (pass/fail): `bash scripts/ci/run_stage29_replay_determinism.sh` PASS.
  - [x] Артефакт результата: replay determinism report + CI log.

## Документация (RU)
- [x] docs/source/dna_core_determinism_performance_assurance.md
- [x] docs/contracts/v2/openapi.yaml
- [x] docs/contracts/v2/schemas/dna_signature.json
- [x] docs/contracts/v2/schemas/raw_event_v2.json
- [x] docs/contracts/v2/schemas/snapshot_v2.json
- [x] docs/contracts/v2/migrations_v2.md
- [x] docs/contracts/v2/contract_fingerprint.sha256
- [x] docs/contracts/v2/dna_model/README.md
- [x] docs/contracts/v2/dna_model/dna_core_clusterization.tla
- [x] docs/contracts/v2/dna_model/dna_core_clusterization.cfg
- [x] docs/runbooks/dna_signature_mismatch.md
- [x] docs/runbooks/v2_migration_failed.md
- [x] docs/runbooks/dna_determinism_violation.md
- [x] docs/runbooks/dna_reference_mismatch.md
- [x] docs/runbooks/dna_canary_divergence.md
- [x] docs/runbooks/dna_replay_mismatch.md
- [x] docs/runbooks/api_dual_write_mismatch.md
- [x] docs/runbooks/dna_traceability_gap.md
- [x] docs/source/risk_register_v0_2.md

## Тестирование
- [x] Tier0 unit: canonicalization determinism corpus.
- [x] Tier0 property-based: `dna_property_determinism_proptest`.
- [x] Tier0 heavy gate: `dna_property_determinism_million_sequences_gate`.
- [x] Tier0 parity: reference implementation parity corpus.
- [x] Tier0 mutation-resilience: `dna_mutation_resilience_sentinel_test`.
- [x] Tier0 monotonicity: append-only cluster monotonicity.
- [x] Tier1 integration: ingest->snapshot->stream v2.
- [x] Tier1 integration: dna clusters/similar lookup.
- [x] Tier1 negative: deterministic error codes.
- [x] Tier1 compatibility: v1/v2 dual-write verifier.
- [x] Tier1 compatibility: lag profile matrix `5s/10s/15s`.
- [x] Tier1 governance: contract fingerprint gate.
- [x] chaos: migration rollback dry-run документирован и воспроизводим.
- [x] load: переносится в этап 34.
- [x] soak: переносится в этап 34.
- [x] replay: периодический deterministic replay window check.

## CI gate
- [x] `stage29-dna-assurance-gate`
- [x] `stage29-dna-tests`
- [x] `stage29-dna-property-million`
- [x] `stage29-contract-fingerprint`
- [x] `stage29-nightly-replay-determinism`
- [x] `stage28-docs-gate` (контракты/документы v2)

## DoD
- [x] v2 endpoints работают параллельно с v1 без breaking изменений.
- [x] DNA signatures детерминированы, версионируемы и валидируются property-based suite.
- [x] Formal model, migration/rollback и reference parity формально определены и проверяемы.
- [x] observability-gap события этапа 29 зарегистрированы и имеют runbook.
- [x] Риски R2 и R5 из risk register закрыты тестами и policy-артефактами.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_30 запрещён до полного закрытия CHECKLIST_29.
- Артефакты закрытия: cargo test logs + model files + registry/runbook diffs + migration doc.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
