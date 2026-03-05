A) Полный запрет опциональности:
# CHECKLIST 22 — E2E/Stress/Chaos/Soak/Perf
Файл: CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
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

- [x] **1. Сделать:** Network chaos: 50% packet loss 10 минут на канале Agent↔Core → затем восстановление → доставка корректна.
  - [x] Packet loss фиксирован: 50% (ровно)
  - [x] Длительность фиксирована: 10 минут
  - [x] Применяется только к трафику Agent↔Core (остальные каналы не трогаем)
  - [x] Во время chaos:
    - [x] Agent накапливает в spool/outbox
    - [x] Core продолжает работать (если доступен)
  - [x] После восстановления сети:
    - [x] backlog у агента уменьшается до 0
    - [x] события доставлены без потерь в режиме `never_drop_unacked`
    - [x] `ack.upto_seq` монотонен
  - [x] **Проверка (pass/fail):** существует отчёт `docs/testing/chaos.md`, содержит:
    - [x] точную команду/скрипт включения 50% packet loss
    - [x] тайминг 10 минут
    - [x] логи/метрики backlog/ack
    - [x] явный вывод pass/fail по критериям выше.

- [x] **2. Сделать:** Memory profiling под нагрузкой включено в perf report (графики RAM/CPU).
  - [x] Нагрузка фиксирована:
    - [x] `events_per_sec=200`
    - [x] `duration=15 минут`
  - [x] Снимаются метрики:
    - [x] RAM процесса Core (пик + график)
    - [x] CPU процесса Core (среднее + график)
    - [x] RAM процесса Agent (пик + график)
    - [x] CPU процесса Agent (среднее + график)
  - [x] **Проверка (pass/fail):** `docs/perf/report.md` содержит:
    - [x] описание нагрузки (200 eps, 15 мин)
    - [x] 4 графика (RAM/CPU Core и RAM/CPU Agent)
    - [x] таблицу итогов (peak/avg) и явный вывод pass/fail по критериям, указанным в документе.

- [x] **3. Сделать:** Power loss recovery: kill -9 Core → restart → подтверждённые данные сохранены; неподтверждённые переотправлены.
  - [x] Kill фиксирован: `kill -9` процесса Core
  - [x] Перезапуск Core фиксирован: systemd restart (или команда стенда; выбрать один способ и зафиксировать)
  - [x] Критерии корректности:
    - [x] все события с `seq <= ack.upto_seq` (подтверждённые до kill) присутствуют после рестарта
    - [x] события, не дошедшие до ack, переотправлены агентом и в итоге приняты
    - [x] отсутствуют дубликаты в Core по `dedup_key` (если дедуп включён в стенде)
  - [x] **Проверка (pass/fail):** сценарий описан в `docs/testing/e2e.md` и в `docs/testing/chaos.md` есть лог прогона; вывод pass/fail по критериям выше.

- [x] **4. Сделать:** Nightly CI: scheduled запуск chaos тестов.
  - [x] существует workflow `.github/workflows/nightly_chaos.yml`
  - [x] workflow имеет `on: schedule` (cron фиксирован)
  - [x] workflow запускает:
    - [x] network chaos (шаг 1) как smoke (например 2 минуты вместо 10 — запрещено; smoke должен быть отдельным зафиксированным сценарием, не заменяющим шаг 1)
    - [x] power loss recovery (шаг 3)
  - [x] workflow публикует артефакты отчётов:
    - [x] `docs/testing/chaos.md` (или отдельные логи в artifacts; один способ зафиксировать)
  - [x] **Проверка (pass/fail):** workflow присутствует, виден в CI и имеет хотя бы 1 успешный scheduled-run (ссылка/скрин фиксируется в docs).

- [x] **5. Сделать:** `observability_gap.e2e_environment_failed` при провале e2e стенда.
  - [x] Событие генерируется при любом фейле инфраструктуры стенда:
    - [x] Core не стартует
    - [x] Agent не стартует
    - [x] сеть/порт недоступен
    - [x] health/snapshot недоступны
  - [x] Событие попадает в snapshot/stream и содержит evidence_min:
    - [x] component (core|agent|network|runner)
    - [x] reason (строка)
    - [x] stage (setup|run|teardown)
    - [x] trace_id
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev2`
    - [x] `action_ref=docs/runbooks/e2e_environment_failed.md`
  - [x] **Проверка (pass/fail):** induced test ломает стенд (например блокирует порт Core) и подтверждает генерацию `observability_gap.e2e_environment_failed` и видимость в snapshot/stream.

## Документация (RU)
- [x] docs/testing/e2e.md
- [x] docs/testing/chaos.md
- [x] docs/testing/soak.md
- [x] docs/perf/report.md
- [x] docs/runbooks/e2e_environment_failed.md
- [x] .github/workflows/nightly_chaos.yml

## Тестирование
- [x] e2e: базовый прогон стенда (описан в docs/testing/e2e.md)
- [x] chaos: packet loss 50% 10 минут (шаг 1)
- [x] chaos: power loss recovery (шаг 3)
- [x] perf: 200 eps 15 минут + memory profiling (шаг 2)
- [x] soak: 24 часа 50 eps (фиксировано) с отчётом в docs/testing/soak.md

## CI gate
- [x] CI job `e2e-smoke` существует и зелёный (короткий e2e прогон без chaos)
- [x] CI job `e2e-chaos` существует и зелёный (включает runtime chaos smoke по потере/восстановлению и проверке gap событий; nightly использует свой workflow)
- [x] CI job `stage22-docs-gate` существует и запускается на PR в main
- [x] `stage22-docs-gate` запускает `scripts/ci/check_e2e_stage22_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/testing/chaos.md` содержит `50%` и `10 минут`
    - [x] `docs/perf/report.md` содержит `200` и `15 минут` и упоминание `RAM` и `CPU`
    - [x] `docs/testing/soak.md` содержит `24 часа` и `50 eps`
    - [x] `docs/testing/e2e.md` содержит `kill -9` и `ack.upto_seq`
    - [x] `docs/runbooks/e2e_environment_failed.md` содержит `mitigations` и `verification`
    - [x] `.github/workflows/nightly_chaos.yml` содержит `schedule`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Есть воспроизводимый network chaos (50% packet loss 10 минут) с отчётом и pass/fail.
- [x] Есть perf report с memory profiling (RAM/CPU графики) под фиксированной нагрузкой.
- [x] Есть power loss recovery сценарий с доказательством сохранности ack’нутых и переотправки не-ack’нутых.
- [x] Nightly chaos workflow существует и реально выполняется по schedule.
- [x] `observability_gap.e2e_environment_failed` реализован, зарегистрирован и имеет runbook; induced test зелёный.
- [x] CI gate Stage 22 зелёный.

