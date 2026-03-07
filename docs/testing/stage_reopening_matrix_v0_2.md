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
| `11` | `OPEN` | Storage/systemd vacuum path broken | `systemd/art-vacuum.service`, `systemd/art-vacuum.timer` | оставить открытым |
| `17` | `OPEN` | Agent spool runtime остаётся in-memory, restart destroys backlog | `agent/src/main.rs` | оставить открытым |
| `18` | `OPEN` | Agent transport/receiver contour не материализован | `agent/src/main.rs`, receiver gaps, no outbound/relay/TLS | оставить открытым |
| `19` | `OPEN` | Pack runtime позволяет placeholder payload | `scripts/tests/pack_install_runtime.sh`, `scripts/tests/packs_runtime.py` | оставить открытым |
| `20` | `OPEN` | REGART pack contour отстаёт от approved external-source coverage | `packs/regart/manifest.yaml`, `packs/regart/examples/receivers.toml` | оставить открытым |
| `24` | `OPEN` | Release/provenance corpus тоньше buyer-grade due diligence | `RELEASE_CHECKLIST.md`, `CHANGELOG.md`, `docs/governance/release_process.md`, `check_release_signing_pipeline.sh` | оставить открытым |
| `28` | `OPEN` | Console foundation overclaim’ит bilingual/agent/source-of-truth completeness | missing `console_agent_interaction_model_v0_2.md`, screenshot with EN-only UI | оставить открытым |
| `29..45` | `OPEN` | Continuation/runtime stages опираются на ещё не устранённые корневые дефекты и/или missing source files/runbooks | audit registry layers 3–10 + missing file check | оставить открытыми до устранения оснований |

## Примечание
Переоткрытие `01..03` меняет первый активный этап в `MASTER` обратно на `01`. Это намеренное действие: ранние основания должны быть восстановлены до дальнейшего линейного продвижения.
