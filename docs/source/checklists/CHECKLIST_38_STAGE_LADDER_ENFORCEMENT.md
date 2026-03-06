# CHECKLIST 38 — Stage Ladder Enforcement (Process Gate)
Файл: CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение правил статусов в MASTER, изменение CI policy для последовательности этапов

## Цель
Технически зафиксировать правило “лестницы”: следующий этап нельзя закрывать или запускать как закрытый, пока предыдущий не закрыт.

## Границы
- Включено: автоматическая проверка статусов этапов 28..38 в MASTER + CI gate блокировки.
- Исключено: ручная интерпретация статусов без CI.

## Зависимости
- CHECKLIST 00 (MASTER)
- CHECKLIST 28..37 (все этапы программы v0.2)

## Шаги (строго линейно)
- [x] 1. Сделать: определить machine-checkable ladder rule по таблице `CHECKLIST_00_MASTER_ART_REGART.md`.
  - [x] Проверка (pass/fail): script проверяет, что после первого `[ ]` в диапазоне 28..38 нет ни одного `[x]`.
  - [x] Артефакт результата: `scripts/ci/check_stage_ladder_enforcement.sh`.
- [x] 2. Сделать: привязать ladder script к CI job `stage38-ladder-gate`.
  - [x] Проверка (pass/fail): job присутствует в `.github/workflows/ci.yml` и выполняет script.
  - [x] Артефакт результата: diff workflow + лог job.
- [x] 3. Сделать: enforce правило “этап [x] = в чек-листе нет [ ]”.
  - [x] Проверка (pass/fail): script падает, если в помеченном `[x]` этапе остаются незакрытые пункты.
  - [x] Артефакт результата: negative test output script.
- [x] 4. Сделать: observability-gap контроль process violations.
  - [x] Событие: `observability_gap.checklist_ladder_violation`.
  - [x] evidence_min: `stage`, `previous_stage`, `status_matrix`, `rule`, `trace_id`.
  - [x] action_ref: `docs/runbooks/checklist_ladder_violation.md`.
  - [x] Проверка (pass/fail): registry запись + runbook файл.
  - [x] Артефакт результата: registry/runbook diff.
- [x] 5. Сделать: заблокировать закрытие этапов 29/34/37 при открытых deterministic incidents.
  - [x] Проверка (pass/fail): при активном `observability_gap.dna_determinism_violation` job `stage38-ladder-gate` возвращает FAIL.
  - [x] Артефакт результата: negative gate log.
- [x] 6. Сделать: блокировать переход по лестнице при активном release-blocker из `risk_register_v0_2`.
  - [x] Проверка (pass/fail): stage38 gate возвращает FAIL при `open_determinism_incidents>0` или `open_canary_divergence_incidents>0`.
  - [x] Артефакт результата: runtime incident status + gate log.
- [x] 7. Сделать: enforce evidence-ledger правило для закрытых этапов (клиентская прозрачность прогресса).
  - [x] Проверка (pass/fail): `scripts/ci/check_evidence_ledger.sh` FAIL, если закрытый этап в MASTER не имеет записи и артефактов в `docs/governance/evidence/evidence_ledger.yaml`.
  - [x] Проверка (pass/fail): `scripts/ci/check_stage_ladder_enforcement.sh` включает `check_evidence_ledger.sh`.
  - [x] Артефакт результата: evidence gate log + ledger diff.

## Документация (RU)
- [x] docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md
- [x] docs/ops/stage_ladder_enforcement.md
- [x] docs/governance/evidence/evidence_ledger.yaml
- [x] docs/governance/evidence/README.md
- [x] docs/portal/DELIVERY_EVIDENCE.md
- [x] docs/runbooks/checklist_ladder_violation.md
- [x] docs/source/risk_register_v0_2.md

## Тестирование
- [x] unit: shell script validation for status parsing.
- [x] integration: CI workflow execution.
- [x] e2e: negative scenario (искусственно помеченный поздний этап `[x]` при незакрытом предыдущем) блокируется.
- [x] chaos: ручная попытка обойти ladder через прямое изменение одной строки.
- [x] integration: closed stage without evidence ledger entry блокируется.
- [x] load: не применяется на этапе 38.
- [x] soak: не применяется на этапе 38.

## CI gate
- [x] `stage38-ladder-gate`

## DoD
- [x] Лестница этапов 28..38 enforce в CI автоматически.
- [x] Невозможен merge с нарушением последовательности.
- [x] Невозможен merge закрытого этапа без evidence-записи и реальных артефактов.
- [x] observability-gap событие этапа 38 зарегистрировано и имеет runbook.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: программа v0.2 считается процессно защищённой только после закрытия CHECKLIST_38.
- Артефакты закрытия: script + CI logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
