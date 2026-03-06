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
