# Stage 03 test matrix

Тесты автоматизированы и включены в CI.

- profile switch строго по процедуре stop->stop->apply->start->guard->start
- airgapped update без подписи отклоняется
- airgapped update при несовместимости отклоняется
- profile violation генерирует `observability_gap.profile_violation`
- пути тестов: `core/src/main.rs` (unit), `scripts/tests/profile_switch_integration.sh` (integration), `scripts/tests/airgapped_pack_update_integration.sh` (integration)
- запуск в CI: `stage03-docs-gate`, `stage03-profile-tests`, `stage03-profile-switch-integration`, `stage03-airgapped-update-integration`
