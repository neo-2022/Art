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
- [ ] 1. Сделать: добавить `/api/v2/ingest`, `/api/v2/snapshot`, `/api/v2/stream`.
  - [ ] Проверка (pass/fail): `cargo test -p art-core v2_ingest_snapshot_stream_integration` PASS.
  - [ ] Артефакт результата: test log + пример `curl` ответа snapshot/stream.
- [ ] 2. Сделать: реализовать deterministic canonicalization с ignore-list volatile полей.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_canonicalization_determinism_corpus_tests` PASS.
  - [ ] Артефакт результата: corpus fixtures и test output.
- [ ] 3. Сделать: зафиксировать `dna_schema_version` и compatibility поведение.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_schema_version_migration_compatibility_tests` PASS.
  - [ ] Артефакт результата: обновлённая schema-документация + test log.
- [ ] 4. Сделать: добавить `/api/v2/dna/clusters`, `/api/v2/dna/{dna_id}`, `/api/v2/dna/{dna_id}/similar`.
  - [ ] Проверка (pass/fail): `cargo test -p art-core v2_dna_clusters_and_similar_lookup` PASS.
  - [ ] Артефакт результата: API fixtures (lookup/similar).
- [ ] 5. Сделать: обеспечить deterministic error codes для invalid payload.
  - [ ] Проверка (pass/fail): `cargo test -p art-core v2_invalid_payload_returns_deterministic_error_codes` PASS.
  - [ ] Артефакт результата: negative test output.
- [ ] 6. Сделать: оформить migration plan + rollback plan для v2 data path.
  - [ ] Проверка (pass/fail): документ `docs/contracts/v2/migrations_v2.md` содержит разделы `Forward`, `Rollback`, `Verification`.
  - [ ] Артефакт результата: утверждённый migration document.
- [ ] 7. Сделать: формализовать DNA model в TLA+.
  - [ ] Проверка (pass/fail): `docs/contracts/v2/dna_model/dna_core_clusterization.tla`, `dna_core_clusterization.cfg`, `README.md` существуют и содержат инварианты + code mapping.
  - [ ] Артефакт результата: model files + model README.
- [ ] 8. Сделать: добавить property-based deterministic tests.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_property_determinism_proptest` PASS.
  - [ ] Артефакт результата: test log.
- [ ] 9. Сделать: ввести heavy deterministic gate на `1 000 000` прогонов.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_property_determinism_million_sequences_gate -- --ignored` PASS.
  - [ ] Артефакт результата: heavy test log.
- [ ] 10. Сделать: добавить reference parity tests для canonicalization/signature.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_reference_implementation_parity_corpus` PASS.
  - [ ] Артефакт результата: parity test log.
- [ ] 11. Сделать: ввести mutation-resilience sentinel тесты для критичных правил canonicalization.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_mutation_resilience_sentinel_test` PASS.
  - [ ] Артефакт результата: mutation sentinel test log.
- [ ] 12. Сделать: ввести monotonicity check append-only sequence.
  - [ ] Проверка (pass/fail): `cargo test -p art-core dna_clusters_are_monotonic_for_append_only_sequence` PASS.
  - [ ] Артефакт результата: monotonicity test log.
- [ ] 13. Сделать: внедрить observability-gap контроль DNA determinism/canary/replay/rollback сбоев.
  - [ ] События:
    - `observability_gap.dna_signature_mismatch`
    - `observability_gap.v2_migration_failed`
    - `observability_gap.dna_determinism_violation`
    - `observability_gap.dna_reference_mismatch`
    - `observability_gap.dna_canary_divergence`
    - `observability_gap.dna_replay_mismatch`
    - `observability_gap.api_dual_write_mismatch`
    - `observability_gap.dna_traceability_gap`
  - [ ] evidence_min:
    - `dna_signature_mismatch`: `dna_id`, `canonical_hash`, `payload_hash`, `dna_schema_version`, `reason`, `trace_id`.
    - `v2_migration_failed`: `migration_id`, `db_path`, `error`, `stage`, `trace_id`.
    - `dna_determinism_violation`: `build_id`, `dna_id`, `canonical_hash`, `payload_hash`, `replay_window`, `trace_id`.
    - `dna_reference_mismatch`: `dna_id`, `canonical_hash`, `reference_hash`, `dna_schema_version`, `trace_id`.
    - `dna_canary_divergence`: `canary_build_id`, `stable_build_id`, `dna_id`, `divergence_rate`, `trace_id`.
    - `dna_replay_mismatch`: `window_start`, `window_end`, `expected_hash`, `actual_hash`, `trace_id`.
    - `api_dual_write_mismatch`: `endpoint`, `trace_id`, `v1_hash`, `v2_hash`, `mismatch_reason`.
    - `dna_traceability_gap`: `dna_id`, `incident_id`, `replay_window`, `law_version`, `trace_id`.
  - [ ] action_ref:
    - `docs/runbooks/dna_signature_mismatch.md`
    - `docs/runbooks/v2_migration_failed.md`
    - `docs/runbooks/dna_determinism_violation.md`
    - `docs/runbooks/dna_reference_mismatch.md`
    - `docs/runbooks/dna_canary_divergence.md`
    - `docs/runbooks/dna_replay_mismatch.md`
    - `docs/runbooks/api_dual_write_mismatch.md`
    - `docs/runbooks/dna_traceability_gap.md`
  - [ ] Проверка (pass/fail): registry содержит все записи и runbook файлы существуют.
  - [ ] Артефакт результата: diff registry + runbooks.
- [ ] 14. Сделать: зафиксировать разделение API путей `v1` и `v2` и dual-write verifier policy.
  - [ ] Проверка (pass/fail): `docs/contracts/v2/migrations_v2.md` содержит разделы `Dual-write verification` и `v1 sunset criteria`, release-blocker `normalized mismatch rate > 0` после `delivery_lag_grace_window` (default `10s` для Linux prod).
  - [ ] Артефакт результата: migration doc diff.
- [ ] 15. Сделать: зафиксировать fingerprint v2 контрактов и CI-контроль незадокументированных изменений.
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_v2_contract_fingerprint.sh` PASS.
  - [ ] Артефакт результата: `docs/contracts/v2/contract_fingerprint.sha256` + gate log.
- [ ] 16. Сделать: оформить dual-write lag profile как конфиг и провести граничные проверки.
  - [ ] Проверка (pass/fail): migration docs содержат `delivery_lag_grace_window` и test matrix для `5s/10s/15s`.
  - [ ] Артефакт результата: migration doc diff + test log matrix.
- [ ] 17. Сделать: добавить периодический replay-determinism suite для контроля drift.
  - [ ] Проверка (pass/fail): `bash scripts/ci/run_stage29_replay_determinism.sh` PASS.
  - [ ] Артефакт результата: replay determinism report + CI log.

## Документация (RU)
- [ ] docs/source/dna_core_determinism_performance_assurance.md
- [ ] docs/contracts/v2/openapi.yaml
- [ ] docs/contracts/v2/schemas/dna_signature.json
- [ ] docs/contracts/v2/schemas/raw_event_v2.json
- [ ] docs/contracts/v2/schemas/snapshot_v2.json
- [ ] docs/contracts/v2/migrations_v2.md
- [ ] docs/contracts/v2/contract_fingerprint.sha256
- [ ] docs/contracts/v2/dna_model/README.md
- [ ] docs/contracts/v2/dna_model/dna_core_clusterization.tla
- [ ] docs/contracts/v2/dna_model/dna_core_clusterization.cfg
- [ ] docs/runbooks/dna_signature_mismatch.md
- [ ] docs/runbooks/v2_migration_failed.md
- [ ] docs/runbooks/dna_determinism_violation.md
- [ ] docs/runbooks/dna_reference_mismatch.md
- [ ] docs/runbooks/dna_canary_divergence.md
- [ ] docs/runbooks/dna_replay_mismatch.md
- [ ] docs/runbooks/api_dual_write_mismatch.md
- [ ] docs/runbooks/dna_traceability_gap.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] Tier0 unit: canonicalization determinism corpus.
- [ ] Tier0 property-based: `dna_property_determinism_proptest`.
- [ ] Tier0 heavy gate: `dna_property_determinism_million_sequences_gate`.
- [ ] Tier0 parity: reference implementation parity corpus.
- [ ] Tier0 mutation-resilience: `dna_mutation_resilience_sentinel_test`.
- [ ] Tier0 monotonicity: append-only cluster monotonicity.
- [ ] Tier1 integration: ingest->snapshot->stream v2.
- [ ] Tier1 integration: dna clusters/similar lookup.
- [ ] Tier1 negative: deterministic error codes.
- [ ] Tier1 compatibility: v1/v2 dual-write verifier.
- [ ] Tier1 compatibility: lag profile matrix `5s/10s/15s`.
- [ ] Tier1 governance: contract fingerprint gate.
- [ ] chaos: migration rollback dry-run документирован и воспроизводим.
- [ ] load: переносится в этап 34.
- [ ] soak: переносится в этап 34.
- [ ] replay: периодический deterministic replay window check.

## CI gate
- [ ] `stage29-dna-assurance-gate`
- [ ] `stage29-dna-tests`
- [ ] `stage29-dna-property-million`
- [ ] `stage29-contract-fingerprint`
- [ ] `stage29-nightly-replay-determinism`
- [ ] `stage28-docs-gate` (контракты/документы v2)

## DoD
- [ ] v2 endpoints работают параллельно с v1 без breaking изменений.
- [ ] DNA signatures детерминированы, версионируемы и валидируются property-based suite.
- [ ] Formal model, migration/rollback и reference parity формально определены и проверяемы.
- [ ] observability-gap события этапа 29 зарегистрированы и имеют runbook.
- [ ] Риски R2 и R5 из risk register закрыты тестами и policy-артефактами.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_30 запрещён до полного закрытия CHECKLIST_29.
- Артефакты закрытия: cargo test logs + model files + registry/runbook diffs + migration doc.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
