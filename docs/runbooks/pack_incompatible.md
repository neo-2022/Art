# Runbook: pack_incompatible

## mitigations
1. Проверить `core_version` и `core_version_range` в manifest pack.
2. Обновить Core до совместимой версии или выбрать совместимый pack.
3. Повторить install после выравнивания версий.

## verification
- install проходит успешно;
- событие `observability_gap.pack_incompatible` больше не генерируется.
