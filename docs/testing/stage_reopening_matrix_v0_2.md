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
| `10` | `OPEN` | Browser surface и hostile browser baseline ещё не материализованы как security contour | browser audit layer + `DEF-020` | оставить открытым |
| `11` | `CLOSED` | Живой `art-core` пишет и reload-ит через SQLite `v1/v2` события, `incidents`, `audit chain`, `fingerprint/source indexes`, `dna/evidence` и analytics/counters; hostile backup/restore proof, live corruption/read_only contour, backup cadence `15 минут`, live `kill -9`, storage pressure / фактический `disk full`, concurrency `8 writer / 4 reader / 10000 ops` и production-proof для `VACUUM/systemd` теперь materialized и подтверждены отдельными runtime-evidence. Downstream работа по durable basement остаётся уже не в `stage11`, а в `stage23` и `stage37`. | `core/src/main.rs`, `docs/core/storage.md`, `scripts/storage_stage11.py`, `scripts/tests/storage_concurrency_runtime.py`, `scripts/tests/storage_kill9_runtime.sh`, `scripts/tests/storage_pressure_runtime.sh`, `scripts/tests/storage_vacuum_runtime.sh`, `docs/source/storage_pressure_protection_v0_2.md`, `docs/governance/evidence/stage11_core_sqlite_restart.log`, `docs/governance/evidence/stage11_core_sqlite_hostile_recovery.log`, `docs/governance/evidence/stage11_core_backup_scope_isolation.log`, `docs/governance/evidence/stage11_step2_backup_policy.log`, `docs/governance/evidence/stage11_step3_concurrency.log`, `docs/governance/evidence/stage11_kill9_runtime.log`, `docs/governance/evidence/stage11_storage_pressure_runtime.log`, `docs/governance/evidence/stage11_step4_vacuum_runtime.log` | можно закрыть |
| `15` | `OPEN` | Trust boundary и canonical actor context всё ещё слабее hostile standard | `core/src/main.rs`, `docs/source/trust_boundary_hardening_v0_2.md`, `DEF-019` | оставить открытым |
| `16` | `OPEN` | Panel0 не имеет отдельного materialized browser hardening baseline | `docs/source/browser_surface_hardening_v0_2.md`, browser audit layer, `DEF-020` | оставить открытым |
| `17` | `OPEN` | Agent spool runtime остаётся in-memory, restart destroys backlog; дополнительно отсутствует полный hostile baseline queue integrity / duplicate / anti-loop (`DEF-025`) | `agent/src/main.rs`, `docs/source/queue_integrity_protection_v0_2.md` | оставить открытым |
| `18` | `OPEN` | Agent transport/receiver contour не материализован; кроме этого отсутствует наглядная connected-system проекция declared-vs-observed coverage, startup fail-closed baseline и queue integrity hostile protection (`DEF-024`, `DEF-025`) | `agent/src/main.rs`, receiver gaps, no outbound/relay/TLS, `docs/agent/receiver_source_coverage.md`, `docs/source/connected_system_visibility_v0_2.md`, `docs/source/startup_config_safety_validator_v0_2.md`, `docs/source/queue_integrity_protection_v0_2.md` | оставить открытым |
| `19` | `OPEN` | Pack runtime позволяет placeholder payload и не обязан показывать внешнюю систему как проверяемую сущность со статусом и типами данных | `scripts/tests/pack_install_runtime.sh`, `scripts/tests/packs_runtime.py`, `docs/packs/source_coverage.md`, `packs/regart/manifest.yaml` | оставить открытым |
| `20` | `OPEN` | REGART pack contour отстаёт от approved external-source coverage и не materialize Connected System View для REGART как живой внешней системы | `packs/regart/manifest.yaml`, `packs/regart/examples/receivers.toml`, `docs/source/connected_system_visibility_v0_2.md` | оставить открытым |
| `23` | `OPEN` | Downstream DR/backup contour для `DEF-001` уже стал реальным runtime-proof, но stage ещё не может закрыться: `WAL-aware backup`, `DR drill`, runtime smoke и PR CI path materialized, а `SIGHUP` hot-reload без простоя и `observability_gap.tls_config_invalid` как startup backlog всё ещё не доведены до честного hostile proof | `scripts/tests/ops_stage23_smoke.sh`, `docs/ops/backup_restore.md`, `docs/ops/dr_drill.md`, `docs/ops/tls_rotation.md`, `scripts/ci/check_ops_stage23_docs.sh`, `docs/governance/evidence/stage23_ops_runtime_smoke.log` | оставить открытым |
| `24` | `OPEN` | Release/provenance corpus тоньше buyer-grade due diligence и ещё не держит trust boundary/browser surface blockers; дополнительно release contour не удерживает storage pressure, unsafe startup config, queue integrity и guard self-test как обязательные blockers (`DEF-023..026`) | `RELEASE_CHECKLIST.md`, `CHANGELOG.md`, `docs/governance/release_process.md`, `check_release_signing_pipeline.sh`, `DEF-019`, `DEF-020`, `docs/source/protective_safeguards_catalog_v0_2.md` | оставить открытым |
| `25` | `OPEN` | Compliance/audit-ready contour опирается на несуществующие evidence-path и декларативные runbooks | `docs/compliance/control_matrix.md`, `docs/compliance/evidence_list.md`, `docs/compliance/data_destruction.md` | оставить открытым |
| `26` | `OPEN` | RU profile и certified-ready contour зависят от неполного privacy/compliance/runtime основания | `docs/privacy/regional_profiles.md`, `docs/compliance/profiles.md`, `formats/ru_regulatory_scope.yaml` | оставить открытым |
| `28` | `OPEN` | Console foundation overclaim’ит bilingual/agent/source-of-truth completeness, не держит browser surface baseline как обязательный закон и не обязан явно показывать состояние подключённых внешних систем | missing `console_agent_interaction_model_v0_2.md`, screenshot with EN-only UI, `DEF-020`, `docs/source/connected_system_visibility_v0_2.md` | оставить открытым |
| `33` | `OPEN` | Secure actions ещё не привязаны к trust-boundary hostile negative path | `DEF-019`, action/audit spoofing surface | оставить открытым |
| `29..34` | `OPEN` | Runtime differentiators и higher-stage claims опираются на ещё не устранённые корневые basement defects | audit registry layers 3–10 + weak contracts/runtime truth | оставить открытыми до устранения оснований |
| `35` | `OPEN` | Spatial/local-stores/worker-runtime contour остаётся слабым, partially stubbed и не доказывает durable local truth | `packages/local-stores/src/index.ts`, `packages/worker-runtime/src/index.ts`, stage35 runtime/gates corpus | оставить открытым |
| `36` | `OPEN` | SaaS readiness опирается на target-state evidence сильнее текущего tenant/privacy/runtime основания | `docs/source/saas_readiness_v0_2.md`, `scripts/tests/stage36_*`, audit registry layer 9 | оставить открытым |
| `37` | `OPEN` | Linux/platform/runtime truth всё ещё слабее readiness claims и не держит trust boundary/browser surface baseline как production blockers; дополнительно не materialize полный storage pressure, startup fail-closed, queue integrity и guard self-observability baseline (`DEF-023..026`) | `tests/platform/vm/run_vm_smoke.sh`, `docs/ops/platform-vm-testing.md`, `scripts/ci/check_stage37_linux_hardening.sh`, `DEF-019`, `DEF-020`, `docs/source/protective_safeguards_catalog_v0_2.md` | оставить открытым |
| `38` | `OPEN` | Process ladder всё ещё зависит от weak/false-green gates и therefore не может считаться окончательно честным; protective guards ещё не обязаны доказывать собственный self-test/failure visibility (`DEF-026`) | `scripts/ci/check_stage_ladder_enforcement.sh`, `scripts/ci/check_storage_stage11_docs.sh`, `scripts/ci/check_protective_safeguards_catalog.sh`, stage37/platform gates | оставить открытым |
| `39..45` | `OPEN` | Continuation stages запрещены к честному закрытию, пока нижние runtime/contract/process основания ещё opened | defect ladder + audit registry layers 3–10 | оставить открытыми до устранения оснований |

## Примечание
Переоткрытие `01..03` меняет первый активный этап в `MASTER` обратно на `01`. Это намеренное действие: ранние основания должны быть восстановлены до дальнейшего линейного продвижения.
