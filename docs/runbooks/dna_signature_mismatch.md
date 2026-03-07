# Runbook: observability_gap.dna_signature_mismatch

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Одинаковые события получают разные `dna_id`.
- Regression в canonicalization tests.

## checks
1. Запустить `cargo test -p art-core dna_canonicalization_determinism_corpus_tests`.
2. Сравнить `canonical_hash/payload_hash/dna_schema_version` из evidence.
3. Проверить ignore-list volatile полей.

## mitigations
1. Исправить canonicalization rules.
2. При breaking change поднять `dna_schema_version`.
3. Обновить fixtures и повторить stage29 tests.

## rollback
- Вернуть предыдущий алгоритм canonicalization и отключить новый ingest v2 path.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.dna_signature_mismatch`.
- Snapshot/stream/метрики подтверждают восстановление без новых regressions.
- Смежные hostile paths не деградировали после remediation.

## escalation
- Эскалировать on-call и Incident Commander, если mitigation не восстановила сервис в рамках SLA severity.
- При SEV1+ или повторном срабатывании приложить evidence refs и связанный incident/postmortem trail.

## evidence
- Сохранить event payload, `trace_id`/`request_id`/`audit_id`, affected component, version/build, config diff и relevant log excerpts.
- Для UI/runtime проблем приложить screenshot/video reproduction и browser/runtime context.
- Для release/config проблем приложить commit/tag/PR и rollback decision.

## owner
- Основной владелец: дежурный инженер и компонент-владелец по RACI/реестру событий.
- Ответственный за эскалацию: Incident Commander для SEV1+ или затяжного инцидента.

## degraded mode
- Если полное восстановление недоступно, включить документированный degraded/read-only mode для затронутой поверхности.
- Зафиксировать scope деградации, срок действия и условие выхода из degraded mode.
