# Матрица переоткрытия стадий v0.2

## Source of truth
- `docs/testing/full_line_by_line_audit_program_v0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/defect_remediation_ladder_v0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Цель
Зафиксировать, какие стадии и почему должны быть переоткрыты после полного построчного аудита.

Эта матрица не определяет remediation-order сама по себе.
Её роль:
- объяснить reopening/open-состояние stage;
- передать основания в `docs/testing/defect_remediation_ladder_v0_2.md`;
- не дать `MASTER` потерять связь между аудитом и corrective execution.

Правило:
- стадия переоткрывается только при наличии подтверждённого корневого дефекта;
- если стадия уже открыта, здесь фиксируется не reopening, а подтверждение, что её нельзя закрывать до устранения конкретного дефекта;
- matrix не заменяет checklist-файлы, а объясняет, почему их статусы изменены.

## Матрица

| Stage | Статус после аудита | Корневой дефект | Ключевые доказательства | Действие |
|---|---|---|---|---|
| `01` | `REOPEN` | Governance corpus слабее hostile/maximal standard | один code owner, PR template без adversarial evidence, `SECURITY.md` и `docs/governance/release_process.md` слишком тонкие, `audit_policy`/`postmortem_template`/`tabletop_exercise` слабее нового стандарта | снять `[x]` с затронутых пунктов и stage row в MASTER |
| `02` | `REOPEN` | Privacy baseline расходится сам с собой | отсутствует `config/privacy/redaction_rules.yaml`; `docs/privacy/retention_matrix.md` конфликтует с `docs/compliance/profiles.md` по incidents retention | снять `[x]` с затронутых privacy пунктов и stage row в MASTER |
| `03` | `REOPEN` | Regional/compliance profile contour не удерживает cross-doc consistency | `docs/compliance/profiles.md` и `docs/privacy/retention_matrix.md` расходятся по retention; stage03 gate не ловит такой drift | снять `[x]` с затронутых profile пунктов и stage row в MASTER |
| `04` | `OPEN` | Stage уже открыт; дополнительно подтверждён CI/release/signing fragility | audit registry + buyer triage | оставить открытым |
| `05` | `OPEN` | Stage уже открыт; cross-repo/runtime truth Art↔REGART не доказана полностью | `scripts/ci/check_stage06_wrapper.sh`, `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`, buyer triage | оставить открытым |
| `06` | `OPEN` | Strict mode зависит от sibling checkout и local HTTP/dev path | `scripts/ci/check_stage06_wrapper.sh`, `http://127.0.0.1` corpus | оставить открытым |
| `07` | `OPEN` | Docs/meta/process layer ещё не выдерживает hostile standard | audit registry root/docs/template layers | оставить открытым |
| `08` | `OPEN` | Contracts/generation слой неоднороден | weak generated clients/docs generators, permissive schemas | оставить открытым |
| `11` | `OPEN` | Systemd vacuum path уже исправлен, а живой `art-core` теперь уже пишет и reload-ит через SQLite `v1/v2` события, `incidents`, `audit chain`, `fingerprint/source indexes`, `dna/evidence` и analytics/counters; корневой blocker сместился ещё глубже: hostile recovery contour (`WAL/corruption/read_only`) пока не доказан на полном расширенном состоянии | `core/src/main.rs`, `docs/core/storage.md`, `scripts/storage_stage11.py`, `docs/governance/evidence/stage11_core_sqlite_restart.log` | оставить открытым |
| `17` | `OPEN` | Agent spool runtime остаётся in-memory, restart destroys backlog | `agent/src/main.rs` | оставить открытым |
| `18` | `OPEN` | Agent transport/receiver contour не материализован | `agent/src/main.rs`, receiver gaps, no outbound/relay/TLS | оставить открытым |
| `19` | `OPEN` | Pack runtime позволяет placeholder payload | `scripts/tests/pack_install_runtime.sh`, `scripts/tests/packs_runtime.py` | оставить открытым |
| `20` | `OPEN` | REGART pack contour отстаёт от approved external-source coverage | `packs/regart/manifest.yaml`, `packs/regart/examples/receivers.toml` | оставить открытым |
| `24` | `OPEN` | Release/provenance corpus тоньше buyer-grade due diligence | `RELEASE_CHECKLIST.md`, `CHANGELOG.md`, `docs/governance/release_process.md`, `check_release_signing_pipeline.sh` | оставить открытым |
| `25` | `OPEN` | Compliance/audit-ready contour опирается на несуществующие evidence-path и декларативные runbooks | `docs/compliance/control_matrix.md`, `docs/compliance/evidence_list.md`, `docs/compliance/data_destruction.md` | оставить открытым |
| `26` | `OPEN` | RU profile и certified-ready contour зависят от неполного privacy/compliance/runtime основания | `docs/privacy/regional_profiles.md`, `docs/compliance/profiles.md`, `formats/ru_regulatory_scope.yaml` | оставить открытым |
| `28` | `OPEN` | Console foundation overclaim’ит bilingual/agent/source-of-truth completeness | missing `console_agent_interaction_model_v0_2.md`, screenshot with EN-only UI | оставить открытым |
| `29..34` | `OPEN` | Runtime differentiators и higher-stage claims опираются на ещё не устранённые корневые basement defects | audit registry layers 3–10 + weak contracts/runtime truth | оставить открытыми до устранения оснований |
| `35` | `OPEN` | Spatial/local-stores/worker-runtime contour остаётся слабым, partially stubbed и не доказывает durable local truth | `packages/local-stores/src/index.ts`, `packages/worker-runtime/src/index.ts`, stage35 runtime/gates corpus | оставить открытым |
| `36` | `OPEN` | SaaS readiness опирается на target-state evidence сильнее текущего tenant/privacy/runtime основания | `docs/source/saas_readiness_v0_2.md`, `scripts/tests/stage36_*`, audit registry layer 9 | оставить открытым |
| `37` | `OPEN` | Linux/platform/runtime truth всё ещё слабее readiness claims несмотря на частичный hardening | `tests/platform/vm/run_vm_smoke.sh`, `docs/ops/platform-vm-testing.md`, `scripts/ci/check_stage37_linux_hardening.sh` | оставить открытым |
| `38` | `OPEN` | Process ladder всё ещё зависит от weak/false-green gates и therefore не может считаться окончательно честным | `scripts/ci/check_stage_ladder_enforcement.sh`, `scripts/ci/check_storage_stage11_docs.sh`, stage37/platform gates | оставить открытым |
| `39..45` | `OPEN` | Continuation stages запрещены к честному закрытию, пока нижние runtime/contract/process основания ещё opened | defect ladder + audit registry layers 3–10 | оставить открытыми до устранения оснований |

## Примечание
Переоткрытие `01..03` меняет первый активный этап в `MASTER` обратно на `01`. Это намеренное действие: ранние основания должны быть восстановлены до дальнейшего линейного продвижения.
