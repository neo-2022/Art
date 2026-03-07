# CHECKLIST 38 — Stage Ladder Enforcement (Process Gate)
Файл: CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md
Последняя актуализация: 2026-03-06
Дата последней проверки: 2026-03-06
Триггер пересмотра: изменение правил статусов в MASTER, изменение CI policy для последовательности этапов

## Цель
Технически зафиксировать правило “лестницы”: следующий этап нельзя закрывать или запускать как закрытый, пока предыдущий не закрыт.

## Границы
- Включено: автоматическая проверка статусов этапов 28..45 в MASTER + CI gate блокировки.
- Исключено: ручная интерпретация статусов без CI.

## Зависимости
- CHECKLIST 00 (MASTER)
- CHECKLIST 28..45 (все этапы программы v0.2 и continuation backlog)

## Шаги (строго линейно)
- [ ] 1. Сделать: определить machine-checkable ladder rule по таблице `CHECKLIST_00_MASTER_ART_REGART.md`.
  - [ ] Проверка (pass/fail): script проверяет, что после первого `[ ]` в диапазоне 28..45 нет ни одного `[x]`.
  - [ ] Артефакт результата: `scripts/ci/check_stage_ladder_enforcement.sh`.
- [ ] 2. Сделать: привязать ladder script к CI job `stage38-ladder-gate`.
  - [ ] Проверка (pass/fail): job присутствует в `.github/workflows/ci.yml` и выполняет script.
  - [ ] Артефакт результата: diff workflow + лог job.
- [ ] 3. Сделать: enforce правило “этап [x] = в чек-листе нет [ ]”.
  - [ ] Проверка (pass/fail): script падает, если в помеченном `[x]` этапе остаются незакрытые пункты.
  - [ ] Артефакт результата: negative test output script.
- [ ] 4. Сделать: observability-gap контроль process violations.
  - [ ] Событие: `observability_gap.checklist_ladder_violation`.
  - [ ] evidence_min: `stage`, `previous_stage`, `status_matrix`, `rule`, `trace_id`.
  - [ ] action_ref: `docs/runbooks/checklist_ladder_violation.md`.
  - [ ] Проверка (pass/fail): registry запись + runbook файл.
  - [ ] Артефакт результата: registry/runbook diff.
- [ ] 5. Сделать: заблокировать закрытие этапов 29/34/37 при открытых deterministic incidents.
  - [ ] Проверка (pass/fail): при активном `observability_gap.dna_determinism_violation` job `stage38-ladder-gate` возвращает FAIL.
  - [ ] Артефакт результата: negative gate log.
- [ ] 6. Сделать: блокировать переход по лестнице при активном release-blocker из `risk_register_v0_2`.
  - [ ] Проверка (pass/fail): stage38 gate возвращает FAIL при `open_determinism_incidents>0` или `open_canary_divergence_incidents>0`.
  - [ ] Артефакт результата: runtime incident status + gate log.
- [ ] 7. Сделать: enforce evidence-ledger правило для закрытых этапов (клиентская прозрачность прогресса).
  - [ ] Проверка (pass/fail): `scripts/ci/check_evidence_ledger.sh` FAIL, если закрытый этап в MASTER не имеет записи и артефактов в `docs/governance/evidence/evidence_ledger.yaml`.
  - [ ] Проверка (pass/fail): `scripts/ci/check_stage_ladder_enforcement.sh` включает `check_evidence_ledger.sh`.
  - [ ] Артефакт результата: evidence gate log + ledger diff.
- [ ] 8. Сделать: enforce pinned external adversarial harness proof для stage 05/06/20/24.
  - [ ] Проверка (pass/fail): `scripts/ci/check_stage_ladder_enforcement.sh` или связанный gate возвращает FAIL, если для stage 05/06/20/24 отсутствует harness policy/evidence.
  - [ ] Артефакт результата: harness gate log + negative scenario.

## Документация (RU)
- [ ] docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md
- [ ] docs/ops/stage_ladder_enforcement.md
- [ ] docs/governance/evidence/evidence_ledger.yaml
- [ ] docs/governance/evidence/README.md
- [ ] docs/portal/DELIVERY_EVIDENCE.md
- [ ] docs/runbooks/checklist_ladder_violation.md
- [ ] docs/source/risk_register_v0_2.md

## Тестирование
- [ ] unit: shell script validation for status parsing.
- [ ] integration: CI workflow execution.
- [ ] e2e: negative scenario (искусственно помеченный поздний этап `[x]` при незакрытом предыдущем) блокируется.
- [ ] chaos: ручная попытка обойти ladder через прямое изменение одной строки.
- [ ] integration: closed stage without evidence ledger entry блокируется.
- [ ] load: не применяется на этапе 38.
- [ ] soak: не применяется на этапе 38.

## CI gate
- [ ] `stage38-ladder-gate`

## DoD
- [ ] Лестница этапов 28..45 enforce в CI автоматически.
- [ ] Невозможен merge с нарушением последовательности.
- [ ] Невозможен merge закрытого этапа без evidence-записи и реальных артефактов.
- [ ] observability-gap событие этапа 38 зарегистрировано и имеет runbook.
- [ ] stage 05/06/20/24 не могут быть закрыты без pinned external adversarial harness evidence.

## Метаданные
- Ответственный: @neo-2022
- Ограничение перехода: программа v0.2 считается процессно защищённой только после закрытия CHECKLIST_38.
- Артефакты закрытия: script + CI logs + registry/runbook diff.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
