# Release Decisions

## Source of truth
- `docs/ops/go_no_go_template.md`
- `docs/en/ops/go_no_go_template.md`
- `docs/release/release_process.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Назначение
Этот каталог хранит фактические операционные решения `GO/NO-GO` для release candidate, canary expansion и production rollout.

## Правила
1. `latest_go_no_go.md` обязателен и отражает последнее актуальное решение.
2. Решение `GO` допустимо только при заполненных mandatory gates и приложенных evidence.
3. Решение должно ссылаться на конкретный commit/tag и CI run.
4. Если решение заменено новым, старый файл сохраняется как исторический артефакт, а `latest_go_no_go.md` обновляется.

## Минимальный формат имени исторического файла
- `YYYY-MM-DD_<release-id>_go_no_go.md`

## Текущий активный файл
- `docs/governance/release_decisions/latest_go_no_go.md`
