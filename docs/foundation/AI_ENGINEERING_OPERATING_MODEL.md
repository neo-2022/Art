# AI Engineering Operating Model (Art)

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/foundation/lens_audit_report.md`

Последняя актуализация: 2026-03-06
Статус: ACTIVE BACKLOG

## 1. Назначение
Этот документ фиксирует, как должна работать AI-ориентированная инженерная команда проекта Art, чтобы большой продукт не деградировал из-за потери контекста, несинхронности решений и разрыва между кодом, тестами, контрактами и документацией.

## 2. Почему это важно
Art уже вышел из масштаба, где один универсальный агент или один инженерный поток могут стабильно удерживать весь контур проекта. В проекте одновременно присутствуют:
- системное ядро на Rust;
- API и контрактный слой;
- аварийный UI;
- основной Console UI;
- evidence/governance/release контуры;
- perf/security/privacy/platform readiness.

Без формальной операционной модели AI-команды появляется риск:
- потери замысла;
- ложных `[x]` в чек-листах;
- конфликтов между кодом и документацией;
- недовнесённых концепций;
- локальной оптимизации в ущерб целостности продукта.

## 3. Принцип работы
AI-команда должна работать не как один "всезнающий исполнитель", а как набор ролей с общей инженерной дисциплиной и общей базой знаний.

## 4. Канонические роли

### 4.1 Архитектор
Обычно человек, но может поддерживаться AI-помощником.

Отвечает за:
- стратегию продукта;
- утверждение foundation и checklist контуров;
- разрешение конфликтов между скоростью, качеством и scope;
- принятие финальных решений по переходу экспериментальных концепций в mandatory.

### 4.2 Инженер ядра
Отвечает за:
- `core/`
- `agent/`
- детерминизм DNA
- runtime/perf/reliability свойства
- platform/runtime compatibility

### 4.3 Инженер API и контрактов
Отвечает за:
- `docs/contracts/*`
- OpenAPI / JSON Schema
- compatibility rules
- migrations
- contract fingerprint и dual-write semantics

### 4.4 Инженер интерфейса
Отвечает за:
- `apps/console-web`
- `packages/*`
- UI laws
- surfaces
- i18n
- settings/design/runtime ergonomics

### 4.5 Инженер тестирования
Отвечает за:
- unit/integration/e2e/load/perf/soak suites
- anti-breakage контуры
- regression gates
- VM/Docker/K8s/Linux runtime harnesses

### 4.6 Инженер документации и governance
Отвечает за:
- `docs/`
- traceability
- source-of-truth consistency
- release evidence
- checklist truthfulness
- runbooks и operational guidance

## 5. Общая база знаний
Обязательное правило:
- все значимые решения должны существовать не только в чате и не только в коде, а в общем knowledge contour проекта.

Минимум, который должен быть синхронизирован:
- Foundation / Constitution
- checklist mapping
- contracts
- runbooks
- risk register
- evidence ledger
- historical concepts / hypotheses / radar

## 6. Операционный цикл работы

### 6.1 Перед началом этапа
Каждый исполнительный контур должен получить:
- текущий статус MASTER;
- статус целевого checklist;
- актуальные blockers;
- список открытых gaps из foundation/lens/risk/runtime audit.

### 6.2 Во время выполнения
Обязательная последовательность:
1. открыть checklist;
2. выполнить текущий пункт буквально;
3. сделать именно то, что требует пункт;
4. выполнить указанную в пункте проверку;
5. убедиться в наличии артефакта;
6. только потом ставить `[x]`.

### 6.3 После завершения этапа
Обязательны:
- короткий отчёт о факте выполнения;
- evidence/artifact registration;
- проверка, не сломаны ли соседние контуры;
- обновление docs, если поведение реально изменилось.

## 7. Утренний брифинг и ретроспектива
Для длинного проекта обязательно:
- перед новым циклом формировать краткую сводку текущего состояния;
- после завершения этапа фиксировать lessons learned и повторяющиеся ошибки.

Это нужно, чтобы AI-исполнение не теряло накопленный опыт и не повторяло одни и те же сбои.

## 8. Двойная проверка
Для критичных контуров должно действовать правило двойной проверки:
- один контур реализует;
- другой проверяет на security/correctness/traceability;
- финальная оценка идёт только после согласования или явной эскалации.

Особенно это важно для:
- DNA
- security/release
- audit/merkle
- actions
- docs/checklist truthfulness

## 9. Checklist mapping
Текущий mapping этого документа в программу:
- `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md` — foundation governance, workspace discipline, lens/source-of-truth cohesion.
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md` — разделение ролей вокруг DNA/contracts/perf.
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md` — truthfulness, stage discipline, evidence-ledger alignment.

Что ещё не доведено до enforceable состояния:
- machine-readable role/task mapping;
- lessons learned ledger;
- explicit review-duty matrix для критичных контуров.

## 10. Verification path
Документ считается полностью operationalized только после появления:
- явного checklist шага или отдельного stage extension;
- machine-readable role map;
- CI/gate, который проверяет truthfulness и обязательность review split для критичных изменений.

## 11. Anti-patterns
Запрещено:
- закрывать чек-листы формально;
- считать chat-memory источником истины;
- заменять checklist verification "на глаз";
- переносить архитектурные решения в код без отражения в foundation/contracts, если это меняет поведение системы;
- размывать роли до состояния "все делают всё" на сложных этапах.

## 12. Что должно появиться дальше
Этот документ пока фиксирует operating model на описательном уровне. Для полного внедрения нужны:
- checklist mapping для AI-team governance;
- machine-readable role/task mapping;
- формализованный format lessons learned;
- gate на truthfulness изменений в foundation/checklists/docs.
