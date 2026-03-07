# Дефектовочная контрольная ведомость remediation v0.2

## Source of truth
- `docs/testing/full_line_by_line_audit_program_v0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/stage_reopening_matrix_v0_2.md`
- `docs/testing/defect_remediation_ladder_v0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `formats/defect_remediation_control_matrix_v0_2.yaml`

## Назначение
Этот документ превращает результаты полного аудита в поштучный управляемый контур исполнения.

Если `full_line_by_line_audit_registry_v0_2.md` отвечает на вопрос:
- что сломано;
- где сломано;
- почему stage должен быть reopened,

то эта контрольная ведомость отвечает на вопрос:
- какой конкретный дефект сейчас в работе;
- какие стадии и какие checklist-листы он блокирует;
- что именно нужно сделать;
- какими тестами и артефактами доказать закрытие;
- когда defect можно перевести в `[x]`.

Для документов и документационных контуров эта ведомость теперь обязана смотреть ещё и на
`docs/portal/DOCUMENTATION_TREE.md`: если изменение затрагивает корневой или зависимый документ,
дерево документации используется как быстрый контроль, что связь с `README.md`, количество строк
и путь влияния на другие документы пересчитаны и не устарели.

## Жёсткое правило управления
После завершения полного аудита remediation запрещено вести только по stage-номерам или только по дефектовочной лестнице.

Обязательная цепочка управления теперь такая:

`Корень -> Аудит -> Stage reopening matrix -> Дефектовочная контрольная ведомость -> Дефектовочная лестница -> MASTER -> Stage checklist`

Это означает:
- ни один найденный дефект не имеет права потеряться между аудитом и исполнением;
- ни одна стадия не имеет права быть повторно закрыта, пока не закрыты все её активные defect-строки в этой ведомости;
- если одна строка дефекта влияет на несколько stage-листов, контроль ведётся через одну строку дефекта, а не разрозненно по разным документам.
- если defect затрагивает документный контур, его закрытие запрещено без синхронного обновления
  `DOCUMENTATION_TREE.md` и соответствующего machine-readable снимка дерева.

## Правила статусов
- `[ ]` — дефект не устранён полностью.
- `[x]` — дефект устранён полностью, эффект доказан разносторонним дебаггингом, все связанные stage-листы можно двигать дальше.

Запрещено:
- переводить строку дефекта в `[x]` по одному зелёному тесту;
- закрывать строку дефекта только на основании документации;
- закрывать stage в `MASTER`, если на него ссылается хотя бы одна строка `[ ]`.

## Сводная таблица

| ID | Статус | Уровень лестницы | Зависит от | Блокирует stages | Смысл дефекта |
|---|---|---|---|---|---|
| `DEF-001` | `[ ]` | `A.1` | — | `11, 23, 37` | Неполный durable storage/recovery basement `Core` |
| `DEF-002` | `[ ]` | `A.2` | `DEF-001` | `17, 23, 37` | `Agent spool` остаётся in-memory и не переживает restart |
| `DEF-003` | `[ ]` | `A.3` | `DEF-002` | `18, 23, 37` | Нет реального transport/relay/TLS/bootstrap в `Agent` |
| `DEF-004` | `[ ]` | `A.4` | `DEF-003` | `19, 37` | Pack runtime принимает placeholder payload как валидный baseline |
| `DEF-005` | `[ ]` | `A.5` | `DEF-004` | `05, 06, 20, 37` | REGART runtime/integration contour отстаёт от утверждённой модели |
| `DEF-006` | `[ ]` | `A.6` | `DEF-005` | `24, 37, 38` | Platform/VM/container/K8s truth слабее заявленной readiness |
| `DEF-007` | `[ ]` | `B.1` | `DEF-006` | `01, 04, 07, 24, 38` | Governance/release/security corpus слабее hostile standard |
| `DEF-008` | `[ ]` | `B.2` | `DEF-007` | `02, 18, 25, 26, 30` | Privacy baseline сам себе противоречит |
| `DEF-009` | `[ ]` | `B.3` | `DEF-008` | `03, 25, 26, 37` | Regional/compliance profiles не удерживают consistency |
| `DEF-010` | `[ ]` | `B.4` | `DEF-009` | `25, 26, 37, 38` | Compliance/audit-ready evidence contour декларативнее runtime truth |
| `DEF-011` | `[ ]` | `C.1` | `DEF-010` | `10, 16, 28, 37, 40` | Browser/Panel0 fallback и bilingual truth расходятся с заявлением |
| `DEF-012` | `[ ]` | `C.2` | `DEF-011` | `28, 30, 31, 33, 40` | Console/i18n/agent interaction contour недоматериализован |
| `DEF-013` | `[ ]` | `C.3` | `DEF-012` | `28, 34, 35, 41` | `local-stores`/`worker-runtime`/spatial basement всё ещё слаб |
| `DEF-019` | `[ ]` | `D.1` | `DEF-013` | `15, 24, 33, 37` | Trust boundary и canonical actor context не материализованы как hostile production baseline |
| `DEF-020` | `[ ]` | `D.2` | `DEF-019` | `10, 16, 24, 28, 37, 40` | Browser surface hardening не закреплён как обязательный security baseline для runtime и showcase |
| `DEF-014` | `[ ]` | `D.3` | `DEF-020` | `04, 07, 08, 24, 38` | Contracts/CI/release/gates ещё дают false-green и weak proof |
| `DEF-015` | `[ ]` | `D.4` | `DEF-014` | `12, 24, 36, 37, 45` | Нет полноценного ingress/perimeter anti-DDoS контура для hostile production среды |
| `DEF-023` | `[ ]` | `D.5` | `DEF-015` | `11, 12, 24, 37` | Нет полного runtime-контура защиты от storage pressure и disk exhaustion |
| `DEF-024` | `[ ]` | `D.6` | `DEF-023` | `12, 18, 24, 37` | Нет fail-closed проверки опасной конфигурации при старте Core/Agent и edge-контуров |
| `DEF-025` | `[ ]` | `D.7` | `DEF-024` | `12, 17, 18, 24, 37` | Нет полного anti-loop / duplicate / queue integrity baseline для event-потоков и backlog |
| `DEF-026` | `[ ]` | `D.8` | `DEF-025` | `24, 37, 38` | Защитные guard-контуры не обязаны иметь self-test, heartbeat и failure visibility |
| `DEF-027` | `[ ]` | `D.9` | `DEF-019` | `15, 24, 33, 37, 43` | Нет semantic safety barrier, который не даёт destructive action пройти по формально валидному пути |
| `DEF-028` | `[ ]` | `D.10` | `DEF-003` | `18, 23, 37` | Нет materialized доверия к `agent identity`, enrollment и relay-chain |
| `DEF-029` | `[ ]` | `D.11` | `DEF-014` | `04, 07, 24, 38` | Релизный контур ещё может давать stale или завышенные claims относительно реального состояния |
| `DEF-031` | `[ ]` | `D.12` | `DEF-010` | `25, 26, 37, 38` | Нет отдельного protective-контура против regulatory/certified overclaim и drift |
| `DEF-034` | `[ ]` | `D.13` | `DEF-029` | `07, 24, 28, 38` | Нет first-class контроля документационного drift между корнем, стволом и кроной |
| `DEF-016` | `[ ]` | `E.1` | `DEF-034` | `29..45` | Утверждённые differentiators ещё не materialize в runtime/contracts/tests |
| `DEF-017` | `[ ]` | `E.2` | `DEF-016` | `10, 11, 17, 18, 28, 35, 37, 39` | Высокорисковые монолитные entrypoint-файлы затрудняют review, hardening и смену владельца |
| `DEF-018` | `[ ]` | `E.3` | `DEF-017` | `10, 16, 22, 24, 28, 34, 36, 38` | Сила test-corpus неравномерна: console/browser и часть release-path ещё слабее hostile production стандарта |
| `DEF-021` | `[ ]` | `E.4` | `DEF-018` | `05, 06, 20, 24, 38` | Нет pinned external adversarial harness для REGART-интеграции и partner-exposed hostile proof |
| `DEF-022` | `[ ]` | `E.5` | `DEF-021` | `18, 19, 20, 28` | Подключённые внешние системы не materialize как наглядные сущности с declared-vs-observed coverage |
| `DEF-030` | `[ ]` | `E.6` | `DEF-021` | `04, 07, 19, 20, 28, 37, 40` | Нет end-to-end authenticity baseline, защищающего проект от спорных ассетов и источников |
| `DEF-032` | `[ ]` | `E.7` | `DEF-017` | `10, 11, 17, 18, 28, 35, 37, 39` | Нет materialized budget-guard, который заставляет раскалывать опасные монолиты вовремя |
| `DEF-033` | `[ ]` | `E.8` | `DEF-018` | `10, 16, 22, 24, 28, 34, 36, 38` | Нет отдельного guard-а, который блокирует closure на слабом hostile/integration proof |

## Контрольные строки

### [ ] DEF-001 — Durable storage и recovery basement `Core`
- Уровень: `A.1`
- Зависит от: —
- Затронутые stage-листы:
  - `CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md`
  - `CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `core/src/main.rs`
  - `docs/core/storage.md`
  - `docs/governance/evidence/stage11_core_sqlite_restart.log`
  - `docs/governance/evidence/stage11_core_sqlite_hostile_recovery.log`
  - `docs/governance/evidence/stage11_core_backup_scope_isolation.log`
  - `docs/governance/evidence/stage11_step2_backup_policy.log`
  - `docs/governance/evidence/stage11_step3_concurrency.log`
- Что нужно сделать:
  1. довести durable persistence не только для `events/incidents/audit`, но и для derived/runtime state;
  2. материализовать recovery contour для fingerprint/source indexes, `dna/evidence` и аналитики;
  3. доказать hostile-path recovery (`WAL/corruption/read_only`) уже на расширенном полном состоянии;
  4. убрать расхождение между storage docs и реальным recovery path.
- Чем доказать закрытие:
  - restart-proof tests на полный `Core state`;
  - evidence logs по recovery после restart/corruption;
  - hostile-path проверки `WAL/corruption/recovery`.
- Текущий прогресс:
  - partial remediation уже сделана коммитами `cf25815`, `444e587`;
  - следующим слоем durable basement расширен и на `fingerprint/source indexes`, `dna_clusters`, `evidence_blocks`, `analytics/counters`;
  - hostile backup/restore recovery для полного `Core state` теперь доказан отдельным evidence и runtime test;
  - коллизия backup-root между экземплярами `Core` с одинаковым профилем устранена: backup-каталог теперь детерминированно зависит и от `db_path`, а не только от `effective_profile_id`;
  - live `art-core` уже материализует автоматический corruption-handling contour (`503/retry_after_ms`, `storage_corrupted`, restore, `read_only`) end-to-end;
  - backup policy больше не расходится с runtime: cadence `15 минут` enforced внутри `Core`, а не только описан в docs;
  - отдельный evidence `stage11_step2_backup_policy.log` фиксирует cadence-test, полный `art-core`, Python storage-suite и весь стволовой guard-chain для шага `11.2`;
  - live-process contour `kill -9 Core во время ingest` теперь материализован отдельным runtime smoke `scripts/tests/storage_kill9_runtime.sh` и evidence `stage11_kill9_runtime.log`;
  - ранний `storage pressure` contour теперь тоже materialized: `high/critical watermarks`, `reserve free space`, write-shed на `high`, жёсткий `503 + retry_after_ms` на `critical`, recovery после возврата свободного места и live evidence `stage11_storage_pressure_runtime.log`;
  - для `stage11` blocker `storage pressure / disk exhaustion` уже снят: фактический `disk full` hostile proof и archive/prune discipline доказаны live runtime smoke;
  - stage-level concurrency proof `11.3` теперь тоже закрыт отдельным runtime-evidence: `8 writer / 4 reader / 10000 ops / 26.061s`, без fatal `database is locked`, с инвариантом `accepted=committed=db_count`, а `storage-integration` запускает этот contour напрямую;
  - сам `DEF-001` остаётся открыт, потому что следующий локальный blocker `stage11` теперь уже один: production-proof для `VACUUM/systemd` (`11.4`).

### [ ] DEF-002 — Durable spool у `Agent`
- Уровень: `A.2`
- Зависит от: `DEF-001`
- Затронутые stage-листы:
  - `CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md`
  - `CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `agent/src/main.rs`
  - `docs/testing/full_line_by_line_audit_registry_v0_2.md`
  - `docs/runbooks/*spool*.md`
- Что нужно сделать:
  1. заменить in-memory spool на durable spool/outbox;
  2. обеспечить restart-safe backlog recovery;
  3. синхронизировать runtime, runbooks и chaos corpus.
- Чем доказать закрытие:
  - restart chaos;
  - disk-full/corruption tests;
  - evidence backlog replay без silent loss.

### [ ] DEF-003 — Outbound transport / relay / TLS / bootstrap у `Agent`
- Уровень: `A.3`
- Зависит от: `DEF-002`
- Затронутые stage-листы:
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `agent/src/main.rs`
  - `docs/source/agent_deployment_transport_v0_2.md`
  - `docs/ops/agent_multisite_deploy.md`
- Что нужно сделать:
  1. materialize outbound delivery to `Core/relay`;
  2. ввести bootstrap/enrolment path и transport auth;
  3. добавить TLS/mTLS/segment-aware routing;
  4. расширить receiver contour до утверждённого набора.
- Чем доказать закрытие:
  - runtime smoke `Agent -> Core` и `Agent -> Relay -> Core`;
  - negative-path tests NAT/WAN/segment loss;
  - evidence backlog replay after reconnect.

### [ ] DEF-004 — Pack framework не должен принимать placeholder payload
- Уровень: `A.4`
- Зависит от: `DEF-003`
- Затронутые stage-листы:
  - `CHECKLIST_19_PACKS_FRAMEWORK.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `scripts/tests/pack_install_runtime.sh`
  - `scripts/tests/packs_runtime.py`
  - `packs/*`
- Что нужно сделать:
  1. валидировать payload semantics, а не только наличие каталога;
  2. добавить authenticity/runtime checks для pack contents;
  3. исключить placeholder payload из install-success path.
- Чем доказать закрытие:
  - negative install tests;
  - authenticity gate;
  - runtime pack activation proof.

### [ ] DEF-005 — REGART runtime/integration contour
- Уровень: `A.5`
- Зависит от: `DEF-004`
- Затронутые stage-листы:
  - `CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
  - `CHECKLIST_06_REGART_ART_BRIDGE.md`
  - `CHECKLIST_20_PACK_REGART.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `packs/regart/manifest.yaml`
  - `packs/regart/examples/receivers.toml`
  - `scripts/ci/check_stage06_wrapper.sh`
  - `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Что нужно сделать:
  1. выровнять pack/runtime bridge с approved external-source coverage;
  2. убрать зависимость truth-path от sibling checkout/local HTTP dev contour;
  3. связать REGART parity с runtime proof, а не только с wrapper/docs.
- Чем доказать закрытие:
  - cross-repo parity на pinned source;
  - runtime Art↔REGART smoke with evidence;
  - negative-path bridge tests.

### [ ] DEF-006 — Platform/VM/runtime truth
- Уровень: `A.6`
- Зависит от: `DEF-005`
- Затронутые stage-листы:
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `tests/platform/vm/run_vm_smoke.sh`
  - `docs/ops/platform-vm-testing.md`
  - `tests/platform/container/*`
  - `tests/platform/k8s/*`
- Что нужно сделать:
  1. убрать placeholder execute path у VM;
  2. довести integrated `Agent -> Core` proof для Docker/K8s;
  3. выровнять platform docs и real runtime evidence.
- Чем доказать закрытие:
  - real VM execute evidence;
  - integrated container/K8s runtime proof;
  - updated delivery evidence and stage37 gate.

### [ ] DEF-007 — Governance/release/security corpus слабее hostile standard
- Уровень: `B.1`
- Зависит от: `DEF-006`
- Затронутые stage-листы:
  - `CHECKLIST_01_GOVERNANCE_SRE.md`
  - `CHECKLIST_04 _Secure SDLC + Supply-chain.md`
  - `CHECKLIST_07_ART_REPO_CI_DOCS.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `.github/CODEOWNERS`
  - `.github/pull_request_template.md`
  - `SECURITY.md`
  - `docs/governance/release_process.md`
- Что нужно сделать:
  1. довести governance/release/security docs до hostile-production standard;
  2. materialize stronger review/adversarial evidence rules;
  3. исключить stale release/go-no-go and thin policy surfaces.
- Чем доказать закрытие:
  - updated policies;
  - hostile governance/release tests;
  - buyer-grade release evidence.

### [ ] DEF-008 — Privacy baseline self-consistency
- Уровень: `B.2`
- Зависит от: `DEF-007`
- Затронутые stage-листы:
  - `CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_25_COMPLIANCE_AUDIT_READY.md`
  - `CHECKLIST_26_RU_PROFILE.md`
  - `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- Audit basis:
  - `docs/privacy/redaction_policy.md`
  - `docs/privacy/pii_surface.md`
  - `docs/privacy/retention_matrix.md`
- Что нужно сделать:
  1. завести отсутствующий `config/privacy/redaction_rules.yaml` или убрать ложную зависимость;
  2. устранить логические ошибки `PII surface`/redaction mapping;
  3. синхронизировать privacy runtime expectations с actual transport/storage.
- Чем доказать закрытие:
  - privacy gate;
  - negative tests на redaction/profile/export;
  - machine-readable rule validation.

### [ ] DEF-009 — Regional/compliance profiles consistency
- Уровень: `B.3`
- Зависит от: `DEF-008`
- Затронутые stage-листы:
  - `CHECKLIST_03_REGIONAL_PROFILES.md`
  - `CHECKLIST_25_COMPLIANCE_AUDIT_READY.md`
  - `CHECKLIST_26_RU_PROFILE.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `docs/compliance/profiles.md`
  - `docs/privacy/retention_matrix.md`
  - `docs/privacy/regional_profiles.md`
- Что нужно сделать:
  1. устранить retention/profile drift;
  2. выровнять airgapped/default profile semantics;
  3. добиться machine-readable and docs parity.
- Чем доказать закрытие:
  - stage03 gate + cross-doc drift tests;
  - RU/compliance integration tests.

### [ ] DEF-010 — Compliance/audit-ready evidence contour
- Уровень: `B.4`
- Зависит от: `DEF-009`
- Затронутые stage-листы:
  - `CHECKLIST_25_COMPLIANCE_AUDIT_READY.md`
  - `CHECKLIST_26_RU_PROFILE.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/compliance/control_matrix.md`
  - `docs/compliance/evidence_list.md`
  - `docs/ops/operational_debt_register.md`
- Что нужно сделать:
  1. убрать несуществующие evidence paths и placeholder debt;
  2. сделать audit-ready corpus реальным, а не декларативным;
  3. выровнять compliance evidence с release/runtime reality.
- Чем доказать закрытие:
  - real evidence paths;
  - compliance export/destroy tests;
  - updated debt register without template placeholders.

### [ ] DEF-011 — Browser/Panel0/fallback/bilingual truth
- Уровень: `C.1`
- Зависит от: `DEF-010`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`
- Audit basis:
  - `browser/scripts/build.mjs`
  - `browser/src/outbox.js`
  - `browser/src/panel0.js`
  - `docs/ui/panel0.md`
- Что нужно сделать:
  1. убрать false-green browser build/smoke;
  2. materialize durable browser outbox/fallback truth;
  3. довести RU/bilingual parity для Panel0/runtime shell.
- Чем доказать закрытие:
  - real browser build + e2e;
  - offline/fallback negative-path proof;
  - bilingual screenshots/evidence without EN leaks.

### [ ] DEF-012 — Console/i18n/agent interaction contour
- Уровень: `C.2`
- Зависит от: `DEF-011`
- Затронутые stage-листы:
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
  - `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
  - `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
  - `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`
- Audit basis:
  - `apps/console-web/src/main.ts`
  - `apps/console-web/scripts/generate-static.mjs`
  - `packages/i18n/src/index.ts`
- Что нужно сделать:
  1. убрать hardcoded/mixed-locale strings;
  2. довести двуязычие и static build parity;
  3. materialize missing agent-interaction/source-of-truth docs and runtime hooks.
- Чем доказать закрытие:
  - full RU/EN shell checks;
  - static build parity;
  - console e2e around agent interaction states.

### [ ] DEF-013 — `local-stores` / `worker-runtime` / spatial basement
- Уровень: `C.3`
- Зависит от: `DEF-012`
- Затронутые stage-листы:
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
  - `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`
  - `CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md`
- Audit basis:
  - `packages/local-stores/src/index.ts`
  - `packages/worker-runtime/src/index.ts`
  - `packages/ui-laws/src/index.ts`
- Что нужно сделать:
  1. убрать `stubbed` spatial/runtime path;
  2. ввести настоящую durable local persistence там, где обещана;
  3. довести UI laws beyond runtime-only enforcement.
- Чем доказать закрытие:
  - persistence tests;
  - spatial readiness tests without stubs;
  - AST/static law enforcement proof.

### [ ] DEF-019 — Trust boundary and canonical actor context hardening
- Уровень: `D.1`
- Зависит от: `DEF-013`
- Затронутые stage-листы:
  - `CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `core/src/main.rs`
  - `docs/source/trust_boundary_hardening_v0_2.md`
  - `docs/portal/SECURITY_POSTURE.md`
  - `docs/governance/observability_gap_registry.md`
- Что нужно сделать:
  1. запретить использовать недоверенные входящие заголовки как источник `actor_role`, `mcp_mode`, `access_scope` и `trusted_client_ip`;
  2. materialize trusted actor-context baseline для security-sensitive путей;
  3. ввести fail-closed negative path для spoofed headers и недоказанной trust boundary;
  4. сделать release/runtime profiles честно зависимыми от trust-boundary proof.
- Чем доказать закрытие:
  - spoofed-header negative tests;
  - trusted source matrix;
  - `observability_gap.trust_boundary_violation`;
  - release blocker evidence для internet-exposed / partner-exposed профилей.

### [ ] DEF-020 — Browser surface hardening baseline
- Уровень: `D.2`
- Зависит от: `DEF-019`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`
- Audit basis:
  - `docs/source/browser_surface_hardening_v0_2.md`
  - `browser/*`
  - `apps/console-web/*`
  - `docs/portal/SECURITY_POSTURE.md`
- Что нужно сделать:
  1. materialize CSP/frame/header/integrity baseline для browser surface;
  2. запретить ослабление browser security ради showcase/demo;
  3. сделать policy degradation наблюдаемой и testable;
  4. связать release profiles с browser hardening proof.
- Чем доказать закрытие:
  - browser policy negative tests;
  - release evidence для internet-exposed browser surface;
  - `observability_gap.browser_surface_policy_degraded`;
  - safe fallback presentation proof.

### [ ] DEF-014 — Contracts / CI / release / gates truth
- Уровень: `D.3`
- Зависит от: `DEF-020`
- Затронутые stage-листы:
  - `CHECKLIST_04 _Secure SDLC + Supply-chain.md`
  - `CHECKLIST_07_ART_REPO_CI_DOCS.md`
  - `CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/contracts/*`
  - `scripts/ci/check_*`
  - `generated/*`
  - release docs/evidence corpus
- Что нужно сделать:
  1. убрать false-green structural gates;
  2. сделать contracts/generated surface stricter and complete;
  3. довести release/provenance/go-no-go to current HEAD truth.
- Чем доказать закрытие:
  - behavioural CI gates;
  - contract/codegen parity checks;
  - release evidence current and non-stale.

### [ ] DEF-015 — Ingress / perimeter anti-DDoS contour
- Уровень: `D.4`
- Зависит от: `DEF-014`
- Затронутые stage-листы:
  - `CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md`
- Audit basis:
  - `core/src/main.rs`
  - `docs/source/ingress_perimeter_protection_v0_2.md`
  - `docs/portal/SECURITY_POSTURE.md`
  - `docs/governance/observability_gap_registry.md`
- Что нужно сделать:
  1. отделить app-level backpressure от полноценной DDoS/perimeter защиты;
  2. materialize release/runtime policy для internet-exposed ingress;
  3. ввести `ddos_suspected` и `ingress_shield_degraded` как обязательные gap-события;
  4. довести SaaS и Linux production profiles до per-tenant/per-source ingress abuse isolation;
  5. доказать hostile ingress path тестами и release blockers.
- Чем доказать закрытие:
  - hostile ingress tests;
  - release blocker evidence;
  - runbooks и registry entries;
  - runtime perimeter proof for internet-exposed profile.

### [ ] DEF-023 — Storage pressure / disk exhaustion protection
- Уровень: `D.5`
- Зависит от: `DEF-015`
- Затронутые stage-листы:
  - `CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md`
  - `CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `docs/source/storage_pressure_protection_v0_2.md`
  - `docs/core/storage.md`
  - `docs/ops/storage.md`
  - `docs/governance/observability_gap_registry.md`
- Что нужно сделать:
  1. удержать уже materialized `high watermark`, `critical watermark` и `reserve free space` как release-grade baseline на уровнях `12/24/37`;
  2. сохранить `observability_gap.storage_pressure_high` и `observability_gap.storage_disk_full` разными стадиями деградации в ingest/release/Linux profiles;
  3. протащить archive/prune discipline и reserve-space policy в release blockers и platform hardening, а не только в `stage11`;
  4. запретить release claim про durable storage, пока hostile disk-exhaustion proof не закреплён в `stage24/37` как production evidence.
- Чем доказать закрытие:
  - hostile disk-pressure tests;
  - runtime evidence по `storage_pressure_high` и `storage_disk_full`;
  - release blocker evidence;
  - recovery logs и proof сохранения reserve free space.
- Текущий прогресс:
  - `stage11`-часть дефекта уже materialized и подтверждена:
    - `observability_gap.storage_pressure_high`
    - `high -> heavy write shed`
    - `critical -> write block`
    - `storage_disk_full -> 503 + retry_after_ms`
    - `storage_archive_prune_activated`
    - recovery после возврата свободного места
    - evidence `stage11_storage_pressure_runtime.log`
  - дефект остаётся открыт только как cross-stage protective contour для `12/24/37`: release/perimeter/runtime hardening ещё должны сделать этот baseline обязательным production-blocker.

### [ ] DEF-024 — Startup configuration fail-closed validator
- Уровень: `D.6`
- Зависит от: `DEF-023`
- Затронутые stage-листы:
  - `CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `docs/source/startup_config_safety_validator_v0_2.md`
  - `docs/source/trust_boundary_hardening_v0_2.md`
  - `docs/source/ingress_perimeter_protection_v0_2.md`
- Что нужно сделать:
  1. запретить старт в опасной конфигурации: `plain HTTP` во внешнем профиле, placeholder/empty secrets, dev/debug flags в prod, опасные лимиты batch/queue;
  2. materialize `observability_gap.unsafe_startup_config_refused` как явный failure path, а не как запись только в docs;
  3. сделать startup validator обязательным blocker для release/runtime profiles;
  4. синхронизировать одну fail-closed логику для Core, Agent, systemd и container profiles.
- Чем доказать закрытие:
  - startup negative tests;
  - runtime gap-event и refusal logs;
  - release blocker evidence;
  - Linux/systemd/container runtime proof.

### [ ] DEF-025 — Queue integrity / duplicate / anti-loop protection
- Уровень: `D.7`
- Зависит от: `DEF-024`
- Затронутые stage-листы:
  - `CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
  - `CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md`
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `docs/source/queue_integrity_protection_v0_2.md`
  - `agent/src/main.rs`
  - `docs/agent/spool.md`
  - `docs/agent/receiver_source_coverage.md`
- Что нужно сделать:
  1. materialize per-source duplicate flood detector и anti-loop detection;
  2. ввести queue integrity state для ingest/backlog/replay и poisoned source isolation;
  3. сделать duplicate / loop / poisoned replay не silent, а observable hostile path;
  4. запретить закрытие spool/receivers/ingest без queue integrity hostile proof.
- Чем доказать закрытие:
  - duplicate flood tests;
  - anti-loop hostile tests;
  - `observability_gap.queue_integrity_violation`;
  - replay/backlog integrity evidence.

### [ ] DEF-026 — Guard self-observability / self-test
- Уровень: `D.8`
- Зависит от: `DEF-025`
- Затронутые stage-листы:
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/guard_self_observability_v0_2.md`
  - `scripts/ci/check_protective_contours.sh`
  - `scripts/ci/check_protective_safeguards_catalog.sh`
- Что нужно сделать:
  1. каждый защитный контур обязан иметь self-test, heartbeat и observable failure path;
  2. protective guards не могут считаться существующими, если их собственный отказ остаётся невидимым;
  3. release/process/Linux blockers должны зависеть от protective self-test proof;
  4. сломанный guard обязан materialize `observability_gap.guard_self_test_failed`.
- Чем доказать закрытие:
  - self-test logs;
  - runtime/process evidence по `guard_self_test_failed`;
  - release/Linux/process blocker evidence;
  - negative proof, что broken guard не остаётся silent.

### [ ] DEF-027 — Action execution safety guard
- Уровень: `D.9`
- Зависит от: `DEF-019`
- Затронутые stage-листы:
  - `CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md`
- Audit basis:
  - `docs/source/action_execution_safety_guard_v0_2.md`
  - `docs/runbooks/action_safety_guard_blocked.md`
  - `docs/governance/observability_gap_registry.md`
- Что нужно сделать:
  1. materialize semantic barrier между `request valid` и `execute allowed`;
  2. сделать destructive path невозможным без preflight, bounded-regret или policy exception;
  3. связать этот guard с secure actions, release и Linux production contour;
  4. сделать блокировку действия наблюдаемой и объяснимой для оператора.
- Чем доказать закрытие:
  - negative tests на destructive/high-impact actions;
  - `observability_gap.action_safety_guard_blocked`;
  - runbook-backed action refusal evidence;
  - secure-actions hostile proof.

### [ ] DEF-028 — Agent identity / enrollment / relay trust
- Уровень: `D.10`
- Зависит от: `DEF-003`
- Затронутые stage-листы:
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- Audit basis:
  - `docs/source/agent_identity_enrollment_trust_v0_2.md`
  - `docs/runbooks/agent_identity_untrusted.md`
  - `docs/source/agent_deployment_transport_v0_2.md`
- Что нужно сделать:
  1. ввести доверенную enrollment/attestation логику, а не только транспортную доставку;
  2. materialize trusted / untrusted / revoked состояния агента и relay-chain;
  3. привязать source truth к `agent_id/site_id/segment_id/relay_id`;
  4. запретить trusted ingest для недоказанного агента.
- Чем доказать закрытие:
  - enrollment/revocation negative tests;
  - `observability_gap.agent_identity_untrusted`;
  - trusted relay-chain evidence;
  - multi-site runtime proof.

### [ ] DEF-029 — Release truth enforcement
- Уровень: `D.11`
- Зависит от: `DEF-014`
- Затронутые stage-листы:
  - `CHECKLIST_04 _Secure SDLC + Supply-chain.md`
  - `CHECKLIST_07_ART_REPO_CI_DOCS.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/release_truth_enforcement_v0_2.md`
  - `docs/runbooks/release_truth_mismatch.md`
  - `RELEASE_CHECKLIST.md`
  - `docs/governance/release_decisions/latest_go_no_go.md`
- Что нужно сделать:
  1. запретить stale release metadata и stale evidence;
  2. сделать `README/CHANGELOG/RELEASE_CHECKLIST/GO-NO-GO` одним правдивым контуром;
  3. привязать release claims к текущему `HEAD`, а не к старой ревизии;
  4. сделать mismatch автоматическим blocker.
- Чем доказать закрытие:
  - stale-claim negative tests;
  - `observability_gap.release_truth_mismatch`;
  - release gate evidence;
  - buyer-visible parity между docs и runtime truth.

### [ ] DEF-031 — Regulatory claims drift control
- Уровень: `D.12`
- Зависит от: `DEF-010`
- Затронутые stage-листы:
  - `CHECKLIST_25_COMPLIANCE_AUDIT_READY.md`
  - `CHECKLIST_26_RU_PROFILE.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/regulatory_claims_drift_control_v0_2.md`
  - `docs/runbooks/regulatory_claim_drift.md`
  - `formats/ru_regulatory_scope.yaml`
- Что нужно сделать:
  1. запретить overclaim по certified/regulatory/RU-profile поверхности;
  2. связать customer-facing claims с machine-readable regulatory scope и evidence;
  3. разделить `certified`, `certified-ready`, `platform-supported` и `architecturally prepared`;
  4. сделать drift явным blocker для release и compliance contours.
- Чем доказать закрытие:
  - claim drift negative tests;
  - `observability_gap.regulatory_claim_drift`;
  - release/compliance evidence parity;
  - updated customer-facing docs without overclaim.

### [ ] DEF-034 — Documentation drift control
- Уровень: `D.13`
- Зависит от: `DEF-029`
- Затронутые stage-листы:
  - `CHECKLIST_07_ART_REPO_CI_DOCS.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/documentation_drift_control_v0_2.md`
  - `docs/portal/DOCUMENTATION_TREE.md`
  - `formats/documentation_tree_v0_2.yaml`
  - `scripts/ci/check_documentation_tree_sync.sh`
- Что нужно сделать:
  1. сделать documentation drift first-class blocker, а не вспомогательной удобной функцией;
  2. привязать дерево документации к корню, стволу и affected crown nodes;
  3. автоматически обнаруживать root-impact изменения и требовать синхронизации зависимых документов;
  4. запретить закрытие docs/release/overview stages без drift-proof.
- Чем доказать закрытие:
  - documentation tree guard;
  - `observability_gap.documentation_drift_detected`;
  - root-impact negative tests;
  - docs/release evidence parity.

### [ ] DEF-016 — Materialization of approved differentiators
- Уровень: `E.1`
- Зависит от: `DEF-034`
- Затронутые stage-листы:
  - `CHECKLIST_29_EVENT_DNA_CORE_V2.md`
  - `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
  - `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
  - `CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md`
  - `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
  - `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
  - `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`
  - `CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
  - `CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md`
  - `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`
  - `CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md`
  - `CHECKLIST_42_EVIDENCE_INTELLIGENCE_AND_DRIFT.md`
  - `CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md`
  - `CHECKLIST_44_INCIDENT_CAPSULE_AND_TWIN.md`
  - `CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md`
- Audit basis:
  - historical corpus + frontier documents + weak machine-readable/runtime materialization
- Что нужно сделать:
  1. materialize approved differentiators in contracts/runtime/tests;
  2. перестать хранить их только в foundation/docs;
  3. довести product uniqueness до executable form.
- Чем доказать закрытие:
  - runtime features;
  - contract surfaces;
  - negative-path and regression evidence;
  - continuity with historical corpus.

### [ ] DEF-017 — Structural decomposition of high-risk monoliths
- Уровень: `E.2`
- Зависит от: `DEF-016`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md`
  - `CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md`
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md`
- Audit basis:
  - `core/src/main.rs`
  - `agent/src/main.rs`
  - `apps/console-web/src/main.ts`
  - `packages/local-stores/src/index.ts`
  - `browser/src/outbox.js`
  - `docs/testing/buyer_due_diligence_signal_triage_v0_2.md`
- Что нужно сделать:
  1. декомпозировать high-risk entrypoints по bounded responsibilities, а не только выносить helper-функции;
  2. снизить code concentration в `core` и связанных runtime entrypoints;
  3. сделать так, чтобы security/runtime review и owner handoff не зависели от одного файла и одного человека;
  4. синхронизировать decomposition с architecture/docs и не потерять корневой замысел проекта.
- Текущее состояние:
  - дальнейший рост плотности в критичных файлах уже запрещён budget-guard'ом;
  - defect остаётся открыт до реальной декомпозиции, а не до “наличия guard-а”.
- Чем доказать закрытие:
  - decomposition report с line-count и responsibility split;
  - module-boundary tests;
  - reviewer-oriented architecture evidence;
  - отсутствие regressions после extraction.

### [ ] DEF-018 — Hostile integration and e2e test depth hardening
- Уровень: `E.3`
- Зависит от: `DEF-017`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
  - `CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
  - `CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `apps/console-web/test/console-web.test.mjs`
  - `browser/test/*.js`
  - `scripts/tests/*`
  - `docs/testing/buyer_due_diligence_signal_triage_v0_2.md`
- Что нужно сделать:
  1. усилить console/browser tests от string/render checks к hostile runtime/e2e chains;
  2. добавить длинные сценарии rollback/migration/reconnect/incident-chain именно для UI/runtime path;
  3. убрать зависимость от false-green статических HTML/assertion tests как от основного доказательства;
  4. связать эти tests с evidence и regression corpus.
- Чем доказать закрытие:
  - real browser/console hostile e2e suite;
  - rollback/migration/reconnect evidence;
  - anti-breakage screenshots/logs не placeholder-backed;
  - reduction of weak string-only gate dependence.

### [ ] DEF-021 — Pinned external adversarial harness для REGART и partner-exposed integration
- Уровень: `E.4`
- Зависит от: `DEF-018`
- Затронутые stage-листы:
  - `CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
  - `CHECKLIST_06_REGART_ART_BRIDGE.md`
  - `CHECKLIST_20_PACK_REGART.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/regart_adversarial_integration_harness_v0_2.md`
  - `formats/regart_adversarial_harness_v0_2.yaml`
  - `scripts/ci/check_regart_adversarial_harness.sh`
  - `docs/INTEGRATION.md`
  - `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Что нужно сделать:
  1. зафиксировать pinned source baseline для внешнего hostile harness;
  2. materialize suite-набор `smoke / hostile-bridge / replay / long-chain / actions-audit`;
  3. запретить floating `main` и sibling checkout как единственную truth-базу интеграционного доказательства;
  4. привязать harness evidence к stage 05/06/20/24/38 как обязательное доказательство.
- Чем доказать закрытие:
  - machine-readable harness policy и guard;
  - pinned source manifest;
  - hostile bridge/replay/long-chain/actions evidence;
  - release/process gate, который блокирует закрытие stage без harness proof.

### [ ] DEF-022 — Connected System View и declared-vs-observed truth
- Уровень: `E.5`
- Зависит от: `DEF-021`
- Затронутые stage-листы:
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_19_PACKS_FRAMEWORK.md`
  - `CHECKLIST_20_PACK_REGART.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
- Audit basis:
  - `docs/source/connected_system_visibility_v0_2.md`
  - `formats/connected_system_visibility_v0_2.yaml`
  - `docs/agent/receiver_source_coverage.md`
  - `docs/packs/source_coverage.md`
  - `packs/regart/manifest.yaml`
- Что нужно сделать:
  1. materialize Connected System View как обязательную сущность, которую видит оператор после подключения внешней системы;
  2. заставить packs и receiver/source coverage показывать declared и observed coverage в одном контуре без двусмысленности;
  3. ввести gap-события для invisible system и coverage drift;
  4. пришить этот контур к Console foundation так, чтобы система не могла считаться `connected` без свежих observed signals и evidence.
- Чем доказать закрытие:
  - machine-readable visibility model и guard;
  - manifest/source-coverage validation;
  - stage18/19/20/28 gates, которые падают без connected-system contour;
  - runtime/e2e evidence, что оператор реально видит system status, data kinds и active gaps.

### [ ] DEF-030 — Authenticity baseline
- Уровень: `E.6`
- Зависит от: `DEF-021`
- Затронутые stage-листы:
  - `CHECKLIST_04 _Secure SDLC + Supply-chain.md`
  - `CHECKLIST_07_ART_REPO_CI_DOCS.md`
  - `CHECKLIST_19_PACKS_FRAMEWORK.md`
  - `CHECKLIST_20_PACK_REGART.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`
- Audit basis:
  - `docs/source/authenticity_baseline_v0_2.md`
  - `docs/runbooks/authenticity_policy_violation.md`
  - `formats/authenticity_assets_allowlist.yaml`
  - `scripts/ci/check_authenticity_assets.sh`
- Что нужно сделать:
  1. сделать authenticity/provenance policy обязательной для baseline assets, packs, showcase и generated media;
  2. связать legal-safe baseline с CI, packs и release surface;
  3. запретить попадание неучтённых assets в проектный baseline;
  4. довести authenticity контур до buyer/audit-friendly состояния.
- Чем доказать закрытие:
  - authenticity gate evidence;
  - `observability_gap.authenticity_policy_violation`;
  - negative tests на unallowlisted assets;
  - release/pack/showcase parity.

### [ ] DEF-032 — Monolith budget guard
- Уровень: `E.7`
- Зависит от: `DEF-017`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md`
  - `CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md`
  - `CHECKLIST_18_ART_AGENT_RECEIVERS.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`
  - `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
  - `CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md`
- Audit basis:
  - `docs/source/monolith_budget_guard_v0_2.md`
  - `docs/runbooks/monolith_budget_exceeded.md`
  - `docs/testing/buyer_due_diligence_signal_triage_v0_2.md`
- Что нужно сделать:
  1. перевести growth of critical files под budget guard, а не только под ручной review;
  2. требовать decomposition plan до того, как монолит станет operational risk;
  3. связать budget exceed с architecture review и stage-blocking;
  4. сделать этот контур воспроизводимым для buyer due diligence.
- Текущее состояние:
  - machine-readable budget уже materialized;
  - CI guard уже materialized;
  - дальнейшая задача этой defect-линии — распространить guard по stage-level closure и decomposition evidence.
- Чем доказать закрытие:
  - budget guard evidence;
  - `observability_gap.monolith_budget_exceeded`;
  - decomposition reports;
  - CI check against file-size budget.

### [ ] DEF-033 — Test strength guard
- Уровень: `E.8`
- Зависит от: `DEF-018`
- Затронутые stage-листы:
  - `CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
  - `CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
  - `CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md`
  - `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
  - `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
  - `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`
  - `CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
  - `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- Audit basis:
  - `docs/source/test_strength_guard_v0_2.md`
  - `docs/runbooks/test_strength_guard_failed.md`
  - `docs/testing/production_adversarial_validation_law.md`
- Что нужно сделать:
  1. сделать силу тестов first-class guard, а не выводом человека по месту;
  2. запрещать closure на decorative/structural-only proof;
  3. требовать contract/behavior/integration/operational/adversarial/regression families для критичных контуров;
  4. связать этот guard с release and stage closure.
- Чем доказать закрытие:
  - test strength guard evidence;
  - `observability_gap.test_strength_guard_failed`;
  - hostile test family matrix;
  - release blocker on weak proof.

## Правило применения
1. Работа по remediation начинается с первой строки `[ ]` в порядке ведомости.
2. Пока строка не закрыта, все её `Блокирует stages` считаются запрещёнными к повторному закрытию.
3. Если строка раскрывает более глубокую причину, создаётся новая строка ниже по уровню, а не обходной фикc наверху.
4. После закрытия строки обновляются:
   - `full_line_by_line_audit_registry_v0_2.md`
   - `stage_reopening_matrix_v0_2.md`
   - `defect_remediation_ladder_v0_2.md`
   - `CHECKLIST_00_MASTER_ART_REGART.md`
5. Только после этого разрешён переход к следующей строке.

## Статус
- Статус документа: `ACTIVE`
- Режим: `MANDATORY_FOR_REMEDIATION`
- Текущая активная строка: `DEF-001`
