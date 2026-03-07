# Реестр полного построчного аудита v0.2

## Source of truth
- `docs/testing/full_line_by_line_audit_program_v0_2.md`

## Слой 1 — Root + GitHub entry layer

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `.github/CODEOWNERS` | REVIEWED | WEAK | Единственный owner `@neo-2022`; governance зависит от одного человека, нет резервной code-owner модели. | 01, 04 |
| `.github/ISSUE_TEMPLATE/bug.yml` | REVIEWED | OK | Структурный входной шаблон; глубину hostile triage оценивать позже в governance слое. | 01 |
| `.github/ISSUE_TEMPLATE/incident.yml` | REVIEWED | OK | Есть отдельный инцидентный шаблон; потребуется дальнейшая сверка с incident lifecycle. | 01 |
| `.github/dependabot.yml` | REVIEWED | OK | Реальный dependency-update baseline появился; weekly + main + 3 ecosystems. | 04 |
| `.github/pull_request_template.md` | REVIEWED | WEAK | Хороший каркас, но не заставляет прикладывать adversarial/negative-path evidence явно. | 01, 38 |
| `.github/workflows/ci.yml` | REVIEWED | WEAK | Очередь уже смягчена, но файл остаётся чрезмерно раздутым; много jobs по-прежнему document/meta oriented. | 07, 38 |
| `.github/workflows/nightly-stage29-replay-determinism.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/nightly_chaos.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/platform_matrix_stage37.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.github/workflows/release_stage04.yml` | REVIEWED | OK | Реальный release pipeline: static artifacts, SBOM, checksums, provenance, cosign sign+verify. | 04, 24 |
| `.github/workflows/required_gates.yml` | REVIEWED | WEAK | Дублирование снижено, но workflow всё ещё повторяет часть security/SDLC смыслов и может расходиться с основным CI-контуром. | 01, 04, 38 |
| `.github/workflows/security_stage04.yml` | REVIEWED | OK | После многократного дебаггинга даёт доказанный эксплуатационный эффект, различает infra failure и findings. | 04 |
| `.github/workflows/stage14-soak-artifacts.yml` | IN_REVIEW | TBD | TBD | TBD |
| `.gitignore` | REVIEWED | OK | Базово адекватен; deeper packaging/runtime leakage проверять позже. | 07 |
| `.gitleaks.toml` | REVIEWED | WEAK | Есть `Temporary allowlist`; даже при осмысленном содержимом сама временная семантика противоречит production-строгости. | 04 |
| `CHANGELOG.md` | REVIEWED | OK | Содержит реальные baseline shifts; позже проверить полноту против фактической истории релизов. | 24 |
| `Cargo.lock` | REVIEWED | OK | Наличие root lockfile соответствует deterministic dependency baseline. | 04 |
| `Cargo.toml` | REVIEWED | OK | Профили `general/certified` уже зафиксированы; deeper certified-runtime check позже в code/platform слоях. | 04, 37 |
| `LICENSE` | REVIEWED | OK | Есть явная лицензия-константа; соответствует private baseline. | 04, 07 |
| `Makefile` | REVIEWED | WEAK | Полезен как dev-entry, но `smoke/security-smoke` ещё не отражают hostile/adversarial философию целиком. | 07, 04 |
| `README.md` | REVIEWED | OK | Сильный product-facing вход, но production candidate claims надо ещё сверить с полным runtime corpus. | 07, 24 |
| `RELEASE_CHECKLIST.md` | REVIEWED | WEAK | Release hygiene есть, но candidate commit и current baseline требуют сверки с реальным HEAD/PR state при каждом цикле. | 24, 37 |
| `SECURITY.md` | REVIEWED | WEAK | Слишком тонкий для зрелого продукта: нет threat-model entry, intake flow, disclosure classes, artifact expectations. | 04, 25 |

## Слой 2 — Канон, foundation, testing и MASTER

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `docs/source/FOUNDATION_CONSTITUTION_V0_2.md` | REVIEWED | OK | Канон силён и уже включает hostile/adversarial law, Truth Modes, Evidence-First и continuation concepts. Риск не в тексте, а в недоведении кода/тестов до уровня канона. | 00, 28..45 |
| `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md` | REVIEWED | MISMATCH | MASTER уже открыт, но таблица этапов всё ещё хранит старые записи “выполнено” для открытых стадий; это создаёт риск ложного ощущения завершённости. | 00, 38 |
| `docs/source/checklists/TRACEABILITY_V0_2.md` | REVIEWED | WEAK | Хорошо пришивает идеи и stages, но остаётся документом намерения; не все mapping уже материализованы в runtime/test corpus. | 00, 38, 39..45 |
| `docs/source/README.md` | REVIEWED | OK | Корневой source-index адекватный; потребуется later сверка каждого external source link с реальным runtime scope. | 00, 05, 06 |
| `docs/source/Art_v1_spec_final.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/source/risk_register_v0_2.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/lens_audit_report.md` | REVIEWED | WEAK | Хотя стал лучше, всё ещё содержит известные открытые gaps как фон; сам факт наличия unresolved production gaps требует реального reopening downstream stages. | 28, 35, 37, 38 |
| `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md` | REVIEWED | OK | Исторический корпус подробный и полезный; не проблема в содержании, а в runtime-program materialization approved ideas. | 39..45 |
| `docs/foundation/revolutionary_hypotheses.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/frontier_tech_radar.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md` | IN_REVIEW | TBD | TBD | TBD |
| `docs/testing/production_adversarial_validation_law.md` | REVIEWED | OK | Новый базовый закон сформулирован жёстко и соответствует философии проекта. | 00, all |
| `docs/testing/test_system_audit_v0_2.md` | REVIEWED | WEAK | Уже честно признаёт слабые зоны, но это пока meta-audit; сам проект ещё не приведён к заявленному стандарту. | 00, all |
| `docs/testing/full_line_by_line_audit_program_v0_2.md` | REVIEWED | OK | Корректно фиксирует приказ на буквальный построчный аудит. | 00 |
| `docs/testing/full_line_by_line_audit_registry_v0_2.md` | REVIEWED | OK | Рабочий реестр ретро-аудита, используется как текущий артефакт программы. | 00 |

## Слой 3 — Contracts, formats, generated, API/schemas

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `docs/contracts/v2/README.md` | REVIEWED | WEAK | Каталог описан слишком узко и уже не отражает полный набор v2 схем (`evidence_lineage`, `tenant_context`, `saas_quota_retention_policy`, access-audit records). | 08, 29, 30, 36 |
| `docs/contracts/v2/openapi.yaml` | REVIEWED | WEAK | Базовые v2 endpoints уже есть, но утверждённые differentiators из исторического корпуса (`Proof Completeness Score`, `DNA Drift Radar`, `Counterfactual Action Simulator`, `Incident Capsule`, `Deterministic Incident Twin`) в contract surface не материализованы. | 29, 30, 31, 33, 34, 42, 43, 44 |
| `docs/contracts/v2/contract_fingerprint.sha256` | REVIEWED | OK | Fingerprint corpus полон и помогает удерживать contract drift под контролем. | 08, 29 |
| `docs/contracts/v2/dna_model/dna_core_clusterization.cfg` | REVIEWED | OK | Конфиг model-checking соответствует formal DNA path; это сильное основание для stage29. | 29 |
| `docs/contracts/v2/schemas/claim_v2.json` | REVIEWED | WEAK | Truth modes и lineage зафиксированы хорошо, но нет machine-readable поля для `Proof Completeness Score` и related explanation payload. | 30, 42 |
| `docs/contracts/v2/schemas/dialog_message_v2.json` | REVIEWED | OK | Есть `lineage_hash`, `evidence_refs`, `audit_refs`, truth modes и typed dialog model; это соответствует dialogic baseline. | 30, 31, 33 |
| `docs/contracts/v2/schemas/dna_cluster.json` | REVIEWED | WEAK | Канонический `dna_id` и truth modes есть, но нет drift/twin hooks, нет machine-readable поля для drift fingerprint или deterministic twin parity metadata. | 29, 34, 42, 44 |
| `docs/contracts/v2/schemas/dna_signature.json` | REVIEWED | WEAK | Signature фиксирует hash/версии, но не несёт drift/twin parity metadata и не помогает машинно отличать replay/twin assertions. | 29, 42, 44 |
| `docs/contracts/v2/schemas/evidence_access_audit_record_v2.json` | REVIEWED | WEAK | Есть `actor_role`, но нет явного `actor_id`/subject id; для строгого audit posture запись слишком обобщённая. | 01, 25, 32 |
| `docs/contracts/v2/schemas/evidence_block.json` | REVIEWED | WEAK | Есть `trust_score` и policy fields, но нет явной provenance/lineage binding и capsule-ready metadata на уровне блока. | 30, 31, 42, 44 |
| `docs/contracts/v2/schemas/evidence_item.json` | REVIEWED | OK | Union/oneOf evidence model и truth metadata соответствуют evidence-first baseline. | 30, 31, 32 |
| `docs/contracts/v2/schemas/evidence_lineage_v2.json` | REVIEWED | WEAK | Lineage graph уже есть, но модель ещё линейная и бедная для сложных multi-claim/multi-branch relations; для approved differentiators это пока узкое место. | 30, 31, 42, 44, 45 |
| `docs/contracts/v2/schemas/gap_event.json` | REVIEWED | OK | Gap event имеет truth metadata; базовый hostile-runtime контур закреплён. | 18, 29, 37 |
| `docs/contracts/v2/schemas/investigation_doc_v1.json` | REVIEWED | WEAK | Базовый InvestigationDoc есть, но нет capsule/twin-ready machine-readable envelope и формального replay portability contract. | 31, 44 |
| `docs/contracts/v2/schemas/raw_event_v2.json` | REVIEWED | WEAK | Схема чрезмерно permissive: `additionalProperties: true`, обязателен только `severity`, нет жёстких correlation/source/privacy baseline полей. Для hostile-runtime ingestion это слишком слабое основание. | 09, 12, 18, 29 |
| `docs/contracts/v2/schemas/saas_quota_retention_policy_v2.json` | REVIEWED | OK | Для SaaS/retention контуров схема уже strong: quotas, retention и compliance export фиксированы жёстко. | 36 |
| `docs/contracts/v2/schemas/snapshot_v2.json` | REVIEWED | WEAK | Snapshot содержит truth modes, gap/slo arrays, но `incidents` остаётся нетипизированным `object`, а capsule/twin/proof-carrying extensions отсутствуют. | 29, 31, 32, 42, 44 |
| `docs/contracts/v2/schemas/slo_violation.json` | REVIEWED | OK | Есть truth metadata и evidence linkage; соответствует SLOViolation baseline. | 30, 34 |
| `docs/contracts/v2/schemas/tenant_context_v2.json` | REVIEWED | WEAK | Tenant context фиксирует базовые IDs, но нет regulatory/profile/runtime placement fields, важных для multi-plane SaaS и RU/regional rules. | 26, 36 |
| `docs/contracts/v2/migrations_v2.md` | REVIEWED | OK | Dual-write verification, lag normalization и rollback semantics описаны строго; migration path уже ближе к production-grade, чем большинство docs-only контуров. | 29, 24 |
| `docs/contracts/v2/dna_model/dna_core_clusterization.tla` | REVIEWED | OK | Сам факт formal model и replay/determinism properties соответствует философии проекта; deeper content parity с Rust проверять уже в code-layer аудите. | 29 |
| `docs/api/openapi.yaml` | REVIEWED | WEAK | v1 API слишком тонкий и partly permissive (`additionalProperties: true`), слабо отражает evidence-first и typed hostile-runtime philosophy. | 08, 14, 24 |
| `docs/api/errors.md` | REVIEWED | WEAK | Error reference полезен, но узок: отсутствует связь с v2/gap events/hostile diagnostics и richer invalid code taxonomy. | 08, 09, 29 |
| `docs/api/schemas.md` | REVIEWED | WEAK | Страница по-прежнему живёт в логике только v1 и не отражает реальный dual-surface проекта. | 08, 29, 30 |
| `docs/api/snapshot.md` | REVIEWED | WEAK | Snapshot reference ограничен v1 и не связывает snapshot path с truth modes, evidence lineage и replay contracts v2. | 14, 29, 31 |
| `docs/api/stream.md` | REVIEWED | WEAK | Хорошо описывает cursor semantics v1, но не выражает modern v2 stream obligations и hostile/backlog discipline полностью. | 14, 29 |
| `docs/api/versioning.md` | REVIEWED | WEAK | Политика versioning слишком общая и не связывает schema evolution с fingerprint, migration and generated-clients discipline. | 08, 24, 29 |
| `docs/api/schema_compliance.md` | REVIEWED | WEAK | Таблица соответствия слишком узкая: покрывает только базовый ingest/v1 и не отслеживает v2 truth-mode / evidence-lineage / dialog / DNA obligations. | 08, 29, 30 |
| `docs/schemas/README.md` | REVIEWED | WEAK | Допущение `additionalProperties` как общего правила противоречит нынешней философии строгих machine-readable contracts. | 08, 29 |
| `docs/schemas/v1/incident.json` | REVIEWED | WEAK | Legacy incident schema слишком свободна и бедна для production-grade incident OS baseline. | 08, 14 |
| `docs/schemas/v1/ingest_envelope.json` | REVIEWED | WEAK | Envelope слишком permissive и не задаёт hostile-ingest discipline. | 08, 12 |
| `docs/schemas/v1/ingest_response.json` | REVIEWED | WEAK | Response отражает только старый базовый контур и допускает лишнюю свободу структуры. | 08, 12 |
| `docs/schemas/v1/raw_event.json` | REVIEWED | WEAK | Историческая схема v1 слишком слабая даже как legacy baseline: `additionalProperties: true`, минимум полей, нет ясного hostile-ingest discipline. | 08, 29 |
| `formats/platform_support.yaml` | REVIEWED | OK | Machine-readable OS/platform matrix сильная, учитывает РФ и международные Linux-дистрибутивы, VM/container surfaces и evidence IDs. | 26, 37 |
| `formats/ru_regulatory_scope.yaml` | REVIEWED | OK | РФ нормативный контур материализован корректно, включая certified-ready boundary и mandatory controls. | 25, 26, 37 |
| `generated/ts/README.md` | REVIEWED | WEAK | README generated-клиента фактически пустой; не объясняет scope, статус полноты и ограничения auto-generated слоя. | 07, 08 |
| `generated/rust/README.md` | REVIEWED | WEAK | Аналогично TS: слишком тонкое описание, риск ввести инженера в заблуждение о полноте generated client. | 07, 08 |
| `docs/schemas/index.md` | REVIEWED | WEAK | Индекс схем ограничен только v1 набором и не отражает v2 contract surface, что ломает целостность machine-readable картины проекта. | 08, 29, 30 |
| `generated/ts/src/index.ts` | REVIEWED | WEAK | Generated TS слой покрывает только ingest primitives; он не представляет реальный breadth contract surface проекта. | 08, 29, 30 |
| `generated/rust/src/lib.rs` | REVIEWED | WEAK | Generated Rust слой аналогично урезан до ingest primitives, что создаёт ложное ощущение полноты generated clients. | 08, 29, 30 |

## Слой 4 — Runtime/code hot spots и известные слабые основания

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `tests/platform/vm/run_vm_smoke.sh` | REVIEWED | MISMATCH | `execute` path через `vagrant ssh` по-прежнему гоняет `vm smoke placeholder`; VM surface заявлен сильнее, чем реализован. | 37, 38 |
| `docs/ops/operational_debt_register.md` | REVIEWED | MISMATCH | В реестре всё ещё живёт `Stage37 template debt placeholder`, а не реальный production debt corpus. | 37, 38 |
| `packs/regart/payload/README.md` | REVIEWED | MISMATCH | REGART payload остаётся placeholder, хотя интеграционный контур уже заявлен как зрелый. | 19, 20 |
| `packages/local-stores/src/index.ts` | REVIEWED | MISMATCH | Рядом с реальными spatial функциями сохраняется `spatialStoreStub()` со статусом `stubbed`; это консервирует неполную зрелость stage35 прямо в runtime surface. | 35, 38 |
| `packages/local-stores/test/local-stores.test.mjs` | REVIEWED | MISMATCH | Тест закрепляет `stubbed` как допустимый результат, то есть защищает слабое основание вместо его устранения. | 35, 38 |
| `packages/i18n/src/index.ts` | REVIEWED | MISMATCH | RU-слой неполон: `Command Center`, `Event River`, `Incident Room`, `Scenario View`, `Time Field`, `Audit Explorer`, `Action Studio`, а также `verified/failed/unavailable` остаются на английском, несмотря на обязательную двуязычность. | 16, 28, 30 |
| `apps/console-web/src/main.ts` | REVIEWED | WEAK | В UI остаются локальные hardcoded строки и обходы словаря: `Проверить audit chain`, `Flow: Проверить audit chain`, `Route:`, fixed placeholders. Bilingual/i18n discipline ещё не доведена до полной чистоты. | 16, 28, 30, 40 |
| `scripts/tests/stage32_audit_ux_anti_breakage_e2e.sh` | REVIEWED | MISMATCH | Тест может завершиться `PASS (fallback)` и подложить placeholder PNG, то есть anti-breakage success допускает отсутствие реального browser path. При реальном запуске gate зелёный, но это не отменяет ложный fallback-green path. | 32, 38 |
| `scripts/tests/stage33_action_flow_anti_breakage_e2e.sh` | REVIEWED | MISMATCH | Аналогично stage32: placeholder fallback разрешает PASS без реального e2e исполнения. Дополнительно выявлена хрупкость test harness: при повторном запуске возможен `EADDRINUSE` на playwright socket. | 33, 38 |
| `tests/platform/contract/generate_evidence_bundle.sh` | REVIEWED | MISMATCH | Evidence bundle всё ещё генерирует `status=placeholder` для большой части natural surfaces; это не production-grade evidence semantics. | 24, 37, 38 |

## Слой 5 — Core / Agent / Panel0 / UI-law code entry layer

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `core/src/main.rs` | REVIEWED | WEAK | Кодовая база сильная: много runtime и property/replay tests, OTLP, v2 DNA, audit/merkle, analytics. Но entry-layer всё ещё несёт loosely typed `Incident`/snapshot incidents и не материализует approved differentiators из исторического корпуса на runtime-уровне. | 14, 29, 32, 33, 34, 42, 44 |
| `agent/src/main.rs` | REVIEWED | MISMATCH | Runtime receiver surface ограничен `file_tail`, `journald`, `stdout_stderr`; это противоречит уже утверждённому coverage (`systemd_unit`, `proc_probe`, `net_probe`, `otlp_logs`). Тесты зелёные, но покрывают только этот урезанный контур. | 18, 23, 37, 38 |
| `core/embedded/panel0/bootstrap.html` | REVIEWED | MISMATCH | Fallback/bootstrap path рабочий и stage16 runtime зелёный, но двуязычность неполная: title/часть EN-строк остаются жёстко вшитыми. | 16, 28 |
| `packages/ui-laws/src/index.ts` | REVIEWED | OK | Runtime law layer сильный: truth modes, RTP, semantic token discipline, evidence-link invariants уже пришиты кодом. Нерешённой остаётся не библиотека, а отсутствие AST/static enforcement слоя. | 28, 30, 41 |
| `packages/evidence-linking/src/index.ts` | REVIEWED | WEAK | Пакет пока очень тонкий: только href builders. Для заявленного evidence-linking differentiator этого недостаточно. | 28, 30, 45 |

## Слой 6 — Browser-facing support / worker / static generation

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `core/embedded/panel0/index.html` | REVIEWED | MISMATCH | Index page Panel0 остаётся частично англоязычной (`lang=\"en\"`, `Embedded emergency panel for Core`, `Language`, `Core is unavailable`, `Evidence payload`). | 16, 28 |
| `core/embedded/panel0/panel0.js` | REVIEWED | MISMATCH | RU-словарь неполон: часть ключей и значений остаются англоязычными (`Art Panel0`, `build_id`, `effective_profile_id`, `Evidence payload`, `network error`). | 16, 28 |
| `core/embedded/panel0/panel0.css` | REVIEWED | OK | CSS простая, но честная: не маскирует runtime gaps и не вносит дополнительной логической слабости. | 16 |
| `core/embedded/panel0/panel0_sw.js` | REVIEWED | WEAK | SW реализует базовый offline cache, но fallback ответ `offline` примитивен и не несёт structured degraded-mode semantics. | 16, 37 |
| `packages/worker-runtime/src/index.ts` | REVIEWED | MISMATCH | Worker runtime фактически stub: `runTask` просто возвращает payload. Для заявленного worker/Wasm isolation layer это пока только каркас. | 28, 34, 35, 43 |
| `packages/worker-runtime/README.md` | REVIEWED | MISMATCH | README отсутствует, несмотря на наличие пакета. Это ухудшает честность package surface и вводит в заблуждение о зрелости worker-layer. | 07, 28 |
| `apps/console-web/scripts/generate-static.mjs` | REVIEWED | WEAK | Генератор статического shell строит только `en` вариант `index.html`; для строгой bilingual philosophy этого недостаточно. | 16, 28 |
| `apps/console-web/test/console-web.test.mjs` | REVIEWED | WEAK | Тесты сильны в breadth UI laws, но принимают неполную RU локализацию и не ловят hardcoded bilingual leaks. | 16, 28, 30, 40 |

## Слой 7 — Security / Privacy / Compliance policy basis

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `docs/security/allowlist.gitleaks.toml` | REVIEWED | OK | Allowlist теперь честно пустой и не содержит placeholder-семантики. | 04 |
| `docs/security/branch_tag_policy.md` | REVIEWED | OK | Политика жёсткая и согласована с реальным branch protection evidence. | 04, 24 |
| `docs/security/certified_dependency_allowlist.txt` | REVIEWED | WEAK | Есть машиночитаемый список, но он слишком “плоский”: нет owner/disposition/why, не выражена граница Linux certified path против всего dependency tree. | 04, 37 |
| `docs/security/ci_pinning_policy.md` | REVIEWED | OK | Supply-chain pinning зафиксирован жёстко и проверяется отдельным gate. | 04 |
| `docs/security/dependency_update_policy.md` | REVIEWED | OK | Dependabot и PR-only discipline материализованы корректно. | 04 |
| `docs/security/fstec-certified-profile.md` | REVIEWED | WEAK | Certified profile описан честно, но пока остаётся build/profile guarantee без runtime/legal-grade доказательств; для зрелого certified contour этого мало. | 04, 26, 37 |
| `docs/security/keys/README.md` | REVIEWED | OK | Правильно закрепляет отказ от placeholder public key и переводит baseline на keyless OIDC verify. | 04, 24 |
| `docs/security/mcp_modes_runtime.md` | REVIEWED | WEAK | Документ слишком тонкий: `limited_actions` не раскрыт allowlist-моделью, нет tenant/profile/action-scope детализации. | 01, 33 |
| `docs/security/osv_risk_accept.yaml` | REVIEWED | WEAK | Реестр точечный и честный, но сам факт active temporary risk-accept означает незакрытое security основание. | 04, 23 |
| `docs/security/pii_secret_filter.md` | REVIEWED | WEAK | Слишком тонкий operational документ: нет rule ids, coverage matrix, versioning и failure-mode semantics. | 02, 15 |
| `docs/security/provenance_signing.md` | REVIEWED | OK | Signing/provenance baseline сильный и согласован с release pipeline. | 04, 24 |
| `docs/security/rbac.md` | REVIEWED | WEAK | RBAC-контур слишком грубый: нет tenant/profile-aware различий, нет agent/bridge/service action scope. | 15, 33, 36 |
| `docs/security/release_hardening.md` | REVIEWED | WEAK | Политика полезная, но слишком обзорная; не выражает hostile release scenarios и не связывает rollback/compromise paths с конкретными control points. | 04, 24, 37 |
| `docs/security/sast_policy.md` | REVIEWED | OK | SAST policy после hardening соответствует blocking-gate baseline. | 04 |
| `docs/security/sbom_policy.md` | REVIEWED | OK | SBOM baseline строгий и согласован с signing bundle. | 04, 24 |
| `docs/security/sca_policy.md` | REVIEWED | WEAK | Политика рабочая, но несёт дублированный раздел risk-accept и оставляет активный класс tolerated-risk как часть baseline. | 04 |
| `docs/security/secrets_policy.md` | REVIEWED | OK | Secrets scanning policy жёсткая и теперь не содержит placeholder bypass path. | 04 |
| `docs/security/secure_sdlc_policy.md` | REVIEWED | OK | Secure SDLC baseline сильный и после дебаггинга соответствует reproducible-build philosophy. | 04 |
| `docs/privacy/access_control_policy.md` | REVIEWED | OK | Least-privilege для attachments выражен честно и не несёт public-by-default слабости. | 02 |
| `docs/privacy/attachments_security.md` | REVIEWED | OK | Attachment baseline детален и соответствует privacy-by-design. | 02 |
| `docs/privacy/data_classification.md` | REVIEWED | OK | Каноническая классификация сильная и пригодна как основание для redaction/minimization. | 02 |
| `docs/privacy/data_minimization_policy.md` | REVIEWED | OK | No-body-by-default и allowlist discipline зафиксированы строго. | 02, 09, 18 |
| `docs/privacy/dsr_process.md` | REVIEWED | WEAK | Процесс описан лучше прежнего, но не задаёт отдельный identity-proof/authorization contour субъекта запроса; это слабое основание для зрелого privacy workflow. | 02, 25 |
| `docs/privacy/encryption_policy.md` | REVIEWED | WEAK | Encryption-at-rest описан только для `events`, `audit`, `attachments`; выпадают `incidents`, `spool/outbox`, local indexes и privacy-sensitive exports, что делает baseline неполным. | 02, 17, 18, 31, 37 |
| `docs/privacy/pii_surface.md` | REVIEWED | MISMATCH | В карте есть логические ошибки основания: `context.user_agent` привязан к `redact.ip.v1`, а `payload.file.path` помечен как безусловно `store`, хотя path может нести PII. | 02, 18, 30 |
| `docs/privacy/redaction_policy.md` | REVIEWED | MISMATCH | Политика требует `config/privacy/redaction_rules.yaml`, но такого файла нет; кроме того, rule mapping наследует ту же ошибку с `context.user_agent -> redact.ip.v1`. | 02, 18, 30 |
| `docs/privacy/regional_profiles.md` | REVIEWED | MISMATCH | Privacy-профили неполны: отсутствует `airgapped`, а критерий актуальности требует `default profile`, который в документе не задан. | 02, 03, 26 |
| `docs/privacy/retention_matrix.md` | REVIEWED | MISMATCH | Прямой конфликт с `docs/compliance/profiles.md`: `incidents` = `180 days` здесь и `90 days` в профилях; это фундаментальный policy drift. | 02, 03, 26 |
| `docs/privacy/test_matrix.md` | REVIEWED | WEAK | Матрица полезна, но не дотягивает до adversarial philosophy: нет hostile сценариев, negative export abuse, storage leakage и profile-crossing tests. | 02, 38 |
| `docs/compliance/airgapped.md` | REVIEWED | WEAK | Offline verify path честный, но документ слишком узок и не покрывает hostile media handling, custody chain и rollback/compromise path. | 03, 24, 26 |
| `docs/compliance/audit_trail.md` | REVIEWED | WEAK | Экспортный контур указан, но документ слишком тонок: нет integrity semantics beyond checksum, нет failure-mode и custody/verification discipline. | 25 |
| `docs/compliance/control_matrix.md` | REVIEWED | MISMATCH | Матрица опирается на `raw_archive/evidence/`, которого в репозитории нет; это ложное основание контроля. | 25, 27 |
| `docs/compliance/data_destruction.md` | REVIEWED | MISMATCH | Документ фактически placeholder: фиксированное `pass/fail: pass` без критериев, evidence, hostile verification и среды исполнения. | 25, 37 |
| `docs/compliance/data_residency.md` | REVIEWED | OK | Data residency policy достаточно строгая и правильно завязана на fail-closed behaviour. | 03, 26 |
| `docs/compliance/evidence_list.md` | REVIEWED | MISMATCH | Основан на `raw_archive/`, которого нет; следовательно, compliance evidence storage описан декларативно, а не реально. | 25, 27 |
| `docs/compliance/profile_guards.md` | REVIEWED | OK | Profile guardrails выражены достаточно жёстко и согласованы с fail-closed подходом. | 03, 26 |
| `docs/compliance/profiles.md` | REVIEWED | MISMATCH | Профили сильны по структуре, но конфликтуют с privacy retention baseline (`incidents=90` против `180`) и поэтому сами создают policy drift. | 03, 26 |
| `docs/compliance/test_matrix.md` | REVIEWED | WEAK | Хорошая stage03 matrix, но она не покрывает hostile/compliance-adversarial сценарии и не ловит policy drift вроде уже найденного retention mismatch. | 03, 38 |

## Слой 8 — Ops / Governance operational basis

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `docs/ops/agent_multisite_deploy.md` | REVIEWED | OK | Multi-site/relay/WAN модель изложена жёстко и согласована с transport philosophy. | 18, 23, 37 |
| `docs/ops/alerts.md` | REVIEWED | WEAK | Пороговые алерты перечислены, но нет owner mapping, evidence contract и hostile false-positive/false-negative discipline. | 21, 37 |
| `docs/ops/art_regart_contract_parity.md` | REVIEWED | WEAK | Контур parity полезен, но завязан на внешний repo и артефакт-репорт; при недоступности внешнего source-of-truth proof path остаётся уязвим. | 05, 06, 37 |
| `docs/ops/backup_restore.md` | REVIEWED | MISMATCH | Фактически placeholder-runbook: слишком тонкий контур и фиктивное `pass/fail: pass` без критериев hostile восстановления. | 23, 37 |
| `docs/ops/backup_restore_sqlite.md` | REVIEWED | WEAK | Частота backup и базовые пути есть, но нет restore drill discipline, custody/evidence и negative-path criteria. | 11, 23, 37 |
| `docs/ops/console_linux_prod_readiness.md` | REVIEWED | WEAK | Документ задаёт правильную планку, но уже расходится с текущим runtime состоянием RU/i18n и поэтому не может считаться полностью доказанным operational baseline. | 16, 28, 37 |
| `docs/ops/db_migration_runbook.md` | REVIEWED | WEAK | Слишком тонкий migration runbook: нет explicit rollback decision tree, evidence contract и multi-failure path. | 23, 24 |
| `docs/ops/deploy_k8s.md` | REVIEWED | WEAK | Есть cert-manager baseline, но deployment contour слишком тонок для production-grade k8s path: нет StatefulSet/storage/RBAC/rollback detail. | 23, 37 |
| `docs/ops/deploy_systemd.md` | REVIEWED | WEAK | Plain HTTP fallback при отсутствии TLS env остаётся слишком мягким operational baseline для production-hardening контура. | 23, 37 |
| `docs/ops/dr_drill.md` | REVIEWED | MISMATCH | Как и backup_runbook, документ остаётся placeholder-like: `pass/fail: pass` без строгих доказательных критериев. | 23, 37 |
| `docs/ops/github_actions_queue_remediation_plan.md` | REVIEWED | OK | План честно фиксирует root cause CI queue issue и уже использовался как рабочий remediation artifact. | 04, 07, 38 |
| `docs/ops/go_no_go_template.md` | REVIEWED | OK | Шаблон строгий и соответствует production gate discipline. | 24, 37, 38 |
| `docs/ops/ingest_chaos.md` | REVIEWED | OK | Chaos-контур для ingest выражен достаточно жёстко и без явных placeholder-path. | 12, 22, 23 |
| `docs/ops/metrics.md` | REVIEWED | WEAK | Слишком тонкое описание: перечислены только ключевые метрики без cardinality/retention/owner/alert semantics. | 21, 37 |
| `docs/ops/operational_debt_register.md` | REVIEWED | MISMATCH | Реестр до сих пор содержит `Stage37 template debt placeholder` вместо реального operational debt corpus. | 37, 38 |
| `docs/ops/panel0_linux_prod_readiness.md` | REVIEWED | WEAK | Требования корректны, но документ уже опережает фактическое bilingual/runtime состояние Panel0. | 16, 37 |
| `docs/ops/platform-container-k8s-testing.md` | REVIEWED | OK | Container/K8s runtime testing выражен честно и лучше большинства ops-документов. | 37 |
| `docs/ops/platform-runtime-compatibility-matrix.md` | REVIEWED | WEAK | Матрица сильная, но связывает release blockers с VM evidence при том, что VM execute-path остаётся placeholder-backed. | 37, 38 |
| `docs/ops/platform-support.md` | REVIEWED | WEAK | Общая матрица хорошая, но production scope всё ещё опирается на частично validate-only поверхности; декларации нужно синхронизировать с runtime truth после VM remediation. | 26, 37 |
| `docs/ops/platform-vm-testing.md` | REVIEWED | MISMATCH | Описывает execute-mode как рабочий путь, тогда как `tests/platform/vm/run_vm_smoke.sh` всё ещё содержит placeholder execute path. | 37, 38 |
| `docs/ops/runtime_incident_status.json` | REVIEWED | WEAK | Используется как gate input, но пока выглядит как вручную поддерживаемое состояние с note про automation; автоматический update path нужно доказать сильнее. | 29, 38 |
| `docs/ops/self_observability.md` | REVIEWED | WEAK | Internal incidents перечислены, но coverage остаётся уже реального registry/alerting breadth проекта. | 21, 37 |
| `docs/ops/stage_ladder_enforcement.md` | REVIEWED | OK | Лестничный process law выражен жёстко и связан с runtime incident state. | 38 |
| `docs/ops/storage.md` | REVIEWED | OK | Storage chaos описан достаточно строго и связан с `observability_gap.*`. | 11, 22, 23 |
| `docs/ops/storage_corruption_runbook.md` | REVIEWED | OK | Recovery path и failover/read_only semantics заданы достаточно жёстко. | 11, 23 |
| `docs/ops/tls_rotation.md` | REVIEWED | WEAK | Документ полезен, но снова слишком тонок и опирается на smoke `pass/fail: pass`, не выражая hostile rotation/revocation scenarios. | 23, 37 |
| `docs/ops/vacuum_schedule.md` | REVIEWED | OK | VACUUM baseline и gap semantics определены достаточно строго. | 11, 23 |
| `docs/governance/audit_policy.md` | REVIEWED | WEAK | Для append-only audit policy документ слишком тонкий: не хватает actor identity contract, verify path и hostile misuse semantics. | 01, 15, 32 |
| `docs/governance/change_policy.md` | REVIEWED | OK | Change governance сильный и согласован с evidence/review discipline. | 01 |
| `docs/governance/docs_traceability_matrix.yaml` | REVIEWED | WEAK | Матрица полезна, но отдельные mappings слишком грубы и скрывают multi-checklist ownership (`docs/compliance/*` привязан только к stage25). | 00, 25, 26, 38 |
| `docs/governance/error_budget_policy.md` | REVIEWED | OK | Freeze policy выражена достаточно чётко. | 01 |
| `docs/governance/evidence_policy.md` | REVIEWED | OK | Evidence policy краткая, но достаточно жёсткая как блокирующий закон. | 01, 38 |
| `docs/governance/incident_process.md` | REVIEWED | OK | Incident lifecycle хорошо материализован и уже несёт registry-driven escalation. | 01 |
| `docs/governance/mcp_modes.md` | REVIEWED | OK | Governance-level MCP policy после усиления достаточна, allowlist теперь задан явно. | 01, 33 |
| `docs/governance/observability_gap_registry.md` | REVIEWED | WEAK | Реестр силён по breadth, но сам breadth уже опережает runtime materialization части событий; нужен later parity audit code-vs-registry. | 01, 18, 21, 29, 37 |
| `docs/governance/oncall.md` | REVIEWED | OK | On-call contour после hardening достаточно конкретен и operational. | 01 |
| `docs/governance/postmortem_policy.md` | REVIEWED | OK | Policy сильная, root cause and blameless baseline зафиксированы явно. | 01 |
| `docs/governance/postmortem_template.md` | REVIEWED | WEAK | Шаблон слишком тонкий для зрелого postmortem corpus: не хватает явных секций owner, due dates, evidence refs, corrective validation. | 01 |
| `docs/governance/release_decisions/README.md` | REVIEWED | OK | Каталог решений оформлен достаточно жёстко. | 24, 37 |
| `docs/governance/release_decisions/latest_go_no_go.md` | REVIEWED | WEAK | `latest` решение относится к старому production-candidate baseline и рискует стать stale относительно текущего HEAD/runtime состояния. | 24, 37, 38 |
| `docs/governance/repo_protection_evidence.md` | REVIEWED | OK | Evidence branch protection сильный и после owner-level API проверки стал честным. | 01, 04 |
| `docs/governance/roles_raci.md` | REVIEWED | OK | RACI после усиления достаточно конкретен и operational. | 01 |
| `docs/governance/runbook_policy.md` | REVIEWED | WEAK | Слишком краткий policy: нет требований к evidence, hostile checks, versioning и lifecycle runbook’ов. | 01, 23 |
| `docs/governance/severity.md` | REVIEWED | OK | Severity taxonomy выражена строго и предметно. | 01 |
| `docs/governance/slo_sli.md` | REVIEWED | OK | SLO/SLI baseline чёткий и operationally useful. | 01, 21 |
| `docs/governance/tabletop_exercise.md` | REVIEWED | WEAK | Есть полезные сценарии, но как corpus слишком статичен и не задаёт строгую методику hostile tabletop validation. | 01, 38 |
| `docs/governance/vulnerability_process.md` | REVIEWED | OK | Vulnerability process достаточно чёткий для governance baseline. | 01, 04, 25 |
| `docs/governance/release_process.md` | REVIEWED | MISMATCH | Release process остаётся слишком тонким и уже не соответствует усложнившемуся release/security/provenance/go-no-go контуру проекта. | 01, 24, 37 |

## Слой 9 — Runtime scripts / platform smoke / packs / packaging

> Аудит этого слоя выполнен с обязательным учётом исторического корпуса (`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`): проверялась не только формальная работоспособность, но и материализация утверждённых differentiators, hostile-path, external-source coverage и доказательная ценность runtime evidence.

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `scripts/ci/check_stage32_audit_ux_anti_breakage.sh` | REVIEWED | MISMATCH | Gate запускает browser script, но принимает любой результат, при котором просто появился `stage32_step6_anti_breakage.png`; так как downstream script умеет завершаться `PASS (fallback)` с placeholder PNG, green gate не доказывает реальный anti-breakage browser path. | 32, 38 |
| `scripts/ci/check_stage33_action_ux_anti_breakage.sh` | REVIEWED | MISMATCH | Аналогично stage32: gate считает успехом наличие PNG, а downstream script допускает fallback-green path без реального browser proof. | 33, 38 |
| `tests/platform/contract/run_contract_suite.sh` | REVIEWED | MISMATCH | Contract suite завершает `OK`, даже если `generate_evidence_bundle.sh` создал placeholder-backed natural evidence; suite therefore overstates production readiness. | 24, 37, 38 |
| `tests/platform/contract/check_regart_cross_repo_parity.sh` | REVIEWED | WEAK | Parity опирается на live-download raw GitHub markdown и grep по ключевым словам; нет pinning по commit/tag, нет schema-level diff, нет защиты от content drift/temporary remote outage. | 05, 06, 20, 37 |
| `tests/platform/contract/platform_smoke_lib.sh` | REVIEWED | WEAK | Smoke helpers сильны как базовый runtime check, но доказывают только локальный happy-path Core/Agent по HTTP; не покрывают hostile network, mTLS, relay, backlog replay и agent→core integrated delivery. | 12, 17, 18, 37 |
| `tests/platform/container/run_docker_smoke.sh` | REVIEWED | WEAK | Docker smoke запускает Core и Agent как два независимых контейнера и проверяет их отдельно; не доказывает интегрированную транспортную цепочку Agent→Core, не проверяет hostile container/runtime scenarios и тем самым слабее заявленной topology smoke. | 18, 37 |
| `tests/platform/k8s/run_k8s_smoke.sh` | REVIEWED | WEAK | K8s smoke создаёт minimal deployments/services и again проверяет Core и Agent отдельно; нет RBAC/storage/network-policy/rollout-failure hostile scenarios, нет реального agent→core transport proof внутри кластера. | 18, 23, 37 |
| `scripts/tests/pack_install_runtime.sh` | REVIEWED | MISMATCH | Runtime test считает pack install успешным, пока есть `manifest.yaml`, `payload/` directory и checksum; содержимое payload не верифицируется, поэтому placeholder payload проходит как валидный production pack. | 19, 20, 38 |
| `scripts/tests/packs_runtime.py` | REVIEWED | MISMATCH | Корневая причина ложного успеха pack install: `install_pack_from_dir()` проверяет existence payload dir, entrypoints и manifest signature, но не валидирует payload semantics, schema, runtime assets и external-source coverage claims. | 19, 20, 38 |
| `packs/regart/manifest.yaml` | REVIEWED | WEAK | Manifest слишком минимален для исторически утверждённого pack contour: нет source coverage, supported receivers matrix, evidence/export semantics, security/compliance capabilities и versioned compatibility claims beyond one dependency. | 19, 20, 26, 37 |
| `packs/regart/examples/receivers.toml` | REVIEWED | WEAK | Example ограничен `journald`, `file_tail`, `stdout_stderr`, `net_probe`; это полезно, но уже отстаёт от утверждённого курса на broader external-source coverage (`systemd_unit`, `proc_probe`, `otlp_logs`, segmented transport). | 18, 20, 37 |
| `scripts/tests/agent_receivers_chaos_runtime.sh` | REVIEWED | WEAK | Сценарии permission/parse/redaction полезны, но runtime proof охватывает только subset receiver kinds; отсутствует hostile coverage для `systemd_unit`, `proc_probe`, `otlp_logs`, relay-aware/network-segmented receivers promised by project philosophy. | 18, 37 |
| `scripts/tests/agent_spool_chaos_runtime.sh` | REVIEWED | OK | Kill -9 / spool_full / disk_full / corruption покрыты честно и ближе всего к hostile-runtime philosophy среди agent tests этого слоя. | 17, 37 |
| `scripts/tests/panel0_linux_prod_readiness.sh` | REVIEWED | WEAK | Browser path хороший, но всё ещё содержит fallback-green mode при отсутствии `playwright-cli`; кроме того, bilingual runtime проверяется лишь частично, что уже конфликтует с более жёстким i18n стандартом. | 16, 28, 37 |
| `scripts/tests/console_audio_settings_e2e.sh` | REVIEWED | WEAK | E2E довольно сильный, но не доказывает полный RU parity, не проверяет hostile import/audio asset corruption path, не тестирует policy locks и custom audio against malformed payloads sufficiently. | 28, 35, 40 |
| `docker/core.Dockerfile` | REVIEWED | WEAK | Runtime image теперь non-root и reproducible-friendly, но остаётся слишком аскетичным для зрелого prod contour: нет image metadata/labels, нет explicit healthcheck, не зафиксирована стратегия CA/certs/runtime trust roots. | 04, 37 |
| `docker/agent.Dockerfile` | REVIEWED | WEAK | Та же проблема, что у Core image: skeleton strong as baseline, but not yet full hostile-production container contract. | 04, 18, 37 |
| `systemd/art-vacuum.service` | REVIEWED | MISMATCH | Unit использует `User=%i`, но файл не шаблонный (`art-vacuum.service`, не `art-vacuum@.service`); при запуске через timer `%i` не будет материализован корректно. Это корневой runtime defect, не пойманный текущим stage11 coverage. | 11, 23, 37, 38 |
| `systemd/art-vacuum.timer` | REVIEWED | MISMATCH | Timer ссылается на `Unit=art-vacuum.service`, то есть на неинстанцируемый unit, который одновременно использует `%i`; вместе с service это образует broken scheduled vacuum path. | 11, 23, 37, 38 |

## Слой 10 — Нижние корневые причины найденных runtime-разрывов

> Этот слой отражает не просто симптомы, а нижние причины несоответствий, обнаруженных в слоях 8–9. Аудит выполнен по закону спуска к корню: фиксируется именно то, что делает верхние green-path ложными.

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `scripts/storage_stage11.py` | REVIEWED | MISMATCH | Stage11 runtime basis покрывает SQLite операции и chaos around DB file, но не материализует scheduled systemd path, не порождает `observability_gap.storage_vacuum_failed` и не верифицирует safe scheduled vacuum как интегрированный runtime contour. Верхний stage11 therefore стоит на слишком узком основании. | 11, 23, 37, 38 |
| `scripts/tests/test_storage_stage11.py` | REVIEWED | MISMATCH | Тесты stage11 подтверждают только Python helper semantics; они не тестируют `systemd/art-vacuum.service`, `systemd/art-vacuum.timer` и не могли поймать broken `%i` path. Это корневая причина того, что сломанный unit дошёл до репозитория как будто рабочий. | 11, 38 |
| `scripts/ci/check_storage_stage11_docs.sh` | REVIEWED | MISMATCH | Gate валидирует только наличие RU docs и grep-маркеры, никак не связывая их с реальным systemd runtime path; из-за этого broken vacuum unit остался невидим для CI. | 11, 38 |
| `tests/platform/contract/check_docker_runtime_contract.sh` | REVIEWED | MISMATCH | Contract слишком слаб для заявленного platform/runtime contour: он проверяет только `FROM scratch`, `COPY`, `ENTRYPOINT`, но не healthcheck, labels, trust roots, user/fs invariants и главное — никак не доказывает интегрированную topology `Agent -> Core`. Это корневая причина переоценки platform readiness. | 24, 37, 38 |
| `agent/src/main.rs` | REVIEWED | MISMATCH | Нижний runtime-слой Agent не реализует заявленную модель stage18: доступны только `file_tail`, `journald`, `stdout_stderr`; отсутствуют `systemd_unit`, `proc_probe`, `net_probe`, `otlp_logs`; отсутствует outbound delivery path к Core/relay вообще. Следовательно, многие docs, smoke scripts и transport promises опережают реальный runtime. | 17, 18, 23, 37, 38 |
| `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md` | REVIEWED | MISMATCH | Checklist stage18 уже требует широкий fixed receiver enum и transport topology, но нижний runtime не догоняет этот claim; значит этап в историческом смысле требует reopening не по документам, а по коду. | 18, 38 |
| `tests/platform/contract/platform_smoke_lib.sh` | REVIEWED | MISMATCH | Helper-библиотека платформенных smoke’ов закрепляет раздельный happy-path для Core и Agent и тем самым архитектурно не может доказать заявленную доставку `Agent -> Core`. Это корневая причина слабости Docker/K8s smoke. | 17, 18, 37, 38 |

## Слой 11 — Артефакты и evidence corpus

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `artifacts/platform-evidence/EVIDENCE_NATURAL_TEST_*.txt` | REVIEWED | MISMATCH | Natural-test evidence для большинства дистрибутивов до сих пор `status=placeholder`; такие файлы не могут считаться production-grade evidence и не должны использоваться как proof закрытого platform contour. | 24, 37, 38 |
| `artifacts/platform-evidence/EVIDENCE_DOCKER_REPRODUCIBLE.txt` | REVIEWED | WEAK | Артефакт содержит `status=policy-defined`, то есть фиксирует договорённость, а не результат реального воспроизводимого прогона. Это полезно как policy marker, но не как полноценное evidence. | 04, 24, 37 |
| `artifacts/platform-evidence/EVIDENCE_SBOM.txt` | REVIEWED | WEAK | `status=generated-in-release-pipeline` без привязки к конкретному SBOM-файлу/sha/report означает, что evidence указывает на будущее или внешний pipeline, а не на локально существующий артефакт. | 04, 24, 37 |
| `artifacts/platform-evidence/EVIDENCE_PLATFORM_MATRIX.txt` | REVIEWED | WEAK | `status=generated` с одной ссылкой на source-of-truth недостаточен как доказательство работоспособности матрицы; это marker, но не runtime proof. | 37, 38 |
| `artifacts/vm-smoke/*/plan.txt` | REVIEWED | MISMATCH | VM-артефакты представлены только plan-файлами; при наличии placeholder execute path они не могут использоваться как доказательство реального VM smoke readiness. | 37, 38 |
| `artifacts/regart-parity/report.json` | REVIEWED | WEAK | Report полезен, но зависит от live-download внешнего репозитория без pinning по commit/tag; parity evidence therefore уязвим к drift и remote availability. | 05, 06, 20, 37 |
| `docs/governance/evidence/evidence_ledger.yaml` | REVIEWED | MISMATCH | Ledger по-прежнему содержит `status: closed` для stages 28–38, хотя MASTER и полный аудит уже открыли часть этапов обратно или признали их слабое основание. Это прямой риск ложного provenance и false delivery narrative. | 00, 24, 35, 37, 38 |
| `docs/governance/release_decisions/latest_go_no_go.md` | REVIEWED | MISMATCH | GO/NO-GO sheet привязан к старому `v0.2.0-rc.2-production-candidate` baseline и implicitly assumes previously closed stages as green; после retro-audit это уже не может считаться текущим truth artifact. | 24, 37, 38 |
| `docs/governance/evidence/stage32_step6_anti_breakage.png` | REVIEWED | WEAK | PNG реальный, но его доказательная сила ограничена потому, что upstream gate может получить green через fallback path; screenshot сам по себе не снимает корневую проблему stage32 gate semantics. | 32, 38 |
| `docs/governance/evidence/stage33_step7_action_flow_anti_breakage.png` | REVIEWED | WEAK | Аналогично stage32: screenshot существует и не placeholder, но лежит на слабом gate-path, который допускает fallback-green semantics. | 33, 38 |
| `docs/governance/evidence/branch_protection_main_full.json` | REVIEWED | OK | Owner-level branch protection snapshot остаётся сильным evidence и соответствует текущему hardening baseline. | 01, 04 |
| `docs/governance/evidence/branch_protection_main.png` | REVIEWED | OK | Screenshot branch protection больше не является 1x1 placeholder и согласован с JSON evidence. | 01, 04 |

## Слой 12 — Browser / Level0 / Panel0 runtime layer

> Этот слой проверялся с обязательной опорой на исторический корпус (`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`) и конституцию: `Panel0 resilience`, `one-click-to-evidence`, двуязычие, truthful degraded-mode, browser hostile-runtime и backlog discipline должны быть материализованы не на словах, а в коде, build-пути и тестах.

| Файл | Статус | Класс | Риски/заметки | Checklist impact |
|---|---|---|---|---|
| `browser/package.json` | REVIEWED | WEAK | Пакет определён честно и без лишних зависимостей, но toolchain слишком аскетичен для production-grade browser layer: нет отдельного runtime smoke/build verification beyond local node scripts. | 10, 16, 28 |
| `browser/package-lock.json` | REVIEWED | OK | Lockfile тривиальный, но честный: внешних npm-зависимостей здесь действительно нет. | 04, 10 |
| `browser/scripts/build.mjs` | REVIEWED | MISMATCH | Build path ложный: скрипт просто копирует `src/index.js` в `dist/bundle.js`, не переносит зависимые модули и тем самым создаёт неработоспособный артефакт. Это доказано эксплуатационно: `node dist/bundle.js` падает с `ERR_MODULE_NOT_FOUND` на `./level0_multitab.js`. | 10, 16, 28, 37, 38 |
| `browser/scripts/lint.mjs` | REVIEWED | MISMATCH | Lint покрывает только часть browser surface и вообще не проверяет `panel0.js`, `panel0_sw.js`, `level0.chaos.e2e.test.js`, `panel0.e2e.test.js`, `panel0_i18n_laws.test.js`; broken build path при этом тоже не ловится. | 10, 16, 28, 38 |
| `browser/src/index.js` | REVIEWED | WEAK | Entry layer слишком тонкий и вводит в заблуждение: экспортирует служебный `sum()` для smoke, но не несёт реального browser bootstrap surface. В сочетании со слабым build/test это создаёт ложное ощущение зрелости пакета. | 10, 28, 38 |
| `browser/src/level0_multitab.js` | REVIEWED | MISMATCH | Модель multi-tab полезна, но `_isCorsBlockedError()` классифицирует любой `TypeError` как `observability_gap.cors_blocked`; это смешивает CORS, offline, DNS, TLS и generic fetch failures в один ложный evidence-path и нарушает truth discipline hostile browser runtime. | 10, 14, 16, 28, 38 |
| `browser/src/outbox.js` | REVIEWED | MISMATCH | Browser outbox не имеет durable storage implementation: в пакете присутствует только `InMemoryOutboxStore`, то есть reload/tab crash теряет pending events. Это противоречит backlog/spool philosophy и заявленной устойчивости Level0 при hostile browser conditions. Дополнительно `worker_unavailable` fallback only emits gap and silently continues on main thread without stronger degraded-mode semantics. | 10, 17, 28, 34, 38 |
| `browser/src/panel0.js` | REVIEWED | MISMATCH | RU слой частичный: локализованы только `panel0.core_down` и `panel0.evidence_link`, при этом runtime reasons (`network error`, `unknown`) и часть diagnostics остаются англоязычными. Panel0 также сводит degraded-mode к текстовым причинам, не материализуя richer truthful fallback semantics, ожидаемые историческим корпусом. | 16, 28, 37, 40 |
| `browser/src/panel0_sw.js` | REVIEWED | WEAK | Service worker реализует базовый offline cache, но fallback response слишком примитивен: raw `offline` body, без локализованного/structured degraded payload, без evidence context и без stronger hostile-cache diagnostics. | 16, 28, 37 |
| `browser/test/level0.chaos.e2e.test.js` | REVIEWED | WEAK | Тесты полезны, но не опускаются к корневым hostile-веткам: нет разделения CORS vs offline vs DNS/TLS, нет `BroadcastChannel unavailable`, нет storage corruption/session/localStorage conflict, поэтому текущая ложная `cors_blocked` семантика остаётся незамеченной. | 10, 28, 38 |
| `browser/test/multitab.e2e.test.js` | REVIEWED | WEAK | Покрывает лидерство и dedup happy-path, но не hostile race conditions: concurrent leadership write, stale localStorage corruption, channel loss, tab crash during leadership transfer. | 10, 28, 38 |
| `browser/test/outbox.compression.test.js` | REVIEWED | MISMATCH | Тесты сильны на compression/failure paths, но все построены на `InMemoryOutboxStore`; ни один тест не доказывает durable persistence across reload/crash, хотя именно это требуется backlog/spool philosophy. Следовательно, green suite скрывает фундаментальный runtime gap. | 10, 17, 28, 38 |
| `browser/test/panel0.e2e.test.js` | REVIEWED | WEAK | Проверяет текущую упрощённую семантику Panel0, но не ловит partial RU, не проверяет structured degraded payload, one-click-to-evidence beyond href builder, truth overlay и richer fallback honesty. | 16, 28, 37, 40 |
| `browser/test/panel0_i18n_laws.test.js` | REVIEWED | MISMATCH | i18n law test слишком узок: он подтверждает только 2 строки и поэтому допускает массовую неполноту RU интерфейса. При жёстком проектном законе двуязычия такой green test является ложным основанием. | 16, 28, 38 |
| `browser/test/smoke.test.js` | REVIEWED | MISMATCH | Smoke test на `sum(2,3)` не имеет отношения к реальному browser runtime и не должен существовать как доказательство живости пакета. Это классический false-green marker. | 10, 28, 38 |
