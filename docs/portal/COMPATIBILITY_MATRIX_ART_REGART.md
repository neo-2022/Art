# Compatibility Matrix Art ↔ REGART

## Source of truth (обязательно)
- `docs/INTEGRATION.md`
- `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- `docs/source/checklists/CHECKLIST_20_PACK_REGART.md`

| Art | REGART | Совместимость | Примечание |
|---|---|---|---|
| программа v0.2 (этапы 28..38) | текущий `main` | подтверждается checklist gates | использовать contract parity checks |
| API v1 | стабильный REGART bridge | поддерживается | критерии sunset описаны в документах миграции v2 |
| API v2 | REGART bridge v2 adapters | в rollout | обязательна dual-write verification |
