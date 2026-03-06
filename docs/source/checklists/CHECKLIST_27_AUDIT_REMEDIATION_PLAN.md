# CHECKLIST 27 — AUDIT / REMEDIATION PLAN (по итогам ревизии MASTER)
Последняя актуализация: 2026-03-05
Дата последней проверки: 2026-03-05

## Цель
Привести фактическую реализацию и критерии [x] в `CHECKLIST_00_MASTER_ART_REGART.md` к реальному, проверяемому состоянию уровня production.

## Итоговая оценка по листам 01-26
- 01 — OK (поддерживать)
- 02 — OK (поддерживать)
- 03 — OK: добавлен runtime negative integration (`scripts/tests/profile_negative_runtime_integration.sh`) + CI job `stage03-profile-negative-integration`
- 04 — OK: усилены supply-chain attestations (`provenance.attestation.json` + verify в `release_stage04.yml`)
- 05 — OK: зависимость от внешнего репозитория снижена (Stage05 gate имеет локальный CI mode без clone + strict mode для source-of-truth)
- 06 — OK: gate усилен (кодовые проверки strict mode + проверка консистентности parent/child чекбоксов)
- 07 — OK
- 08 — OK
- 09 — OK: добавлен runtime OTLP integration (`/otlp/v1/logs`, tests `otlp_logs_*`, `scripts/tests/otlp_runtime_integration.sh`)
- 10 — OK: расширена real browser chaos/e2e матрица (`browser/test/level0.chaos.e2e.test.js`, CI job `stage10-chaos-e2e`)
- 11 — OK
- 12 — OK
- 13 — OK
- 14 — OK: добавлен long soak с артефактами (`scripts/tests/stream_soak_with_artifacts.sh`, workflow `.github/workflows/stage14-soak-artifacts.yml`)
- 15 — OK: углублена неизменяемость audit (hash-chain `prev_hash/entry_hash` + `GET /api/v1/audit/verify` + tamper detection tests)
- 16 — OK: усилены offline/SW негативные сценарии (cache-miss→503 `x-art-offline`, cache put fail, secure-context gate)
- 17 — OK: placeholder удалён, CI smoke выполняет runtime chaos (`scripts/tests/agent_spool_chaos_runtime.sh`)
- 18 — OK: усилена receiver chaos matrix (`scripts/tests/agent_receivers_chaos_runtime.sh`, CI job `agent-receivers-chaos-runtime`)
- 19 — OK: runtime install тестируется из реального pack layout (`scripts/tests/pack_install_runtime.sh`, CI job `packs-runtime-install`)
- 20 — OK: fixture/examples тестируются через реальный pack dir + runtime API (`scripts/tests/pack_regart_runtime_api.sh`, CI job `pack-regart-runtime-api`)
- 21 — OK: есть runtime e2e по 4 internal incidents + induced test `metrics_unavailable`
- 22 — OK: synthetic-заглушки заменены runtime smoke (`scripts/tests/test_stage22_e2e.py`, `e2e_smoke.sh`, `e2e_chaos.sh`)
- 23 — OK: ops/dr smoke переведён в runtime (`scripts/tests/ops_stage23_smoke.sh`: backup/restore + ingest→snapshot + SIGHUP stream survival)
- 24 — OK: upgrade/downgrade переведён в runtime API suite (`scripts/tests/test_upgrade_downgrade.py`), release signing verify согласован с keyless OIDC workflow (`release_stage04.yml`)
- 25 — OK: export переведён с synthetic на runtime (`scripts/export_audit_pack.sh` читает `/api/v1/incidents` и `/api/v1/audit`, integration test запускает real core)
- 26 — OK: RU export policy переведён в server-side enforcement (`scripts/export_audit_pack.sh` берёт `effective_profile_id` из Core snapshot + allowlist `RU_EXPORT_ALLOWLIST_ROOT`)

## Порядок исправления (строго)
1. Stage 18 — усилить receiver chaos matrix.
2. Stage 19-21 — убрать synthetic-only тесты, добавить runtime integration.
3. Stage 22-26 — заменить synthetic/grep smoke на реальные e2e/ops/release/compliance/ru проверки.
4. После каждого stage: evidence, обновление DoD, только потом [x].

## Минимальные критерии «можно ставить [x]»
- Есть runtime test/интеграционный сценарий с fail/pass критериями.
- Есть артефакты (логи/метрики/ссылки CI), воспроизводимые командой.
- CI job проверяет поведение, а не только наличие текста в docs.
- Для incident/gap сценариев: событие реально генерируется и проверяется.

## Критичные исправления по файлам
- `.github/workflows/ci.yml`: убрать placeholder и grep-only jobs для 17,23,24,25,26.
- `test_upgrade_downgrade.py`: перейти от synthetic констант к runtime проверкам.
- `test_self_observability.py`: поддерживать связку с runtime smoke (`scripts/tests/self_observability_runtime_smoke.sh`) и не допускать отката к synthetic-only.
- `scripts/export_audit_pack.sh`: экспорт из реальных данных, не synthetic JSON.
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`: закрытие только после реального integration evidence (выполнено).

## Риски, если не исправлять
- Ложное чувство готовности release.
- Провалы на реальном инциденте/аудите.
- Невалидные [x] и разрыв между документацией и системой.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
