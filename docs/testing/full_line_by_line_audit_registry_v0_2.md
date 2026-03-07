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
