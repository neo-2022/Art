# Delivery Evidence Timeline

## Source of truth
- `docs/governance/evidence/evidence_ledger.yaml`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/governance/evidence/README.md`

## Зачем это клиентам
Этот документ показывает, что проект развивается по реальным проверяемым шагам: каждый закрытый этап связан с артефактами (логи/скриншоты/CI-gates), а не только с текстом в документации.

## Ключевые вехи
| Этап | Дата | Что реализовано | Доказательства |
|---|---|---|---|
| Stage 28 | 2026-03-06 | Console foundation + governance gates | `docs/governance/evidence/stage28_settings_profile_manager.png`, `check_stage28_docs.sh` |
| Stage 29 | 2026-03-06 | DNA Core v2 determinism and contracts | `docs/governance/evidence/stage29_step*.log`, `check_dna_assurance_program.sh` |
| Release governance | 2026-03-06 | Operational `GO/NO-GO` decision trail added to release process | `docs/governance/release_decisions/latest_go_no_go.md`, `check_go_no_go_gate.sh` |
| REGART integration checks | 2026-03-06 | Cross-repo compatibility checks | `tests/platform/contract/check_regart_cross_repo_parity.sh`, `tests/platform/contract/ubuntu_regart_smoke.sh` |

## Как проверить самостоятельно
1. Открыть `docs/governance/evidence/evidence_ledger.yaml`.
2. Выполнить команды из `reproducible_checks` для интересующей записи.
3. Сверить наличие файлов из `evidence_files`.

## Политика прозрачности
- Закрытый этап без evidence-записи считается нарушением process law.
- CI gate `check_evidence_ledger.sh` блокирует такие расхождения.
