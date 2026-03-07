# Stage 03 test matrix

Тесты автоматизированы и включены в CI.

| test_id | сценарий | вход | ожидаемый результат | путь | CI |
|---|---|---|---|---|---|
| stage03-profile-switch | profile switch строго по процедуре stop->stop->apply->start->guard->start | `global -> eu`, затем invalid `airgapped` config | валидный switch проходит; invalid config fail closed | `scripts/tests/profile_switch_integration.sh` | `stage03-profile-switch-integration` |
| stage03-airgapped-no-signature | airgapped update без подписи отклоняется | pack без `signatures/pack.sig` | update отклонён | `scripts/tests/airgapped_pack_update_integration.sh` | `stage03-airgapped-update-integration` |
| stage03-airgapped-incompatible | airgapped update при несовместимости отклоняется | signed pack с `compatible_core != 1.x` | update отклонён | `scripts/tests/airgapped_pack_update_integration.sh` | `stage03-airgapped-update-integration` |
| stage03-airgapped-valid | airgapped update проходит при валидных условиях | signed compatible pack | update проходит | `scripts/tests/airgapped_pack_update_integration.sh` | `stage03-airgapped-update-integration` |
| stage03-profile-negative | invalid `profile_id` и invalid guardrails дают `400` + `observability_gap.profile_violation` | `POST /api/v1/profile/apply` с invalid payload | `400`, violation в snapshot/incidents | `scripts/tests/profile_negative_runtime_integration.sh` | `stage03-profile-negative-integration` |
| stage03-unit | unit tests профилей | runtime/unit corpus | профильные unit tests зелёные | `core/src/main.rs` | `stage03-profile-tests` |

Пути тестов автоматизированы:
- `core/src/main.rs` (unit)
- `scripts/tests/profile_switch_integration.sh` (integration)
- `scripts/tests/airgapped_pack_update_integration.sh` (integration)
- `scripts/tests/profile_negative_runtime_integration.sh` (negative integration)

Запуск в CI:
- `stage03-docs-gate`: `bash scripts/ci/check_regional_profiles_stage03.sh`
- `stage03-profile-tests`
- `stage03-profile-switch-integration`: `bash scripts/tests/profile_switch_integration.sh`
- `stage03-airgapped-update-integration`: `bash scripts/tests/airgapped_pack_update_integration.sh`
- `stage03-profile-negative-integration`: `bash scripts/tests/profile_negative_runtime_integration.sh`
