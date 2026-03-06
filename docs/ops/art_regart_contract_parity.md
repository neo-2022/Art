# Art <-> REGART Contract Parity Report

Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- External REGART SoT:
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
  - `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`
- Runtime parity checker: `tests/platform/contract/check_regart_cross_repo_parity.sh`

Последняя актуализация: 2026-03-06
Статус: ACTIVE

## Цель
Подтверждать совместимость обязательных контрактов между Art (`docs/contracts/v2/*`) и REGART source-of-truth, чтобы изменения в одном репозитории не ломали интеграционный контур второго.

## Обязательные проверки
1. REGART external documents доступны и валидно загружаются.
2. CHECKLIST 05 и 06 в Art содержат ссылки на внешние source-of-truth документы REGART.
3. Базовые contract anchors присутствуют в внешних документах (`debugger`, `integration`, `tls/https`).
4. По результату формируется evidence-артефакт `artifacts/regart-parity/report.json`.

## Формат отчёта parity runner
- `verification_date`
- `art_commit`
- `regart_ref`
- `checks.ui_graph_run_debugger_sha256`
- `checks.bridge_integration_sha256`
- `parity_result`
- `mismatches[]`

## CI привязка
- `stage37-linux-hardening-gate`
- `platform-matrix-contract-gate`

## Последний прогон
Последний прогон хранится в артефакте CI `artifacts/regart-parity/report.json` и обновляется при каждом запуске parity-checker.
