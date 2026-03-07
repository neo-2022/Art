# Документация Art

## Source of truth
- [Art_v1_spec_final.md](source/Art_v1_spec_final.md)
- [FOUNDATION_CONSTITUTION_V0_2.md](source/FOUNDATION_CONSTITUTION_V0_2.md)
- [CHECKLIST_00_MASTER_ART_REGART.md](source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- [source/README.md](source/README.md)

Этот каталог — публичная и операционная точка входа в документацию `Art`.

Он не заменяет канон в `docs/source/*`, а организует навигацию, эксплуатационные документы, release-процесс, evidence и интеграцию.

## С чего начать
- корень репозитория: [README.md](../README.md)
- канонический foundation: [FOUNDATION_CONSTITUTION_V0_2.md](source/FOUNDATION_CONSTITUTION_V0_2.md)
- мастер-чек-лист: [CHECKLIST_00_MASTER_ART_REGART.md](source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- портал документации: [INDEX.md](portal/INDEX.md)

## Foundation И История Замысла
- модель работы AI-команды: [AI_ENGINEERING_OPERATING_MODEL.md](foundation/AI_ENGINEERING_OPERATING_MODEL.md)
- backlog продвинутой автоматизации: [ADVANCED_AUTOMATION_BACKLOG.md](foundation/ADVANCED_AUTOMATION_BACKLOG.md)
- корпус концепций и истории проекта: [PROJECT_HISTORY_AND_CONCEPTS.md](foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- backlog революционных гипотез: [revolutionary_hypotheses.md](foundation/revolutionary_hypotheses.md)
- radar перспективных технологий: [frontier_tech_radar.md](foundation/frontier_tech_radar.md)
- lens audit report: [lens_audit_report.md](foundation/lens_audit_report.md)

## Корень Дерева Решений
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`

Эти документы задают корневой смысл и законы проекта. Их изменение без синхронного обновления зависимого контура запрещено.

Machine-readable карта зависимостей:
- `../formats/root_decision_tree_dependencies.yaml`

Автоматический контроль:
- `scripts/ci/check_root_decision_tree_sync.sh`

## Основные разделы

### Продукт и архитектура
- обзор архитектуры: [ARCHITECTURE.md](ARCHITECTURE.md)
- интеграция с REGART: [INTEGRATION.md](INTEGRATION.md)
- product guarantees: [PRODUCT_GUARANTEES.md](portal/PRODUCT_GUARANTEES.md)
- security posture: [SECURITY_POSTURE.md](portal/SECURITY_POSTURE.md)

### Эксплуатация и production readiness
- platform support: [platform-support.md](ops/platform-support.md)
- runtime compatibility: [platform-runtime-compatibility-matrix.md](ops/platform-runtime-compatibility-matrix.md)
- VM testing: [platform-vm-testing.md](ops/platform-vm-testing.md)
- Docker и Kubernetes testing: [platform-container-k8s-testing.md](ops/platform-container-k8s-testing.md)
- GO/NO-GO template: [go_no_go_template.md](ops/go_no_go_template.md)
- remediation plan для очередей GitHub Actions: [github_actions_queue_remediation_plan.md](ops/github_actions_queue_remediation_plan.md)

### Release и клиентская коммуникация
- release process: [release_process.md](release/release_process.md)
- versioning: [versioning.md](release/versioning.md)
- compatibility matrix: [compat_matrix.md](release/compat_matrix.md)
- лента delivery evidence: [DELIVERY_EVIDENCE.md](portal/DELIVERY_EVIDENCE.md)

### Governance и evidence
- evidence policy: [evidence_policy.md](governance/evidence_policy.md)
- observability gap registry: [observability_gap_registry.md](governance/observability_gap_registry.md)
- evidence ledger: [evidence_ledger.yaml](governance/evidence/evidence_ledger.yaml)
- release decisions: [governance/release_decisions/](governance/release_decisions)

### Канон и программа выполнения
- index исходников: [source/README.md](source/README.md)
- index чек-листов: [source/checklists/README.md](source/checklists/README.md)
- risk register: [risk_register_v0_2.md](source/risk_register_v0_2.md)
- DNA assurance standard: [dna_core_determinism_performance_assurance.md](source/dna_core_determinism_performance_assurance.md)
- закон hostile-environment проверки: [production_adversarial_validation_law.md](testing/production_adversarial_validation_law.md)
- аудит силы тестового корпуса: [test_system_audit_v0_2.md](testing/test_system_audit_v0_2.md)

## Языковая политика
- нормативный язык документации: русский
- дополнительные языковые зеркала могут существовать только как вспомогательный слой
- source-of-truth и release-critical документы ведутся на русском

## Модель авторитета

Уровни документации:
- `docs/source/*` — канон
- `docs/source/checklists/*` — программа исполнения и верификации
- `docs/*.md`, `docs/*/*.md` — рабочие и операционные документы
- `docs/portal/*` — презентационный и навигационный слой

Рабочие документы не имеют права переопределять контракты или противоречить канону.
