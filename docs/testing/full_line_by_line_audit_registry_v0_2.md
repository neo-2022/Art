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
