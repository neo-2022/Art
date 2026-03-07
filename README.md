# Art

> Evidence-first Incident OS для воспроизводимой эксплуатации, детерминированного расследования и верифицируемого release governance.

## Кратко

`Art` — это единый продукт в одном монорепозитории, который объединяет:
- `art-core` — Rust-ядро для ingest, snapshot, stream, actions и audit
- `art-agent` — Rust-агент для сбора и надёжной доставки сигналов
- `Panel0` — встроенный аварийный интерфейс внутри Core
- `Art Console` — основной операционный интерфейс расследования и навигации по evidence

Репозиторий ведётся по модели `docs-first`:
- правила и инварианты зафиксированы в каноне
- выполнение идёт по чек-листам
- закрытие этапов подтверждается проверками и артефактами
- релизные решения оформляются через `GO/NO-GO`

## Текущее состояние

| Параметр | Значение |
|---|---|
| Ветка-источник истины | `main` |
| Текущий baseline | `v0.2.0-rc.2` |
| Статус релиза | production candidate, `NO-GO` до доказательства protective contours |
| Активный corrective baseline | `DEF-001 -> stage11 (durable Core storage/recovery, live corruption/read_only contour, live kill -9 during ingest chaos и storage pressure / disk exhaustion contour уже materialized; локально открытыми остаются 11.3 concurrency proof и 11.4 VACUUM/systemd production-proof)` |
| Следующие structural defects в стволе | `DEF-017` high-risk monolith decomposition, `DEF-018` hostile e2e depth hardening, `DEF-019/020` trust boundary и browser surface hardening |
| Execute-gated платформы | Ubuntu native, Docker runtime, Kubernetes runtime |
| Расширенная Linux-матрица | validate-only до включения выделенных runner'ов |

Ключевые документы:
- текущий decision record: [latest_go_no_go.md](docs/governance/release_decisions/latest_go_no_go.md)
- release checklist: [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- changelog: [CHANGELOG.md](CHANGELOG.md)
- лента доказательств прогресса: [DELIVERY_EVIDENCE.md](docs/portal/DELIVERY_EVIDENCE.md)
- активная дефектовочная контрольная строка: [defect_remediation_control_matrix_v0_2.md](docs/testing/defect_remediation_control_matrix_v0_2.md)
- дефектовочная лестница: [defect_remediation_ladder_v0_2.md](docs/testing/defect_remediation_ladder_v0_2.md)
- в активной defect-строке `DEF-001` storage pressure contour для `stage11` уже материализован; cross-stage continuation по этому защитному контуру остаётся в `12/24/37`
- baseline ingress/perimeter защиты: [ingress_perimeter_protection_v0_2.md](docs/source/ingress_perimeter_protection_v0_2.md)
- baseline trust boundary hardening: [trust_boundary_hardening_v0_2.md](docs/source/trust_boundary_hardening_v0_2.md)
- baseline browser surface hardening: [browser_surface_hardening_v0_2.md](docs/source/browser_surface_hardening_v0_2.md)
- baseline storage pressure protection: [storage_pressure_protection_v0_2.md](docs/source/storage_pressure_protection_v0_2.md)
- baseline startup config fail-closed: [startup_config_safety_validator_v0_2.md](docs/source/startup_config_safety_validator_v0_2.md)
- baseline queue integrity protection: [queue_integrity_protection_v0_2.md](docs/source/queue_integrity_protection_v0_2.md)
- baseline guard self-observability: [guard_self_observability_v0_2.md](docs/source/guard_self_observability_v0_2.md)
- baseline monolith budget guard: [monolith_budget_guard_v0_2.md](docs/source/monolith_budget_guard_v0_2.md)
- pinned external adversarial harness for REGART and partner-exposed proof: [regart_adversarial_integration_harness_v0_2.md](docs/source/regart_adversarial_integration_harness_v0_2.md)
- baseline connected system visibility: [connected_system_visibility_v0_2.md](docs/source/connected_system_visibility_v0_2.md)
- buyer due diligence triage: [buyer_due_diligence_signal_triage_v0_2.md](docs/testing/buyer_due_diligence_signal_triage_v0_2.md)

## Что такое Art

Art — это не набор дашбордов и не “чат поверх логов”.

Art проектируется как `Incident OS`, где:
- `Core` является единственным источником истины
- ничего не считается достоверным без evidence
- `Event DNA` является первоклассным объектом группировки и навигации
- расследования воспроизводимы
- аудит неизменяем и проверяем
- аварийный и degraded путь встроены в архитектуру продукта

## Архитектура продукта

### Tier A: Panel0
- встроен в `art-core`
- не зависит от runtime-файловой системы для ассетов
- автоматически подхватывает отказ Console
- остаётся последним операционным рубежом

### Tier B: Art Console
- находится в `apps/console-web`
- использует только контракты Core и workspace-пакеты
- покрывает Command Center, Event River, Incident Room, Audit Explorer, Investigation Library и Flow Mode

### Tier C: SaaS Readiness
- tenant isolation
- квоты, retention и compliance-контур
- единые законы для self-hosted и SaaS-режима

## Структура репозитория

| Путь | Назначение |
|---|---|
| `core/` | Rust Core |
| `agent/` | Rust Agent |
| `browser/` | Browser Level0 и код поддержки Panel0 |
| `apps/console-web/` | приложение Tier B Console |
| `packages/` | общие пакеты Console |
| `tests/` | интеграционные, runtime, platform и contract suites |
| `scripts/` | CI-gates и служебные скрипты |
| `formats/` | machine-readable source-of-truth |
| `docs/` | документация, runbooks, release, ops, evidence |

## Источники истины

Основные документы:
- спецификация продукта: [Art_v1_spec_final.md](docs/source/Art_v1_spec_final.md)
- Foundation / Constitution: [FOUNDATION_CONSTITUTION_V0_2.md](docs/source/FOUNDATION_CONSTITUTION_V0_2.md)
- мастер-чек-лист: [CHECKLIST_00_MASTER_ART_REGART.md](docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- stage ladder: [CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md](docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md)
- risk register: [risk_register_v0_2.md](docs/source/risk_register_v0_2.md)
- DNA assurance standard: [dna_core_determinism_performance_assurance.md](docs/source/dna_core_determinism_performance_assurance.md)
- ingress/perimeter protection standard: [ingress_perimeter_protection_v0_2.md](docs/source/ingress_perimeter_protection_v0_2.md)
- trust boundary hardening standard: [trust_boundary_hardening_v0_2.md](docs/source/trust_boundary_hardening_v0_2.md)
- browser surface hardening standard: [browser_surface_hardening_v0_2.md](docs/source/browser_surface_hardening_v0_2.md)
- protective safeguards catalog: [protective_safeguards_catalog_v0_2.md](docs/source/protective_safeguards_catalog_v0_2.md)
- storage pressure protection standard: [storage_pressure_protection_v0_2.md](docs/source/storage_pressure_protection_v0_2.md)
- startup configuration fail-closed standard: [startup_config_safety_validator_v0_2.md](docs/source/startup_config_safety_validator_v0_2.md)
- queue integrity protection standard: [queue_integrity_protection_v0_2.md](docs/source/queue_integrity_protection_v0_2.md)
- guard self-observability standard: [guard_self_observability_v0_2.md](docs/source/guard_self_observability_v0_2.md)
- connected system visibility standard: [connected_system_visibility_v0_2.md](docs/source/connected_system_visibility_v0_2.md)
- корневой индекс документации: [docs/README.md](docs/README.md)

## Контракты и API

Этот раздел сохраняет совместимость с историческим `Stage 08` docs-gate и остаётся публичной точкой входа в контрактный слой.

- OpenAPI v1: [docs/api/openapi.yaml](docs/api/openapi.yaml)
- API v2 contracts: [docs/contracts/v2/openapi.yaml](docs/contracts/v2/openapi.yaml)
- схемы: [docs/contracts/v2/schemas/](docs/contracts/v2/schemas)
- platform support contract: [formats/platform_support.yaml](formats/platform_support.yaml)

### Contracts
- `Stage 08` зафиксировал обязательный контрактный baseline репозитория.
- `OpenAPI` используется как публичный API-контракт.
- `JSON Schema` используется как машинно-проверяемый формат контрактов и payload-моделей.

## Platform Readiness

- platform support: [platform-support.md](docs/ops/platform-support.md)
- runtime compatibility: [platform-runtime-compatibility-matrix.md](docs/ops/platform-runtime-compatibility-matrix.md)
- VM testing: [platform-vm-testing.md](docs/ops/platform-vm-testing.md)
- Docker/Kubernetes testing: [platform-container-k8s-testing.md](docs/ops/platform-container-k8s-testing.md)
- certified profile: [fstec-certified-profile.md](docs/security/fstec-certified-profile.md)

## Release Governance

- release process: [release_process.md](docs/release/release_process.md)
- versioning: [versioning.md](docs/release/versioning.md)
- compatibility matrix: [compat_matrix.md](docs/release/compat_matrix.md)
- GO/NO-GO template: [go_no_go_template.md](docs/ops/go_no_go_template.md)
- release blockers по защитным контурам:
  - trust boundary hardening: [trust_boundary_hardening_v0_2.md](docs/source/trust_boundary_hardening_v0_2.md)
  - browser surface hardening: [browser_surface_hardening_v0_2.md](docs/source/browser_surface_hardening_v0_2.md)
  - ingress/perimeter protection: [ingress_perimeter_protection_v0_2.md](docs/source/ingress_perimeter_protection_v0_2.md)
  - storage pressure protection: [storage_pressure_protection_v0_2.md](docs/source/storage_pressure_protection_v0_2.md)
  - startup config fail-closed: [startup_config_safety_validator_v0_2.md](docs/source/startup_config_safety_validator_v0_2.md)
  - queue integrity protection: [queue_integrity_protection_v0_2.md](docs/source/queue_integrity_protection_v0_2.md)
  - guard self-observability: [guard_self_observability_v0_2.md](docs/source/guard_self_observability_v0_2.md)

## Прогресс и доказательства

Развитие проекта подтверждается артефактами, а не обещаниями:
- лента доказательств: [DELIVERY_EVIDENCE.md](docs/portal/DELIVERY_EVIDENCE.md)
- evidence ledger: [evidence_ledger.yaml](docs/governance/evidence/evidence_ledger.yaml)
- каталог evidence: [docs/governance/evidence/](docs/governance/evidence)

## Навигация

- корень документации: [docs/README.md](docs/README.md)
- исторический корпус концепций: [PROJECT_HISTORY_AND_CONCEPTS.md](docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- AI operating model: [AI_ENGINEERING_OPERATING_MODEL.md](docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md)
- advanced automation backlog: [ADVANCED_AUTOMATION_BACKLOG.md](docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md)
- visual language: [ART_VISUAL_LANGUAGE.md](docs/portal/ART_VISUAL_LANGUAGE.md)
- портал: [docs/portal/INDEX.md](docs/portal/INDEX.md)
- дерево документации с каталоговыми узлами, line-count контролем и сигналами рассинхрона: [docs/portal/DOCUMENTATION_TREE.md](docs/portal/DOCUMENTATION_TREE.md)
- source docs: [docs/source/README.md](docs/source/README.md)
- index чек-листов: [docs/source/checklists/README.md](docs/source/checklists/README.md)

## Интеграция с REGART

Art и REGART — отдельные кодовые базы с контрактной интеграцией.

Ссылки:
- план интеграции: [docs/INTEGRATION.md](docs/INTEGRATION.md)
- pinned external adversarial harness: [regart_adversarial_integration_harness_v0_2.md](docs/source/regart_adversarial_integration_harness_v0_2.md)
- внешний репозиторий REGART: `https://github.com/neo-2022/my_langgraph_agent`

## Безопасность

Политика безопасности: [SECURITY.md](SECURITY.md)

Дополнительно:
- ingress/perimeter baseline: [ingress_perimeter_protection_v0_2.md](docs/source/ingress_perimeter_protection_v0_2.md)
- trust boundary hardening baseline: [trust_boundary_hardening_v0_2.md](docs/source/trust_boundary_hardening_v0_2.md)
- browser surface hardening baseline: [browser_surface_hardening_v0_2.md](docs/source/browser_surface_hardening_v0_2.md)
- runtime runbook при подозрении на DDoS: [ddos_suspected.md](docs/runbooks/ddos_suspected.md)
- runbook деградации ingress shield: [ingress_shield_degraded.md](docs/runbooks/ingress_shield_degraded.md)
- runbook нарушения trust boundary: [trust_boundary_violation.md](docs/runbooks/trust_boundary_violation.md)
- runbook деградации browser surface policy: [browser_surface_policy_degraded.md](docs/runbooks/browser_surface_policy_degraded.md)

## Лицензия

Частная собственность.  
Статус лицензии: `All rights reserved / UNLICENSED`.

Копирование, распространение и использование без явного письменного разрешения запрещены.
