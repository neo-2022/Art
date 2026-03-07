# FOUNDATION / CONSTITUTION v0.2 (Art Monorepo)

Статус: ACTIVE
Версия: v0.2
Последняя актуализация: 2026-03-06

## 1. Цель
Зафиксировать обязательные инварианты Art как единого продукта в одном репозитории (`Art`) с архитектурным разделением Tier A (Panel0), Tier B (Console), Tier C (SaaS), без двусмысленности.

## 2. Область действия
Документ обязателен для:
- `core/` (Rust Core)
- `agent/` (Rust Agent)
- `browser/` (Level0 + Panel0 libs/tests)
- `apps/console-web` (Tier B Console)
- `packages/*` (общие runtime-пакеты Console)
- `docs/contracts/v2/*`
- `docs/source/checklists/CHECKLIST_28..38*`

## 3. Границы репозитория
- Art и Console ведутся в одном репозитории `Art` (monorepo).
- `browser/` не является Console-приложением. Это строго Level0/Panel0.
- `apps/console-web` не импортирует код из `core/`, `agent/`, `browser/` напрямую.
- Console использует только API-контракты Core (`/api/v1/*`, `/api/v2/*`) и workspace-пакеты `packages/*`.

## 4. Продуктовые инварианты
1. `Core = source of truth`.
2. `Evidence-First`: claim/hypothesis/recommendation запрещены без `evidence_refs[]`.
3. `Tooltip everywhere`: каждый интерактивный элемент обязан иметь tooltip key.
4. `One-click-to-evidence`: любой gap/claim/decision имеет переход к первичному evidence.
5. `Zero-lag UX`: тяжёлые вычисления выполняются в workers/wasm.
6. `Privacy-by-design`: redaction выполняется до UI/cache/index.
7. `Audit immutability`: журнал действий append-only и верифицируемый.
8. `Panel0 resilience`: Core DOWN/Console DOWN не блокирует аварийный UI.
9. `No checklist skipping`: переход к следующему этапу запрещён до PASS текущего.

## 5. Трёхуровневая архитектура
### 5.1 Tier A (Panel0)
- Embedded-ассеты в бинарнике Core.
- Авто-fallback с `GET /` за 5000ms.
- Event при отказе Console: `observability_gap.console_boot_failed`.
- Поддержка EN default + RU switch.

### 5.2 Tier B (Console)
- Реализация в `apps/console-web`.
- Поверхности: Command Center, Event River, Incident Room, Scenario View, Time Field, Audit Explorer, Action Studio.
- Локальные слои данных реализуются через `packages/local-stores`.

### 5.3 Tier C (SaaS)
- Обязательная модель: tenant isolation + quotas + retention + compliance export.
- Контракты SaaS определяются на этапе 36 и применяются к self-hosted/SaaS режимам одинаково.

## 6. API эволюция
- `/api/v1/*` сохраняется минимум 2 release cycles после запуска `/api/v2/*`.
- `/api/v2/*` добавляется параллельно без breaking change для v1.
- Canonical contracts: `docs/contracts/v2/openapi.yaml` и `docs/contracts/v2/schemas/*.json`.
- Для API v2 обязательны: forward-compatible migration и rollback script.

## 7. DNA / Evidence / Claims / Dialogic
- DNA signature обязательна: `dna_id`, `canonical_hash`, `payload_hash`, `dna_schema_version`.
- Canonicalization детерминирована; изменение алгоритма только через bump `dna_schema_version`.
- DNA assurance обязателен по документу `docs/source/dna_core_determinism_performance_assurance.md` (этапы 0..7).
- EvidenceBlock обязателен с полями доверия/свежести/политики/области доступа.
- Claim невалиден без `proof_set` и `evidence_refs`.
- Dialog protocol допускает только типы: `Hypothesis`, `Decision`, `ActionRequest`, `ActionResult`, `Explanation`.

### 7.1 DNA Engine Safety Law (обязательный)
1. До production rollout DNA Core обязателен formal model (`docs/contracts/v2/dna_model/*`).
2. Property-based deterministic tests обязательны, включая heavy gate `1 000 000` прогонов.
3. Эталонная проверка (reference parity) обязательна в CI.
4. Perf ratchet: ухудшение критичных метрик более `5%` запрещено.
5. Canary rollout обязателен с divergence detection и feature-flag rollback.
6. При divergence/determinism mismatch обязан генерироваться `observability_gap.*` инцидент.

## 8. I18N
- UI default language: English.
- Runtime switch to Russian обязателен.
- Локализуются tooltip/status/error/empty states.
- Hardcoded user-facing strings запрещены вне i18n словарей.

## 9. Observability Gap Law
- Каждый этап 28..38 обязан определить минимум одно `observability_gap.*` событие.
- Для каждого события фиксируются:
  - `what`, `where`, `why`
  - `evidence_min`
  - `action_ref` (runbook)
- Событие включается в `docs/governance/observability_gap_registry.md` до закрытия этапа.

## 9.1 Risk Register Law
- Для программы 28..38 обязателен `docs/source/risk_register_v0_2.md`.
- Любой риск из реестра должен иметь: контрмеру, CI gate, `observability_gap.*`, release-blocker условие.
- Активный release-blocker запрещает rollout и продвижение этапа.

## 10. CI Gates v0.2
Обязательные job’ы:
- `stage28-docs-gate`
- `stage28-risk-gate`
- `stage29-dna-tests`
- `stage29-dna-assurance-gate`
- `stage29-dna-property-million`
- `stage30-evidence-claims-tests`
- `panel0-i18n-law-tests`
- `console-workspace-install`
- `console-lint`
- `console-test`
- `console-build`
- `workspace-boundary-check`
- `stage34-perf-load-tests`
- `coverage-ratchet-gate`
- `stage37-linux-hardening-gate`
- `stage38-ladder-gate`

Обязательные stage16 job’ы сохраняются:
- `panel0-e2e`
- `stage16-docs-gate`
- `stage16-runtime-gate`

## 11. Coverage policy
- Baseline покрытия фиксируется в репозитории.
- Любой новый код в `apps/console-web` и `packages/*` обязан иметь тесты.
- CI блокирует снижение baseline.
- Этапы 28..34 повышают покрытие до 100% по утверждённому плану.

## 12. Linux production law
- Текущая production-платформа: Linux.
- Readiness/e2e/perf smoke для этапов 16/28/29/30/37 выполняются в Linux headless.

## 13. Checklist Ladder Enforcement
- Источник статуса этапов: `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`.
- Если этап `N` не закрыт (`[ ]`), любой этап `N+1..` обязан быть `[ ]`.
- Нарушение блокируется CI job `stage38-ladder-gate`.

## 14. Process law (обязательный)
Пункт чек-листа закрывается только если:
1. Реализация завершена.
2. Выполнена воспроизводимая проверка.
3. Сформирован артефакт (лог/тест/скрин/вывод команды/файл).
4. Проставлен `[x]`.

Если проверка FAIL:
- пункт остаётся `[ ]`;
- фикс обязателен;
- повторная проверка обязательна.

## 14.1. Production-Adversarial Validation Law (обязательный)
- Art проектируется как система, которая должна выживать в агрессивной production-среде, где конфигурация, сеть, зависимости, входные данные, операторы и интеграции могут ломать систему одновременно.
- Для любого критичного изменения запрещён only-happy-path подход.
- Изменение считается завершённым только после доказанного эксплуатационного эффекта, подтверждённого разносторонним дебаггингом.
- Разносторонний дебаггинг обязателен по минимуму в четырёх измерениях:
  - основная гипотеза;
  - альтернативные причины;
  - negative-path;
  - regression containment.
- Формальный docs/file/grep gate не считается достаточным доказательством production-ready поведения.
- Для runtime/security/release/platform/agent/UI-law контуров обязателен минимум один adversarial или hostile-environment сценарий.
- Источники детализации:
  - `docs/testing/production_adversarial_validation_law.md`
  - `docs/testing/test_system_audit_v0_2.md`

## 14.2. Multi-layer Root-Cause Descent Law (обязательный)
- Art рассматривается как многоуровневая система; дефект на верхнем уровне может быть только симптомом более глубокого основания.
- Если недостаток найден на любом уровне (`UI`, `workflow`, `test`, `CI`, `contract`, `runtime`, `transport`, `storage`, `agent`, `core`, `policy`), перед исправлением обязателен спуск на уровень ниже.
- На нижнем уровне выполняется полный аудит связанного основания; если там найден следующий дефект, спуск продолжается ещё ниже.
- Исправление считается завершённым только после устранения корневой причины и повторной проверки затронутых верхних уровней.
- Запрещено:
  - чинить только симптом;
  - закрывать пункт по локальному улучшению на верхнем уровне;
  - не проверять, из какого нижнего контура дефект питается;
  - завершать remediation без доказательства, что нижний слой стабилен.
- Источники детализации:
  - `docs/testing/production_adversarial_validation_law.md`
  - `docs/testing/full_line_by_line_audit_program_v0_2.md`

## 15. Product Narrative (Console)
### 15.1 Категория
- Art Console является поверхностью Incident OS, а не набором независимых дашбордов.
- Любой вывод в UI должен быть проверяемым по evidence, audit и lineage.

### 15.2 Дифференциаторы
- Evidence-First рендеринг.
- Event DNA как первоклассный навигационный объект.
- Dialogic protocol вместо свободного невалидируемого чата.
- Investigations-as-Code с replay/compare.
- Verifyable audit через Merkle proof.
- Visual Flow Mode как проекция Reality Model (2D default, 3D как следующий слой).

## 16. Truth Modes Law (обязательный)
### 16.1 Режимы истины
- `Observed`: факт из Core/Agent/Panel0, всегда с ссылкой на первичные evidence.
- `Derived`: детерминированный вывод (кластеризация/агрегация/дифф), всегда с algorithm metadata.
- `Predicted`: прогноз/симуляция; не может отображаться как факт.

### 16.2 Контракт meta (единый)
- `meta.truth_mode: observed|derived|predicted`.
- `meta.evidence_refs: string[]` (mandatory для observed).
- `meta.derived: { algorithm_id, params }` (mandatory для derived).
- `meta.predicted: { assumptions[], confidence, dataset_ref?, data_window? }` (mandatory для predicted).

### 16.3 UI law
- UI обязан визуально различать truth mode (badge/legend/style token).
- Для `observed` отсутствие `meta.evidence_refs` является блокирующей ошибкой рендера.
- Для `predicted` обязателен явный маркер "prediction", запрещено подавать как established fact.

## 17. Canonical Domain Model (Console)
### 17.1 Канонические сущности
- `Event` (raw/normalized)
- `DNACluster`
- `EvidenceItem`
- `Claim`
- `ActionRequest` / `ActionResult`
- `AuditRecord` + `MerkleProof`
- `SLOViolation`
- `GapEvent`
- `InvestigationDoc`

### 17.2 Обязательные идентификаторы и поля
- `DNACluster`: `dna_id`, `size`, `first_seen`, `last_seen`, `time_range`, `navigation_tags`.
- `GapEvent`: `kind`, `component`, `incident_rule`, `action_ref`, `trace_id`.
- `EvidenceItem`: `oneOf(log|metric|trace|audit|snapshot|artifact)` + `source_ref`.
- `DialogMessage`: `message_id`, `parent_message_ids[]`, `evidence_refs[]`, `audit_refs[]`, `lineage_hash`.

## 18. Surfaces and Interaction Laws
### 18.1 Поверхности
- Command Center
- Event River
- Incident Room
- Scenario View
- Time Field
- Audit Explorer
- Action Studio
- Investigation Library
- Visual Flow Mode

### 18.2 Базовый пользовательский цикл
1. Пользователь открывает Command Center и получает состояние/риски/gap-сигналы.
2. Из Event River фильтрует по DNA/incident/severity/source и раскрывает evidence lineage.
3. В Incident Room проходит цикл Hypothesis -> Decision -> ActionRequest -> ActionResult -> Explanation.
4. В Investigation Library выполняет import/export/verify/replay InvestigationDoc.
5. В Flow Mode визуально исследует потоки, кластеры и связи; клик по объекту открывает Evidence Panel.

### 18.3 Interaction laws
- `Click-anything -> Inspect`: любой интерактивный объект имеет inspect-переход.
- `Tooltip everywhere`: все интерактивные элементы имеют tooltip key.
- `Freeze/Snapshot/Replay/Diff`: обязательные функции для воспроизводимости.
- `One-click-to-evidence`: gap/claim/decision/audit всегда раскрываются до первичных evidence.

## 19. Visual Flow Mode Specification
### 19.1 Границы
- Flow Mode не заменяет другие поверхности, а является проекцией на ту же Reality Model.
- Для v0.2 новые Core API запрещены; используются текущие контракты и локальный индекс.

### 19.2 Семантические типы
- `dna_cloud`, `incident_cloud`, `gap_cloud`
- `service_node`, `store_node`, `buffer_node`, `agent_node`
- `flow_edge` (направленный поток между узлами)

### 19.3 Truth Overlay
- Каждый node/cloud/edge имеет overlay mode: observed/derived/predicted.
- Цвет/контур/иконка определяются truth mode + severity + confidence.

### 19.4 3D концепция
- 3D-вид моделирует "воздушное пространство данных": направленные трассы потоков + информационные облака.
- Группировка облаков поддерживается по типам данных, объектам, инцидентам и DNA.
- 3D остаётся проекцией 2D модели и не является отдельным источником истины.

## 20. Adaptive UX Policy (обязательный)
- Default policy: `Auto by OS+GPU`.
- Пользовательские overrides обязательны:
  - theme: `auto|light|dark|high-contrast`
  - density: `compact|standard|expanded`
  - motion: `reduced|standard|enhanced`
  - flow complexity: `read-only|advanced`
- Advanced Control допускается только под feature-flag и SLO guardrail.
- При нарушении perf/stability budget включается auto-downgrade в read-only flow mode.

## 21. Spatial Store Law (Flow/2D/3D)
- Spatial Store является derivation layer и не хранит source-of-truth.
- Минимальный интерфейс v0.2:
  - `setPosition(node_id, vec)`
  - `getLayout(layout_id)`
  - `saveSnapshot(snapshot_id, state)`
  - `loadSnapshot(snapshot_id)`
  - `listSnapshots()`

## 22. Tiered Testing and CI Law
### 22.1 Обязательные проверки
- Truth Modes: observed без evidence_refs -> FAIL.
- Dialog lineage: сообщение без explainable lineage -> FAIL.
- Flow inspectability: клик по каждому semantic type раскрывает Evidence Panel.
- Freeze/Snapshot/Replay: state restore детерминирован.
- 2D perf baseline: 1000 nodes pan/zoom p95 <= 50 ms.
- i18n smoke: EN default и RU switch валидны для surfaces/tooltips/errors.

### 22.2 Обязательные CI jobs программы 28..38
- `stage30-truth-modes-tests`
- `stage31-investigation-library-tests`
- `stage35-flow-inspectability-tests`
- `stage35-flow-snapshot-replay-tests`
- `stage35-flow-perf-2d-gate`

## 23. Design System Law (Dark Gold Theme Tokens + UI Laws)
### 23.1 Статус
- Этот раздел является каноном design system для Console.
- Любые изменения токенов и law-правил выполняются только через правку этого раздела + повторный аудит контраста/читабельности/доступности.

### 23.2 Закон семантических токенов
- Компоненты состояний не имеют права использовать raw токены напрямую (`--color-gold-*`, `--color-warning` без суффикса).
- Обязательны семантические токены:
  - состояния: `--color-*-subtle`, `--color-*-strong`, `--color-on-*`
  - таблицы/списки: `--color-row-*`
  - фокус/оверлеи: `--color-focus-ring`, `--color-overlay-scrim`, `--shadow-elevated`
  - интерактив: `--color-link*`, `--color-btn-*`
- Raw gold (`--color-gold-*`) разрешён только для брендовых акцентов: selected/active, headline, primary CTA, выделенный DNA cluster/series.

### 23.3 Модель состояний: error vs danger
- `error`: ошибки данных/валидации/событий/интерфейса.
- `danger`: destructive действия (`delete|terminate|rollback|force`).
- Любая destructive action control обязана использовать `danger` токены.
- Ошибки валидации/парсинга/загрузки обязаны использовать `error` токены.

### 23.4 Interactive tokens (обязательно)
- `--color-link`, `--color-link-hover`
- `--color-btn-primary-bg`, `--color-btn-primary-bg-hover`, `--color-btn-primary-text`
- `--color-btn-secondary-bg`, `--color-btn-secondary-border`, `--color-btn-secondary-text`

### 23.5 Focus-visible и плотные списки
- `:focus-visible` обязателен: `2px` ring, `2px` offset, token `--color-focus-ring`.
- Hover не заменяет keyboard focus.
- Для dense lists/table rows:
  - selected: `--color-row-selected` + нецветовой маркер `--color-row-active-border`
  - hover не имеет права скрывать selected.

### 23.6 Charts и truth overlay
- Максимум одновременных серий графика: `6`.
- Набор серий фиксирован: `--color-series-1..6`; произвольные цвета запрещены.
- Gold используется только для selected series / target SLO / key investigation metric.
- Truth overlay не может быть реализован только цветом:
  - `Observed`: solid
  - `Derived`: dotted
  - `Predicted`: dashed + badge `PRED` + сниженная opacity

### 23.7 3D operational default
- По умолчанию 3D работает в operational режиме:
  - bloom/tуман/лишние cinematic effects отключены
  - чёткие контуры и читаемая типографика
- Cinematic mode допустим только отдельным toggle и вне активного расследования либо с явным warning.

### 23.8 i18n law для дизайн-контуров
- Default UI language: English.
- Russian обязателен как второй язык, включая tooltips/ошибки/статусы design controls.
- Запрещены hardcoded строки в компонентах.

### 23.9 Token Canon (CSS variables)
```css
/* =========================
   Base Surfaces
   ========================= */
--color-bg-primary: #0A0C0E;
--color-bg-secondary: #14181C;
--color-bg-tertiary: #1E2328;
--color-surface-elevated: #1F262C;

--color-overlay-scrim: rgba(0,0,0,0.6);
--shadow-elevated: 0 8px 20px rgba(0,0,0,0.5);

/* =========================
   Typography
   ========================= */
--color-text-primary: #E8E6E3;
--color-text-secondary: #9A9A9A;
--color-text-disabled: #5A5A5A;

/* =========================
   Borders
   ========================= */
--color-border-subtle: #2C3138;
--color-border-strong: #4A5058;

/* =========================
   Brand Gold (raw)
   ========================= */
--color-gold-primary: #C6A45C;
--color-gold-light: #D8B878;
--color-gold-dark: #B49450;
--color-gold-dim: #665C3A;
--color-gold-glow: rgba(198,164,92,0.6);

/* =========================
   States (semantic)
   ========================= */
--color-success-strong: #5B8C5A;
--color-success-subtle: rgba(91,140,90,0.15);

--color-error-strong: #B55A5A;
--color-error-subtle: rgba(181,90,90,0.15);

--color-danger-strong: #8E2A2A;
--color-danger-subtle: rgba(142,42,42,0.2);

--color-warning-strong: #D97C2B;
--color-warning-subtle: rgba(217,124,43,0.15);

--color-info-strong: #5A8CB5;
--color-info-subtle: rgba(90,140,181,0.15);

/* =========================
   "On" Colors (text on colored bg)
   ========================= */
--color-on-gold: #0A0C0E;
--color-on-success: #0A0C0E;
--color-on-warning: #0A0C0E;
--color-on-info: #0A0C0E;
--color-on-danger: #E8E6E3;

/* =========================
   Focus / Accessibility
   ========================= */
--color-focus-ring: #D8B878;

/* =========================
   Dense Lists / Tables
   ========================= */
--color-row-hover: rgba(198,164,92,0.08);
--color-row-selected: rgba(198,164,92,0.14);
--color-row-active-border: #D8B878;

/* =========================
   Charts: fixed series palette
   ========================= */
--color-series-1: #5A7C8C;
--color-series-2: #6A8C7A;
--color-series-3: #8C7A6A;
--color-series-4: #7A6A8C;
--color-series-5: #8C6A7A;
--color-series-6: #6A8C8C;

/* =========================
   Interactions (semantic)
   ========================= */
--color-link: #D8B878;
--color-link-hover: #C6A45C;

--color-btn-primary-bg: #C6A45C;
--color-btn-primary-bg-hover: #D8B878;
--color-btn-primary-text: #0A0C0E;

--color-btn-secondary-bg: transparent;
--color-btn-secondary-border: #4A5058;
--color-btn-secondary-text: #E8E6E3;

/* =========================
   3D-specific (operational default)
   ========================= */
--color-3d-bg-start: #030405;
--color-3d-bg-end: #0A0C0E;
--color-3d-node: rgba(198,164,92,0.7);
--color-3d-edge: rgba(198,164,92,0.3);
--color-3d-cloud: rgba(102,92,58,0.15);
```

### 23.10 Audio Effects Ownership Law
- Аудио-эффекты по умолчанию обязаны генерироваться процедурно (WebAudio synthesis) и не должны зависеть от внешних аудиофайлов.
- В baseline запрещено включать сторонние мелодии/сэмплы, если не доказана чистота лицензии.
- Для каждого эффекта UI обязан поддерживать replace/preview/clear через пользовательский файл.
- При пользовательской загрузке система обязана явно предупреждать о необходимости прав на контент.
- Каскадные системные эффекты должны быть мелодическими и нейтральными для длительной операционной работы.

## 24. Settings Information Architecture Law
- Структура настроек Console должна быть единой иерархией с уровнями scope: `Global -> Organization -> Project -> Environment -> User`.
- Любая настройка обязана иметь `id`, `scope`, `default`, `owner_component`, `verify`.
- Поиск по настройкам обязателен; фильтрация работает по `label/tags/id`.
- Policy-locked настройки отображаются как read-only с указанием источника lock.
- Settings Profile Manager обязателен: `save/apply/delete/export/import` для user-scope snapshot.
- Каноническая карта меню и stage mapping фиксируются в `docs/source/console_settings_architecture_v0_2.md`.

# APPENDIX A — LENS CATALOG (обязательный аудит полноты)

## Цель
Этот раздел фиксирует обязательные линзы анализа, которыми Codex обязан пользоваться для аудита полноты.
Линзы используются для поиска пробелов в архитектуре, контрактах, тестах, безопасности, эксплуатации и roadmap.

## A0) Process Law для Lens Audit (жёстко)
Мы всегда работаем основательно.
Никаких "быстро накидать", никаких пропусков и послаблений.
Порядок исполнения неизменен: реализация -> проверка -> только потом [x] -> следующий пункт.

Для каждой линзы обязателен цикл:
1. Inventory: перечислить существующие артефакты (файлы/контракты/тесты/скрипты/гейты).
2. Gap list: перечислить недостающее в форме "нет X".
3. Closure mapping: сопоставить каждый gap конкретному пункту MASTER (или добавить пункт).
4. Implement & Verify: реализовать и выполнить проверку с артефактом.
5. Закрыть [x] только после PASS-проверки.

Запрещено:
- отмечать как "частично закрыто";
- переходить к следующему этапу с незакрытым блокирующим gap;
- менять критерии качества/безопасности ради ускорения.

### A0.0 Classification rule
Каждая линза классифицируется как Primary, Secondary или Anti-pattern.

- Primary: обязательные линзы для проекта; должны иметь полный набор артефактов и проверок.
- Secondary: применяются точечно, если дают пользу без нарушения конституции.
- Anti-pattern: используются только как красные флаги; следование им запрещено.

### A0.1 Primary / Secondary / Anti-pattern mapping
#### Primary (обязательные)
- Evidence/Assurance-driven (Evidence-first)
- Risk-driven
- Constraint-driven (perf/security/offline)
- Contract-first + Policy-first (Policy-as-UI)
- Architecture-first
- Operations/SRE-driven
- Quality-first (gates + real load tests)
- Security-first / Zero-trust
- Privacy-by-Design
- Supply-chain security
- Platform/Composable (слойность/модульность)
- Human-centered (tooltips everywhere, one-click-to-evidence)
- Data/Index-first (локальный индекс обязателен)
- Streaming-first + Backpressure-first
- Audit-first (Merkle verify + immutable audit)

#### Secondary (по месту, без ослабления требований)
- Scientific / Hypothesis-driven (R&D задачи: 3D/XR, новые UX-примитивы)
- Model-driven (схемы/протоколы/форматы)
- Formal/Correctness-driven (точечно: крипто-аудит, критические протоколы)
- Economics-driven (SaaS/стоимость/лимиты без компромиссов по безопасности)
- Stage-Gate (governance-ворота без искусственного торможения развития)

#### Anti-pattern (запрещено как стиль работы)
- Code-and-Fix / Big-bang
- RAD в трактовке "ускорить за счёт упрощений" (запрещено)
- Любой AI-first без evidence

## A1) Метаподходы (уровень принятия решений)
- [Primary] Evidence/Assurance-driven (Evidence-first)
- [Primary] Risk-driven
- [Primary] Constraint-driven
- [Primary] Operations/SRE-driven
- [Primary] Security-first / Zero-trust
- [Primary] Quality-first
- [Primary] Human-centered
- [Primary] Platform/Composable
- [Secondary] Scientific / Hypothesis-driven
- [Secondary] Model-driven
- [Secondary] Formal/Correctness-driven
- [Secondary] Economics-driven

## A2) SDLC-модели (семейства жизненного цикла)
- [Primary] Iterative-Incremental
- [Primary] CI-driven
- [Primary] CD/Continuous Delivery-driven (с обязательными gates)
- [Secondary] Stage-Gate (governance)
- [Secondary] R&D / Hypothesis-driven delivery
- [Secondary] Prototyping (throwaway/evolutionary) для изолированного R&D
- [Secondary] Timeboxing (без снижения требований качества/безопасности)
- [Anti-pattern] Code-and-Fix (ANTI-PATTERN)
- [Anti-pattern] Big-bang delivery (ANTI-PATTERN)

## A3) Подходы к требованиям и проектированию
- [Primary] Requirements-driven + traceability
- [Primary] Contract-first (OpenAPI/JSON Schema-first)
- [Primary] API-first
- [Primary] Data-first / Event-first
- [Primary] Policy-first (PII/RBAC/redaction)
- [Primary] Architecture-first
- [Secondary] Use-case / Scenario-driven
- [Secondary] Domain-driven
- [Secondary] UX-first / JTBD

## A4) Архитектурные подходы
- [Primary] Layered architecture
- [Primary] Component-based
- [Primary] Event-driven architecture
- [Primary] Plugin-based / Extensible platform
- [Primary] Renderer-agnostic / Projection-based UI (2D/3D/XR)
- [Primary] Offline-first / PWA-first
- [Primary] Single source of truth (Core truth + derived local stores)
- [Secondary] Hexagonal / Ports-and-Adapters
- [Secondary] Clean architecture
- [Secondary] CQRS / Event sourcing (если оправдано моделями данных)
- [Secondary] Edge-first / Hybrid edge-cloud (если появится edge deployment)

## A5) Подходы к качеству, тестированию и валидации
- [Primary] Verification-driven (контракты/инварианты)
- [Primary] Contract testing
- [Primary] End-to-End driven
- [Primary] Performance-driven / Perf budgets
- [Primary] Reliability testing (soak/chaos/stress)
- [Primary] Security testing (SAST/DAST/SCA)
- [Primary] Regression gating (CI блокирует регресс)
- [Secondary] Validation-driven (ценность/UX)
- [Secondary] Test-driven (TDD-class)
- [Secondary] Property-based testing (обязателен для критических алгоритмов)

## A6) Безопасность / приватность / аудит
- [Primary] Security-by-Design
- [Primary] Privacy-by-Design
- [Primary] Zero-Trust
- [Primary] Least privilege (RBAC/ABAC)
- [Primary] Audit-first / Evidence retention
- [Primary] Supply-chain security (SBOM, подписи, pinning)
- [Primary] Threat-model-driven
- [Primary] Compliance-driven

## A7) Надёжность / эксплуатация / масштабирование
- [Primary] SRE-driven (SLO/SLI, error budget)
- [Primary] Graceful degradation
- [Primary] Resilience engineering
- [Primary] Observability-first
- [Primary] Backpressure-first
- [Primary] Runbook-driven ops
- [Primary] Disaster recovery-driven
- [Primary] Multi-tenancy-driven (SaaS)
- [Secondary] Capacity planning-driven
- [Secondary] Cost-aware scaling

## A8) Данные / индексы / аналитика
- [Primary] Data-lifecycle-driven (ingest -> normalize -> store -> index -> query -> retention)
- [Primary] Index-first (локальный индекс обязателен)
- [Primary] Cache-first / Offline-read
- [Primary] Streaming-first (SSE, cursor, batching, backpressure)
- [Primary] Vector/Spatial-store-driven (3D координаты, LOD, picking)
- [Primary] Evidence lineage (происхождение данных и цепочки)

## A9) AI/автоматизация
- [Primary] Evidence-anchored AI (единственная допустимая базовая модель AI в проекте)
- [Primary] AI не имеет права генерировать claims без evidence_refs.
- [Primary] Human-in-the-loop (критичные решения фиксируются как Decision + audit)
- [Primary] Policy-guarded actions (preflight/RBAC/audit)
- [Secondary] Agent-orchestration-driven (задачи/артефакты агента)
- [Secondary] Local inference / privacy-preserving (если применяется, без нарушения Policy-first)
- [Anti-pattern] Любой AI-first без evidence (запрещено)

## A10) Формат отчёта Lens Audit (обязательный артефакт)
Файл отчёта: `docs/foundation/lens_audit_report.md`.

Для каждой линзы обязателен блок со структурой:
- Class: Primary / Secondary / Anti-pattern
- Existing coverage
- Gaps
- Fix plan
- Verification
- Checklist mapping
- Status: [ ] / [x]

Правила блокировки:
- Primary: отсутствие артефактов = блокирующий gap до полного закрытия.
- Secondary: gap фиксируется только если мы решили использовать линзу в текущем scope.
- Anti-pattern: фиксируются только признаки/риски как предупреждения, без плана внедрения.
