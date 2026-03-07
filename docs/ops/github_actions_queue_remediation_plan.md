# План устранения очередей GitHub Actions и переработки CI fan-out

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/source/checklists/CHECKLIST_07_ART_REPO_CI_DOCS.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `.github/workflows/ci.yml`
- `.github/workflows/security_stage04.yml`
- `.github/workflows/required_gates.yml`

## Контекст
На PR `#21` наблюдается массовое состояние `QUEUED` для более чем 100 checks.
Это не контентная ошибка конкретного job, а перегрузка CI-контуров:

- один PR одновременно запускает `ci`, `security-stage04` и `required-gates`;
- основной `ci.yml` содержит очень большой fan-out jobs на `ubuntu-latest`;
- часть security jobs дублируется между workflow;
- тяжёлые stage suites запускаются даже тогда, когда изменение не затрагивает соответствующий контур;
- branch protection ждёт результата, но GitHub-hosted runners не выдают достаточный параллелизм.

## Цель
Сделать PR-путь быстрым и управляемым:

- required merge gates выполняются быстро;
- тяжёлые и дорогие suites не запускаются без причины;
- security и release контуры не дублируются;
- очередь GitHub Actions перестаёт быть нормой;
- production/release контур остаётся полным, но переносится в appropriate execution path.

## Симптомы, которые считаются дефектом
- более 20 обязательных checks одновременно в статусе `QUEUED` на обычном PR;
- один docs-only PR запускает тяжёлые runtime/perf/platform suites;
- одинаковые security jobs идут более чем в одном workflow без необходимости;
- PR review blocked не из-за падения tests, а из-за долгой очереди runners;
- required checks list содержит jobs, которые по смыслу относятся к nightly/release-only контру.

## Проектное решение

### 1. Разделить CI на 3 класса

#### A. `required-fast`
Запускается на каждый PR в `main`.
Назначение: быстрое blocking-решение для merge.

Сюда входят только:
- status integrity / checklist integrity / docs traceability;
- branch/security policy gates;
- минимальные contract/docs gates;
- минимальный build/smoke для реально затронутых контуров;
- security jobs, которые branch protection требует явно.

Целевой бюджет:
- старт jobs: не более 2 минут ожидания;
- полный required-fast pipeline: не более 15 минут на типичный PR.

#### B. `extended-pr`
Запускается на PR только при изменении релевантных путей или вручную.
Назначение: расширенная техническая проверка без превращения любого PR в release rehearsal.

Сюда переносятся:
- тяжёлые integration suites по stage-специфике;
- console/perf/spatial suites по `paths`;
- часть negative scenarios и heavy runtime suites.

#### C. `nightly-release`
Запускается по расписанию, вручную или на release candidate.
Назначение: тяжёлые контуры, которые обязательны для качества продукта, но не должны блокировать любой PR.

Сюда переносятся:
- heavy perf/load;
- миллионные property/determinism suites;
- полные platform matrix suites;
- soak/chaos/nightly replays;
- release artifact and publish rehearsals.

### 2. Убрать дублирование security workflows
Единый набор security jobs должен жить в одном месте и переиспользоваться.

Правило:
- `sdlc-gate`, `sast`, `sca`, `license`, `secrets` не должны дублироваться между `ci.yml`, `security_stage04.yml` и `required_gates.yml`;
- обязательный путь:
  - либо один security workflow,
  - либо reusable workflow через `workflow_call`,
  - но не параллельные дубли одних и тех же jobs.

### 3. Ввести path-based trigger discipline
Каждый тяжёлый контур должен запускаться только по релевантным изменениям.

Примеры:
- docs-only изменения не запускают heavy runtime/perf/platform suites;
- изменения только в `docs/portal`, `docs/ops`, `README.md` не запускают stage29/stage34/stage35/stage37 runtime suites;
- изменения только в `apps/console-web` и `packages/*` не запускают unrelated `agent/core` heavy jobs;
- изменения только в `core/agent` не запускают unrelated console-showcase jobs.

### 4. Ввести concurrency policy
Для PR-run нужен жёсткий `concurrency`:
- новая ревизия PR отменяет устаревшие pending/in-progress runs для той же ветки;
- stale runs не должны продолжать занимать очередь;
- nightly/release workflows используют отдельные concurrency groups.

### 5. Пересмотреть required checks для branch protection
Required checks должны быть:
- быстрыми;
- стабильными;
- содержательно merge-blocking;
- не зависеть от release-only и nightly-only suites.

В required checks не должны входить:
- тяжёлые perf/load suites;
- full platform matrix;
- showcase/perf/3D heavy jobs;
- nightly replay/perf jobs;
- release publish rehearsal.

### 6. Вынести heavy suites из every-PR path
Следующие типы jobs должны перейти в `extended-pr` или `nightly-release`:
- stage29 million/property determinism;
- stage34 heavy perf/load;
- часть stage35 flow/perf;
- часть stage37 platform matrix;
- длительные chaos/soak/replay suites.

### 7. Ввести reusable workflow architecture
Новая схема:
- `required_fast.yml`
- `extended_pr.yml`
- `nightly_release.yml`
- reusable modules:
  - `security_reusable.yml`
  - `docs_reusable.yml`
  - `runtime_smoke_reusable.yml`

Цель:
- не копировать одни и те же jobs по разным workflow;
- управлять очередью и логикой исполнения централизованно.

### 8. Подготовить self-hosted runner path как следующий уровень
Если нужно сохранить большой объём проверок на каждый PR, GitHub-hosted runners недостаточны.

Поэтому:
- GitHub-hosted путь остаётся baseline;
- для heavy release/perf/platform suites подготавливается self-hosted pool;
- без этого full fan-out на каждый PR считается operationally unsound.

## Пошаговый execution plan

### Шаг 1. Инвентаризация всех jobs
Для каждого job зафиксировать:
- workflow;
- stage/checklist owner;
- среднюю длительность;
- required/non-required status;
- какой путь изменения должен его триггерить;
- можно ли перенести в nightly/release-only.

Артефакт:
- `docs/ops/github_actions_job_inventory.md`

### Шаг 2. Классификация jobs
Каждый job получает класс:
- `required-fast`
- `extended-pr`
- `nightly-release`

Артефакт:
- `formats/ci_job_classes.yaml`

### Шаг 3. Удаление дублирования security jobs
Привести `security-stage04` и `required-gates` к одной модели:
- security jobs объявляются один раз;
- required-gates либо вызывает reusable workflow, либо исчезает как duplicate wrapper.

### Шаг 4. Path filters
Для `extended-pr` и части `required-fast` добавить `paths`/`paths-ignore`.

### Шаг 5. Concurrency
Ввести:
- `cancel-in-progress: true` на PR branches;
- отдельные concurrency groups для nightly и release.

### Шаг 6. Обновление branch protection
После новой классификации required checks список branch protection обновляется.

### Шаг 7. Release/nightly hardening
Убедиться, что из PR fast-path ничего критичного не потеряно:
- release контур остаётся полным;
- nightly replay/perf/platform suites продолжают работать;
- GO/NO-GO опирается на полный набор release/nightly evidence.

## Что запрещено
- считать очередь GitHub Actions “нормальной ценой качества”;
- оставлять duplicate jobs в разных workflow;
- делать любой PR эквивалентом полного release rehearsal;
- расширять required checks без классификации job class;
- переводить heavy jobs в required list без budget justification.

## Критерии готовности
- обычный docs/config PR не запускает heavy runtime/perf/platform suites;
- required checks на PR ограничены быстрым и действительно блокирующим набором;
- stale runs отменяются автоматически;
- security jobs не дублируются в нескольких workflow;
- release/nightly контур остаётся полным и доказуемым;
- массовое состояние `100+ queued` перестаёт быть типичным.

## Почему это обязательно
Если эту проблему не решить сейчас, дальнейшее расширение программы `04..45` будет:
- замедлять merge path;
- создавать ложное ощущение “всё проверяем”, хотя jobs стоят в очереди;
- мешать реальной инженерной обратной связи;
- делать provenance слабее, потому что доказательство качества будет зависеть от случайной доступности runner slots.
