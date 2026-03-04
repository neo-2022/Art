A) Полный запрет опциональности:
# CHECKLIST 22 — E2E/Stress/Chaos/Soak/Perf
Файл: CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение perf целей; изменение сети; новые компоненты; изменение состава стенда e2e

## Цель
Доказать устойчивость end-to-end: network chaos (50% packet loss), memory profiling под нагрузкой, power loss recovery, nightly chaos CI, и наблюдаемость проблем стенда через `observability_gap.e2e_environment_failed`.

## Границы
Тестовый контур (стенд) и воспроизводимые сценарии тестирования/отчёты.  
Не включает изменение функционала Core/Agent/Browser — только тесты/инфраструктура тестов и доказательства.

## Зависимости
- CHECKLIST 20 — Pack REGART
- CHECKLIST 21 — Self-observability Art

## Шаги (строго линейно)

- [ ] **1. Сделать:** Network chaos: 50% packet loss 10 минут на канале Agent↔Core → затем восстановление → доставка корректна.
  - [ ] Packet loss фиксирован: 50% (ровно)
  - [ ] Длительность фиксирована: 10 минут
  - [ ] Применяется только к трафику Agent↔Core (остальные каналы не трогаем)
  - [ ] Во время chaos:
    - [ ] Agent накапливает в spool/outbox
    - [ ] Core продолжает работать (если доступен)
  - [ ] После восстановления сети:
    - [ ] backlog у агента уменьшается до 0
    - [ ] события доставлены без потерь в режиме `never_drop_unacked`
    - [ ] `ack.upto_seq` монотонен
  - [ ] **Проверка (pass/fail):** существует отчёт `docs/testing/chaos.md`, содержит:
    - [ ] точную команду/скрипт включения 50% packet loss
    - [ ] тайминг 10 минут
    - [ ] логи/метрики backlog/ack
    - [ ] явный вывод pass/fail по критериям выше.

- [ ] **2. Сделать:** Memory profiling под нагрузкой включено в perf report (графики RAM/CPU).
  - [ ] Нагрузка фиксирована:
    - [ ] `events_per_sec=200`
    - [ ] `duration=15 минут`
  - [ ] Снимаются метрики:
    - [ ] RAM процесса Core (пик + график)
    - [ ] CPU процесса Core (среднее + график)
    - [ ] RAM процесса Agent (пик + график)
    - [ ] CPU процесса Agent (среднее + график)
  - [ ] **Проверка (pass/fail):** `docs/perf/report.md` содержит:
    - [ ] описание нагрузки (200 eps, 15 мин)
    - [ ] 4 графика (RAM/CPU Core и RAM/CPU Agent)
    - [ ] таблицу итогов (peak/avg) и явный вывод pass/fail по критериям, указанным в документе.

- [ ] **3. Сделать:** Power loss recovery: kill -9 Core → restart → подтверждённые данные сохранены; неподтверждённые переотправлены.
  - [ ] Kill фиксирован: `kill -9` процесса Core
  - [ ] Перезапуск Core фиксирован: systemd restart (или команда стенда; выбрать один способ и зафиксировать)
  - [ ] Критерии корректности:
    - [ ] все события с `seq <= ack.upto_seq` (подтверждённые до kill) присутствуют после рестарта
    - [ ] события, не дошедшие до ack, переотправлены агентом и в итоге приняты
    - [ ] отсутствуют дубликаты в Core по `dedup_key` (если дедуп включён в стенде)
  - [ ] **Проверка (pass/fail):** сценарий описан в `docs/testing/e2e.md` и в `docs/testing/chaos.md` есть лог прогона; вывод pass/fail по критериям выше.

- [ ] **4. Сделать:** Nightly CI: scheduled запуск chaos тестов.
  - [ ] существует workflow `.github/workflows/nightly_chaos.yml`
  - [ ] workflow имеет `on: schedule` (cron фиксирован)
  - [ ] workflow запускает:
    - [ ] network chaos (шаг 1) как smoke (например 2 минуты вместо 10 — запрещено; smoke должен быть отдельным зафиксированным сценарием, не заменяющим шаг 1)
    - [ ] power loss recovery (шаг 3)
  - [ ] workflow публикует артефакты отчётов:
    - [ ] `docs/testing/chaos.md` (или отдельные логи в artifacts; один способ зафиксировать)
  - [ ] **Проверка (pass/fail):** workflow присутствует, виден в CI и имеет хотя бы 1 успешный scheduled-run (ссылка/скрин фиксируется в docs).

- [ ] **5. Сделать:** `observability_gap.e2e_environment_failed` при провале e2e стенда.
  - [ ] Событие генерируется при любом фейле инфраструктуры стенда:
    - [ ] Core не стартует
    - [ ] Agent не стартует
    - [ ] сеть/порт недоступен
    - [ ] health/snapshot недоступны
  - [ ] Событие попадает в snapshot/stream и содержит evidence_min:
    - [ ] component (core|agent|network|runner)
    - [ ] reason (строка)
    - [ ] stage (setup|run|teardown)
    - [ ] trace_id
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev2`
    - [ ] `action_ref=docs/runbooks/e2e_environment_failed.md`
  - [ ] **Проверка (pass/fail):** induced test ломает стенд (например блокирует порт Core) и подтверждает генерацию `observability_gap.e2e_environment_failed` и видимость в snapshot/stream.

## Документация (RU)
- [ ] docs/testing/e2e.md
- [ ] docs/testing/chaos.md
- [ ] docs/testing/soak.md
- [ ] docs/perf/report.md
- [ ] docs/runbooks/e2e_environment_failed.md
- [ ] .github/workflows/nightly_chaos.yml

## Тестирование
- [ ] e2e: базовый прогон стенда (описан в docs/testing/e2e.md)
- [ ] chaos: packet loss 50% 10 минут (шаг 1)
- [ ] chaos: power loss recovery (шаг 3)
- [ ] perf: 200 eps 15 минут + memory profiling (шаг 2)
- [ ] soak: 24 часа 50 eps (фиксировано) с отчётом в docs/testing/soak.md

## CI gate
- [ ] CI job `e2e-smoke` существует и зелёный (короткий e2e прогон без chaos)
- [ ] CI job `e2e-chaos` существует и зелёный (включает шаги 1 и 3 в полном виде для ручного запуска; nightly использует свой workflow)
- [ ] CI job `stage22-docs-gate` существует и запускается на PR в main
- [ ] `stage22-docs-gate` запускает `scripts/ci/check_e2e_stage22_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/testing/chaos.md` содержит `50%` и `10 минут`
    - [ ] `docs/perf/report.md` содержит `200` и `15 минут` и упоминание `RAM` и `CPU`
    - [ ] `docs/testing/soak.md` содержит `24 часа` и `50 eps`
    - [ ] `docs/testing/e2e.md` содержит `kill -9` и `ack.upto_seq`
    - [ ] `docs/runbooks/e2e_environment_failed.md` содержит `mitigations` и `verification`
    - [ ] `.github/workflows/nightly_chaos.yml` содержит `schedule`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Есть воспроизводимый network chaos (50% packet loss 10 минут) с отчётом и pass/fail.
- [ ] Есть perf report с memory profiling (RAM/CPU графики) под фиксированной нагрузкой.
- [ ] Есть power loss recovery сценарий с доказательством сохранности ack’нутых и переотправки не-ack’нутых.
- [ ] Nightly chaos workflow существует и реально выполняется по schedule.
- [ ] `observability_gap.e2e_environment_failed` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [ ] CI gate Stage 22 зелёный.

