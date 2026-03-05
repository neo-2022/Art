# CHECKLIST 27 — AUDIT / REMEDIATION PLAN (по итогам ревизии MASTER)
Последняя актуализация: 2026-03-05
Дата последней проверки: 2026-03-05

## Цель
Привести фактическую реализацию и критерии [x] в `CHECKLIST_00_MASTER_ART_REGART.md` к реальному, проверяемому состоянию уровня production.

## Итоговая оценка по листам 01-26
- 01 — OK (поддерживать)
- 02 — OK (поддерживать)
- 03 — Условно: усилить runtime/negative tests
- 04 — Условно: усилить supply-chain attestations
- 05 — Условно: снизить зависимость от внешнего репозитория в CI
- 06 — Проблема: gate поверхностный
- 07 — OK
- 08 — OK
- 09 — Условно: усилить интеграционные OTLP проверки
- 10 — Условно: расширить real browser chaos/e2e матрицу
- 11 — OK
- 12 — OK
- 13 — OK
- 14 — Условно: добавить долгий soak с артефактами
- 15 — Условно: углубить неизменяемость/audit at-rest
- 16 — Условно: усилить offline/SW негативные сценарии
- 17 — Проблема: chaos smoke placeholder в CI
- 18 — Условно: усилить receiver chaos matrix
- 19 — Условно: runtime install тестируется из реального pack layout (manifest/payload/signatures)
- 20 — Условно: fixture/examples тестируются через реальный pack dir; усилить e2e через runtime API
- 21 — OK: есть runtime e2e по 4 internal incidents + induced test `metrics_unavailable`
- 22 — OK: synthetic-заглушки заменены runtime smoke (`scripts/tests/test_stage22_e2e.py`, `e2e_smoke.sh`, `e2e_chaos.sh`)
- 23 — Проблема: ops/dr smoke не выполняет реальные сценарии
- 24 — Проблема: signing/upgrade-downgrade не проверяются end-to-end
- 25 — Проблема: export synthetic вместо реального compliance export
- 26 — Проблема: RU policy enforcement не серверный

## Порядок исправления (строго)
1. Stage 06 — усилить gate до кодового/интеграционного уровня (без grep-only).
2. Stage 17 — заменить placeholder job на реальные chaos smoke сценарии.
3. Stage 19-21 — убрать synthetic-only тесты, добавить runtime integration.
4. Stage 22-26 — заменить synthetic/grep smoke на реальные e2e/ops/release/compliance/ru проверки.
5. После каждого stage: evidence, обновление DoD, только потом [x].

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
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`: закрытие только после реального integration evidence.

## Риски, если не исправлять
- Ложное чувство готовности release.
- Провалы на реальном инциденте/аудите.
- Невалидные [x] и разрыв между документацией и системой.
