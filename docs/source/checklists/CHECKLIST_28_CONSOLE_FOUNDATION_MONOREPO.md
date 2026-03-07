# CHECKLIST 28 — Console Foundation (Monorepo Apps+Packages)
Файл: CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение monorepo layout, import boundaries, foundation routes Console
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Подготовить production-ready фундамент Tier B Console в одном репозитории `Art`: workspace, package boundaries, базовые поверхности UI, i18n и UI-laws runtime checks.

## Границы
- Включено: `pnpm workspace`, `apps/console-web`, `packages/*`, import boundary checks, foundation tests.
- Исключено: перенос/смешивание кода `browser/` с `apps/console-web`.
- Исключено: реализация функций этапов 29..37.

## Зависимости
- CHECKLIST 00 (MASTER)
- CHECKLIST 07 (repo/CI discipline)
- CHECKLIST 16 (Panel0 baseline)
- FOUNDATION_CONSTITUTION_V0_2.md

## Шаги (строго линейно)
- [ ] 1. Сделать: оформить root workspace (`pnpm-workspace.yaml`, root `package.json`, единый `pnpm-lock.yaml`).
  - [ ] Проверка (pass/fail): `corepack pnpm install --frozen-lockfile` возвращает код `0`.
  - [ ] Артефакт результата: `pnpm-lock.yaml` в репозитории + лог установки CI (`console-workspace-install`).
- [ ] 2. Сделать: создать `apps/console-web` и `packages/{ui-laws,i18n,evidence-linking,worker-runtime,local-stores}` с build/test scripts.
  - [ ] Проверка (pass/fail): `corepack pnpm run console:build` возвращает код `0`.
  - [ ] Артефакт результата: файлы `package.json`, `src/*`, `test/*`, `dist/index.html` (на CI).
- [ ] 3. Сделать: зафиксировать import boundaries для monorepo.
  - [ ] Запретить импорт `apps/*` из `browser/*`.
  - [ ] Запретить прямые импорты `core/`, `agent/`, `browser/` из `apps/console-web`.
  - [ ] Запретить прямые относительные импорты в `packages/*` из `apps/console-web` (только через `@art/*`).
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает код `0`.
  - [ ] Артефакт результата: CI job `workspace-boundary-check`.
- [ ] 4. Сделать: реализовать foundation shell с 7 surface routes.
  - [ ] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` возвращает код `0`.
  - [ ] Артефакт результата: тест-отчёт `apps/console-web/test/console-web.test.mjs`.
- [ ] 5. Сделать: enforce i18n foundation (EN default + RU switch) и tooltip laws.
  - [ ] Проверка (pass/fail): `corepack pnpm run console:test` и `node --test browser/test/panel0_i18n_laws.test.js` возвращают код `0`.
  - [ ] Артефакт результата: логи test jobs `console-test`, `panel0-i18n-law-tests`.
 - [ ] 5A. Сделать: разложить двуязычный UI как обязательный сквозной контракт всех foundation surfaces, а не только language toggle.
   - [ ] Требование: EN default + RU switch работают для `routes`, `tooltips`, `errors`, `empty states`, `status labels`, `settings search`, `audio/settings controls`, `keyboard help`, `agent interaction labels`.
   - [ ] Требование: locale сохраняется при переходах между surface routes и не теряется после reload.
   - [ ] Требование: foundation shell не содержит hardcoded user-facing strings вне i18n слоя.
   - [ ] Проверка (pass/fail): test suite подтверждает EN/RU parity для всех foundation routes и отрицательно падает на hardcoded string fixture.
   - [ ] Артефакт результата: i18n parity test log + negative fixture log.
- [ ] 6. Сделать: внедрить observability-gap контроль нарушений boundaries.
  - [ ] Событие: `observability_gap.console_workspace_boundary_violation`.
  - [ ] evidence_min: `module`, `import_path`, `rule`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/console_workspace_boundary_violation.md`.
  - [ ] Проверка (pass/fail): запись присутствует в `docs/governance/observability_gap_registry.md` и runbook файл существует.
  - [ ] Артефакт результата: diff registry + runbook.
- [ ] 7. Сделать: зафиксировать метрику архитектурной чистоты `forbidden_import_count=0`.
  - [ ] Проверка (pass/fail): `bash scripts/ci/check_workspace_boundaries.sh` возвращает `forbidden_import_count=0`.
  - [ ] Артефакт результата: отчёт boundary-check с метрикой.
- [ ] 8. Сделать: внедрить Lens governance как обязательный нормативный контур этапа 28.
  - [ ] Проверка (pass/fail): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` содержит `APPENDIX A — LENS CATALOG`, `A0.0 Classification rule`, `A0.1 Primary / Secondary / Anti-pattern mapping`.
  - [ ] Проверка (pass/fail): `test -s docs/foundation/lens_audit_report.md` и `rg -n "^Class: (Primary|Secondary|Anti-pattern)$" docs/foundation/lens_audit_report.md`.
  - [ ] Проверка (pass/fail): `rg -n "Evidence-anchored AI|claims без evidence_refs|Code-and-Fix|Timeboxing" docs/source/FOUNDATION_CONSTITUTION_V0_2.md`.
  - [ ] Артефакт результата: diff Foundation Appendix + `docs/foundation/lens_audit_report.md` + CI log `stage28-docs-gate`.
- [ ] 9. Сделать: добавить отдельный gate `stage28-lens-gate` с проверками Lens governance.
  - [ ] Проверка (pass/fail): `.github/workflows/ci.yml` содержит job `stage28-lens-gate`, выполняющий `bash scripts/ci/check_stage28_lens.sh`.
  - [ ] Артефакт результата: diff workflow + лог job.
- [ ] 10. Сделать: добавить negative smoke для boundary enforcement.
  - [ ] Проверка (pass/fail): `bash scripts/tests/workspace_boundary_negative_smoke.sh` возвращает код `0` и подтверждает FAIL boundary-check при искусственном нарушении.
  - [ ] Артефакт результата: negative smoke log.
- [ ] 11. Сделать: зафиксировать интерфейсную лестницу реализации (`L0->L1->L2->L3`) как обязательный контракт этапов.
  - [ ] L0 (stage 28): shell + surfaces skeleton + i18n + tooltip/evidence navigation.
  - [ ] L1 (stage 30/31): truth modes + dialog lineage + investigation library baseline.
  - [ ] L2 (stage 35): flow mode 2D (inspect/snapshot/replay/diff) + adaptive settings.
  - [ ] L3 (post-35): 3D projection как проекция L2 без новых source-of-truth.
  - [ ] Проверка (pass/fail): `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` содержит разделы `Truth Modes Law`, `Visual Flow Mode Specification`, `Adaptive UX Policy`, `Tiered Testing and CI Law`.
  - [ ] Артефакт результата: diff Foundation.
- [ ] 12. Сделать: зафиксировать обязательный anti-breakage набор тестов ранних этапов для будущих интерфейсных слоёв.
  - [ ] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` содержит проверки surfaces/i18n/tooltips/evidence links и остаётся PASS после изменений stage 30+.
  - [ ] Артефакт результата: test log + checklist reference matrix.
- [ ] 12A. Сделать: заложить foundation contract взаимодействия человека с агентом и агентных поверхностей Console.
  - [ ] Требование: уже на этапе foundation должны быть определены точки входа `ask agent`, `review agent proposal`, `approve/reject`, `show evidence`, `show why`, `show audit trail`.
  - [ ] Требование: agent UI не имеет права действовать как “магический чат”; только evidence-anchored interaction objects.
  - [ ] Требование: foundation shell различает `human`, `agent`, `system` actors визуально и текстово.
  - [ ] Проверка (pass/fail): существует документ модели взаимодействия и foundation tests подтверждают наличие маршрутов/компонентов-заглушек без silent-action path.
  - [ ] Артефакт результата: interaction model doc + foundation test log.
- [ ] 12B. Сделать: заложить Layer E / Agent Workspace как обязательный foundation слой данных и UX.
  - [ ] Требование: `packages/local-stores` и foundation docs фиксируют `Agent Workspace` как отдельный local layer для задач, артефактов анализа, proposal queue и replayable agent traces.
  - [ ] Требование: agent workspace не создаёт собственную «истину» и хранит только evidence-anchored derived artifacts.
  - [ ] Требование: foundation shell содержит route/placeholder для agent workspace navigation без silent execution path.
  - [ ] Проверка (pass/fail): существует source-of-truth документ agent workspace model и foundation tests подтверждают наличие route/store contract.
  - [ ] Артефакт результата: agent workspace model doc + foundation route/store test log.
- [ ] 13. Сделать: заложить foundation settings framework с поиском по настройкам и иерархией групп.
  - [ ] Проверка (pass/fail): Console shell содержит settings search + grouped sections (`visual`, `opacity`, `colors`, `audio`) и фильтрацию пунктов по query.
  - [ ] Артефакт результата: e2e screenshot + test log.
- [ ] 14. Сделать: заложить audio effects framework с legal-safe baseline и пользовательской заменой каждого эффекта.
  - [ ] Требование: default эффекты генерируются процедурно (без внешних audio assets).
  - [ ] Требование: для каждого эффекта доступны `preview`, `replace`, `clear`.
  - [ ] Требование: есть явный legal warning о правах на пользовательский контент.
  - [ ] Проверка (pass/fail): `corepack pnpm --filter ./apps/console-web run test` PASS и подтверждает наличие audio controls + replace hooks.
  - [ ] Артефакт результата: test log + foundation diff.
- [ ] 15. Сделать: внедрить runtime e2e suite для audio/settings цепочки.
  - [ ] Проверка (pass/fail): `bash scripts/tests/console_audio_settings_e2e.sh` PASS (`search -> preview -> custom-status -> clear`).
  - [ ] Артефакт результата: e2e log + обновление CI job `stage28-audio-settings-e2e`.
- [ ] 16. Сделать: зафиксировать информационную архитектуру меню настроек всего проекта.
  - [ ] Проверка (pass/fail): документ `docs/source/console_settings_architecture_v0_2.md` содержит структуру уровней (`Global/Organization/Project/Environment/User`), категории/подкатегории, policy lock и search model.
  - [ ] Артефакт результата: settings architecture doc diff + ссылочный раздел в Foundation.
- [ ] 17. Сделать: реализовать Settings Profile Manager (`save/apply/delete/export/import`) для user-scope настроек.
  - [ ] Проверка (pass/fail): runtime e2e подтверждает цикл `save -> apply -> export -> import -> delete` с корректными status-сообщениями.
  - [ ] Проверка (pass/fail): policy-locked controls помечены и не изменяются через profile apply.
  - [ ] Артефакт результата: profile manager e2e log + UI screenshot.
- [ ] 18. Сделать: закрепить browser surface hardening как обязательный foundation law для Console shell.
  - [ ] Требование: foundation shell и static build не имеют права ослаблять CSP/frame/integrity baseline ради dev/showcase paths.
  - [ ] Требование: actor context (`human/agent/system`) отображается только из trusted context и не может spoof’иться через UI shell.
  - [ ] Проверка (pass/fail): foundation docs/tests подтверждают browser hardening baseline и trusted actor context negative path.
  - [ ] Артефакт результата: browser hardening foundation diff + negative-path test log.
- [ ] 19. Сделать: заложить Connected System View как обязательный foundation contour для внешних систем.
  - [ ] Требование: после успешного подключения внешней системы Console показывает отдельную сущность системы, а не только косвенные события.
  - [ ] Требование: минимум видны:
    - [ ] `display_name`
    - [ ] `integration_kind`
    - [ ] `connection_status`
    - [ ] `declared_data_kinds`
    - [ ] `observed_data_kinds`
    - [ ] `receiver_kinds`
    - [ ] `telemetry_endpoints`
    - [ ] `active_gap_events`
    - [ ] `evidence_refs`
  - [ ] Требование: статус `connected` запрещён без свежих observed signals.
  - [ ] Требование: drift между declared и observed coverage показывается явно, а не прячется за зелёным статусом.
  - [ ] Проверка (pass/fail): foundation docs/tests подтверждают наличие Connected System View law и обязательных полей, а docs gate валится при отсутствии `docs/source/connected_system_visibility_v0_2.md`.
  - [ ] Артефакт результата: foundation diff + connected-system gate log.

## Документация (RU)
- [ ] docs/source/FOUNDATION_CONSTITUTION_V0_2.md
- [ ] docs/source/checklists/TRACEABILITY_V0_2.md
- [ ] docs/source/checklists/README.md
- [ ] docs/source/README.md
- [ ] docs/foundation/lens_audit_report.md
- [ ] docs/runbooks/console_workspace_boundary_violation.md
- [ ] docs/source/risk_register_v0_2.md
- [ ] docs/source/console_settings_architecture_v0_2.md
- [ ] docs/source/console_agent_interaction_model_v0_2.md
- [ ] docs/source/agent_workspace_model_v0_2.md
- [ ] docs/source/browser_surface_hardening_v0_2.md
- [ ] docs/source/trust_boundary_hardening_v0_2.md
- [ ] docs/source/connected_system_visibility_v0_2.md

## Тестирование
- [ ] unit: пакеты `packages/*` покрыты тестами и запускаются в CI.
- [ ] integration: routing foundation shell в `apps/console-web`.
- [ ] integration: EN/RU parity across all foundation surfaces and settings/agent labels.
- [ ] e2e: Linux headless smoke открытия foundation shell.
- [ ] e2e: foundation agent interaction route exists, shows evidence-first placeholders and preserves locale.
- [ ] integration: agent workspace route/store contract exists and remains evidence-anchored.
- [ ] regression: интерфейсная лестница L0 сохраняет обратную совместимость при переходе к L1/L2.
- [ ] integration: settings search фильтрует пункты без потери доступности.
- [ ] integration: audio replace/preview/clear работает по каждому baseline эффекту.
- [ ] e2e: search + audio preview + custom replace status + clear cycle.
- [ ] e2e: settings profile manager cycle (`save/apply/export/import/delete`) + policy-lock behavior.
- [ ] negative: Console shell не допускает hardcoded/unsafe browser surface path и spoofed actor context.
- [ ] chaos: отрицательный boundary case (прямой импорт запрещённого пути) падает в CI.
- [ ] load: не применяется на этапе 28; переносится в этап 34.
- [ ] soak: не применяется на этапе 28; переносится в этап 34.

## CI gate
- [ ] `stage28-docs-gate`
- [ ] `stage28-risk-gate`
- [ ] `console-workspace-install`
- [ ] `console-lint`
- [ ] `console-test`
- [ ] `console-build`
- [ ] `workspace-boundary-check`
- [ ] `workspace-boundary-negative-smoke`
- [ ] `panel0-i18n-law-tests`
- [ ] `stage28-lens-gate`
- [ ] `stage28-audio-settings-e2e`

## DoD
- [ ] Workspace и foundation app/packages воспроизводимо собираются на Linux CI.
- [ ] Boundary violations блокируются автоматически.
- [ ] Foundation shell содержит 7 поверхностей и проходит test suite.
- [ ] Lens Catalog классифицирован (Primary/Secondary/Anti-pattern) и проверяется в stage28 docs gate.
- [ ] Lens governance проверяется отдельным CI gate `stage28-lens-gate`.
- [ ] Отрицательный boundary smoke подтверждает автоматическую блокировку запрещённых импортов.
- [ ] Интерфейсная лестница L0->L3 задокументирована и проверяется как обязательный anti-breakage контракт.
- [ ] Settings framework (с поиском) и audio effects framework (replace/preview/clear) реализованы и покрыты тестами.
- [ ] Полный двуязычный foundation UI подтверждён не только toggle, но и parity всех surface states.
- [ ] Browser surface hardening и trusted actor context закреплены как foundation laws, а не как поздний optional hardening.
- [ ] Connected System View заложен как обязательный foundation contour для всех внешних систем и pack-based integrations.
- [ ] Модель взаимодействия человека с агентом заложена в Console foundation без “магического чата”.
- [ ] Layer E / Agent Workspace заложен как ранний foundation contour, а не отложен до поздних этапов.
- [ ] Карта меню настроек проекта зафиксирована как расширяемый контракт уровней и policy-lock.
- [ ] observability-gap событие этапа 28 задокументировано в registry + runbook.
- [ ] Риск R1 из risk register подтверждён метрикой `forbidden_import_count=0`.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: CHECKLIST_29 запрещён до полного закрытия CHECKLIST_28.
- Артефакты закрытия: CI logs + ссылки на коммит + обновлённый registry.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
