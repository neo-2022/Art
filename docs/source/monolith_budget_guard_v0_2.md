# Monolith Budget Guard v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `formats/monolith_budget_guard_v0_2.yaml`
- `scripts/ci/check_monolith_budget_guard.sh`

## Что это такое
Это предохранитель против опасной монолитности ключевых файлов и runtime entrypoint-модулей.

Простыми словами:
- проекту запрещено дальше уплотнять самые опасные файлы, пока они не будут разрезаны на более понятные модули;
- рост таких файлов больше не считается “обычной разработкой”, а считается управляемым дефектом.

## Почему это важно
Слишком большой файл — это не просто вопрос стиля.

Это риск:
- bus factor;
- дорогих изменений;
- сложного review;
- плохой локализации дефектов;
- невозможности быстро ввести нового инженера.
- дорогого и опасного рефакторинга уже после выхода в production (продакшен).

## Что именно считается бюджетом
Для каждого критичного файла в `formats/monolith_budget_guard_v0_2.yaml` задаются:
- `path` — путь к файлу;
- `current_lines` — реальное текущее число строк;
- `budget_lines` — верхняя граница, выше которой расти нельзя;
- `owner_contour` — какой stage/runtime-контур владеет этим файлом;
- `defect_ids` — какие defect-строки отвечают за исправление;
- `stages` — какие stage-листы обязаны учесть этот файл;
- `rationale` — почему именно этот файл считается опасной точкой роста.

Текущие охраняемые файлы baseline:
- `core/src/main.rs`
- `apps/console-web/src/main.ts`
- `packages/local-stores/src/index.ts`
- `agent/src/main.rs`
- `browser/src/outbox.js`

## Что guard обязан отслеживать
- line count критичных файлов;
- concentration of responsibilities;
- отсутствие module split plan при превышении бюджета.
- drift между machine-readable budget и реальным размером файла.

## Что считается нарушением
Нарушение есть, если:
- файл перерос свой бюджет;
- в нём смешаны несколько несущих ответственностей;
- нет decomposition plan и stage-binding на исправление.
- `current_lines` в budget-файле уже не совпадает с реальным числом строк;
- файл растёт “по чуть-чуть”, но без выделения новых модулей и без уменьшения ответственности entrypoint-файла.

## Как это работает
1. Критичные файлы описаны в `formats/monolith_budget_guard_v0_2.yaml`.
2. Guard `scripts/ci/check_monolith_budget_guard.sh` автоматически считает реальные строки в файлах.
3. Если файл вырос хотя бы на одну строку выше `budget_lines`, CI падает.
4. Если изменился файл, но budget-файл не синхронизирован, CI тоже падает.
5. Разрешён не рост монолита, а только:
   - удержание текущего размера;
   - сокращение файла;
   - вынос ответственности в отдельные модули.

## Что это решает
- не даёт проекту незаметно уплотняться в самых опасных местах;
- делает рост сложности наблюдаемым, а не “почти незаметным”;
- снижает риск того, что сопровождение будет возможно только для 1–2 людей;
- заставляет начинать decomposition раньше, а не тогда, когда рефакторинг уже стал слишком дорогим.

## Observability и реакция
Gap:
- `observability_gap.monolith_budget_exceeded`

## Связанные runbooks
- `docs/runbooks/monolith_budget_exceeded.md`

## Production-правило
До завершения defect-линии `DEF-017` и materialization budget-guard по `DEF-032`
рост критичных entrypoint-файлов запрещён.

То есть:
- сначала decomposition;
- потом новый рост через модульную структуру;
- но не наоборот.
