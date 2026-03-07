# Портал Документации Art

## Source of truth
- [README.md](../README.md)
- [FOUNDATION_CONSTITUTION_V0_2.md](../source/FOUNDATION_CONSTITUTION_V0_2.md)
- [CHECKLIST_00_MASTER_ART_REGART.md](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- [INTEGRATION.md](../INTEGRATION.md)
- [PROJECT_HISTORY_AND_CONCEPTS.md](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- `../../formats/root_decision_tree_dependencies.yaml`

Этот портал является презентационным и навигационным слоем над каноном.  
Его задача — быстро объяснить систему, не ослабляя реальные правила проекта.

## Быстрые Пути

### Foundation
- AI operating model: [AI_ENGINEERING_OPERATING_MODEL.md](../foundation/AI_ENGINEERING_OPERATING_MODEL.md)
- Advanced automation backlog: [ADVANCED_AUTOMATION_BACKLOG.md](../foundation/ADVANCED_AUTOMATION_BACKLOG.md)
- История и корпус концепций: [PROJECT_HISTORY_AND_CONCEPTS.md](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- Революционные гипотезы: [revolutionary_hypotheses.md](../foundation/revolutionary_hypotheses.md)
- Radar технологий: [frontier_tech_radar.md](../foundation/frontier_tech_radar.md)

### Корневое дерево решений
- Графическое дерево документации с каталоговыми узлами и контролем строк: [DOCUMENTATION_TREE.md](./DOCUMENTATION_TREE.md)
- Корневой закон: [FOUNDATION_CONSTITUTION_V0_2.md](../source/FOUNDATION_CONSTITUTION_V0_2.md)
- Исторический корпус: [PROJECT_HISTORY_AND_CONCEPTS.md](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md)
- Базовый предметный spec: [Art_v1_spec_final.md](../source/Art_v1_spec_final.md)
- Корневой интеграционный spec: [REGART -  LangGraph  взаимодействие с Art описание.md](../source/REGART -  LangGraph  взаимодействие с Art описание.md)
- Дефектовочная лестница: [defect_remediation_ladder_v0_2.md](../testing/defect_remediation_ladder_v0_2.md)

### Продукт
- Архитектура: [ARCHITECTURE.md](../ARCHITECTURE.md)
- Интеграция: [INTEGRATION.md](../INTEGRATION.md)
- Глоссарий: [GLOSSARY.md](./GLOSSARY.md)
- Гарантии продукта: [PRODUCT_GUARANTEES.md](./PRODUCT_GUARANTEES.md)

### Эксплуатация
- Поддержка платформ: [platform-support.md](../ops/platform-support.md)
- VM-тестирование: [platform-vm-testing.md](../ops/platform-vm-testing.md)
- Docker и Kubernetes: [platform-container-k8s-testing.md](../ops/platform-container-k8s-testing.md)
- GO/NO-GO шаблон: [go_no_go_template.md](../ops/go_no_go_template.md)
- План устранения очередей GitHub Actions: [github_actions_queue_remediation_plan.md](../ops/github_actions_queue_remediation_plan.md)

### Governance
- Visual language: [ART_VISUAL_LANGUAGE.md](./ART_VISUAL_LANGUAGE.md)
- Delivery evidence: [DELIVERY_EVIDENCE.md](./DELIVERY_EVIDENCE.md)
- Buyer due diligence triage: [buyer_due_diligence_signal_triage_v0_2.md](../testing/buyer_due_diligence_signal_triage_v0_2.md)
- Security posture: [SECURITY_POSTURE.md](./SECURITY_POSTURE.md)
- Ingress / perimeter protection baseline: [ingress_perimeter_protection_v0_2.md](../source/ingress_perimeter_protection_v0_2.md)
- Матрица совместимости Art↔REGART: [COMPATIBILITY_MATRIX_ART_REGART.md](./COMPATIBILITY_MATRIX_ART_REGART.md)
- Модель авторитета документов: [DOC_AUTHORITY.md](./DOC_AUTHORITY.md)
- Стиль документации: [DOC_STYLE_GUIDE.md](./DOC_STYLE_GUIDE.md)

## Интеграция С REGART
- Быстрый старт: [INTEGRATION.md](../INTEGRATION.md)
- Контракты и API: [openapi.yaml](../api/openapi.yaml), [openapi.yaml](../contracts/v2/openapi.yaml)
- Actions и control plane: [secure_actions_protocol_v2.md](../source/secure_actions_protocol_v2.md)
- Troubleshooting: [art_bridge_runbook.md](../regart/art_bridge_runbook.md)

## Маршрутизация Языка
- основной путь: `/docs/`
- служебный английский слой: `/docs/en/`
- UI-маршрутизация должна учитывать `ui_locale`, но нормативный контур документации ведётся на русском
