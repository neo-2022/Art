# Портал Документации Art

## Source of truth
- [README.md](../README.md)
- [FOUNDATION_CONSTITUTION_V0_2.md](../source/FOUNDATION_CONSTITUTION_V0_2.md)
- [CHECKLIST_00_MASTER_ART_REGART.md](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- [INTEGRATION.md](../INTEGRATION.md)

Этот портал является презентационным и навигационным слоем над каноном.  
Его задача — быстро объяснить систему, не ослабляя реальные правила проекта.

## Быстрые Пути

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

### Governance
- Delivery evidence: [DELIVERY_EVIDENCE.md](./DELIVERY_EVIDENCE.md)
- Security posture: [SECURITY_POSTURE.md](./SECURITY_POSTURE.md)
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
