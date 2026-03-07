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
- графическое дерево документации с каталоговыми узлами, подсчётом строк и контролем рассинхрона: [DOCUMENTATION_TREE.md](portal/DOCUMENTATION_TREE.md)

## Foundation И История Замысла
- модель работы AI-команды: [AI_ENGINEERING_OPERATING_MODEL.md](foundation/AI_ENGINEERING_OPERATING_MODEL.md)
- backlog продвинутой автоматизации: [ADVANCED_AUTOMATION_BACKLOG.md](foundation/ADVANCED_AUTOMATION_BACKLOG.md)
- корпус концепций и истории проекта: [PROJECT_HISTORY_AND_CONCEPTS.md](foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- threat model appendix как часть исторического канона: [PROJECT_HISTORY_AND_CONCEPTS.md](foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- универсальный шаблон идеологии построения проекта: [UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md](foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md)
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

Ствол дерева решений:
- полный аудит
- дефектовочная контрольная ведомость
- дефектовочная лестница remediation
- `MASTER`

`MASTER` завершает ствол и управляет кроной проекта, а corrective-порядок получает от предыдущего слоя ствола.

## Основные разделы

### Продукт и архитектура
- обзор архитектуры: [ARCHITECTURE.md](ARCHITECTURE.md)
- интеграция с REGART: [INTEGRATION.md](INTEGRATION.md)
- pinned external hostile harness для REGART: [regart_adversarial_integration_harness_v0_2.md](source/regart_adversarial_integration_harness_v0_2.md)
- connected system visibility baseline: [connected_system_visibility_v0_2.md](source/connected_system_visibility_v0_2.md)
- product guarantees: [PRODUCT_GUARANTEES.md](portal/PRODUCT_GUARANTEES.md)
- security posture: [SECURITY_POSTURE.md](portal/SECURITY_POSTURE.md)

### Эксплуатация и production readiness
- platform support: [platform-support.md](ops/platform-support.md)
- runtime compatibility: [platform-runtime-compatibility-matrix.md](ops/platform-runtime-compatibility-matrix.md)
- VM testing: [platform-vm-testing.md](ops/platform-vm-testing.md)
- Docker и Kubernetes testing: [platform-container-k8s-testing.md](ops/platform-container-k8s-testing.md)
- GO/NO-GO template: [go_no_go_template.md](ops/go_no_go_template.md)
- remediation plan для очередей GitHub Actions: [github_actions_queue_remediation_plan.md](ops/github_actions_queue_remediation_plan.md)
- storage pressure baseline: [storage_pressure_protection_v0_2.md](source/storage_pressure_protection_v0_2.md)
- startup config fail-closed baseline: [startup_config_safety_validator_v0_2.md](source/startup_config_safety_validator_v0_2.md)
- queue integrity baseline: [queue_integrity_protection_v0_2.md](source/queue_integrity_protection_v0_2.md)
- guard self-observability baseline: [guard_self_observability_v0_2.md](source/guard_self_observability_v0_2.md)

Текущее состояние corrective-baseline:
- в `DEF-001 -> stage11` уже materialized:
  - durable SQLite basement;
  - corruption -> restore -> read_only contour;
  - live `kill -9 during ingest` chaos;
  - live `storage pressure / disk exhaustion` contour;
- локальными незакрытыми пунктами `stage11` остаются:
  - `11.3` concurrency proof как stage-level closure evidence;
  - `11.4` production-proof `VACUUM/systemd`.

### Release и клиентская коммуникация
- release process: [release_process.md](release/release_process.md)
- versioning: [versioning.md](release/versioning.md)
- compatibility matrix: [compat_matrix.md](release/compat_matrix.md)
- лента delivery evidence: [DELIVERY_EVIDENCE.md](portal/DELIVERY_EVIDENCE.md)
- trust boundary hardening baseline: [trust_boundary_hardening_v0_2.md](source/trust_boundary_hardening_v0_2.md)
- browser surface hardening baseline: [browser_surface_hardening_v0_2.md](source/browser_surface_hardening_v0_2.md)
- pinned external adversarial harness baseline: [regart_adversarial_integration_harness_v0_2.md](source/regart_adversarial_integration_harness_v0_2.md)
- connected system visibility baseline: [connected_system_visibility_v0_2.md](source/connected_system_visibility_v0_2.md)
- единый каталог предохранителей: [protective_safeguards_catalog_v0_2.md](source/protective_safeguards_catalog_v0_2.md)
- обзор threat model для клиента и аудитора: [PROJECT_HISTORY_AND_CONCEPTS.md](foundation/PROJECT_HISTORY_AND_CONCEPTS.md)

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
- ingress/perimeter protection baseline: [ingress_perimeter_protection_v0_2.md](source/ingress_perimeter_protection_v0_2.md)
- закон hostile-environment проверки: [production_adversarial_validation_law.md](testing/production_adversarial_validation_law.md)
- аудит силы тестового корпуса: [test_system_audit_v0_2.md](testing/test_system_audit_v0_2.md)
- дефектовочная контрольная ведомость управляет corrective-отработкой поштучно: [defect_remediation_control_matrix_v0_2.md](testing/defect_remediation_control_matrix_v0_2.md)
- дефектовочная лестница задаёт последовательность исправления от нижнего слоя вверх: [defect_remediation_ladder_v0_2.md](testing/defect_remediation_ladder_v0_2.md)

## Языковая политика
- нормативный язык документации: русский
- дополнительные языковые зеркала могут существовать только как вспомогательный слой
- source-of-truth и release-critical документы ведутся на русском

## Принцип понятности документации
- Документация Art должна читаться не только автором решения, но и новым инженером, оператором, аудитором и не специалистом.
- Почти все документы обязаны простым языком объяснять:
  - что это за сущность или механизм;
  - зачем он нужен;
  - как он работает;
  - какие ограничения и риски у него есть.
- Сложные термины, англоязычные слова, сокращения и внутренние обозначения должны сопровождаться пояснением или переводом.
- Документ считается недостаточным, если он требует угадывать контекст, знает ответы только "в голове автора" или не объясняет причин выбора.

## Модель авторитета

Уровни документации:
- `docs/source/*` — канон
- `docs/source/checklists/*` — программа исполнения и верификации
- `docs/*.md`, `docs/*/*.md` — рабочие и операционные документы
- `docs/portal/*` — презентационный и навигационный слой

Рабочие документы не имеют права переопределять контракты или противоречить канону.
