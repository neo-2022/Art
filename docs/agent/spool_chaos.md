# Chaos сценарии для spool/outbox

## 1) kill -9 во время записи
1. Запустить агент и включить приём событий.
2. Во время активной записи выполнить `kill -9 <pid>`.
3. Перезапустить агент.
4. Проверить консистентность очереди и продолжение flush в Core.

Pass: данные читаются, flush продолжается, агент не падает в цикле рестартов.

## 2) network loss (Core недоступен)
1. Отключить доступ к Core ingest (firewall или stop сервиса).
2. Наблюдать рост spool/outbox.
3. Проверить backoff и поведение active overflow policy.

Pass: backoff включается; при full отрабатывает policy (`never_drop_unacked` или `drop_oldest_when_full`).

## 3) disk full
1. Ограничить свободное место на spool пути.
2. Продолжить подачу событий до заполнения диска.
3. Проверить событие `observability_gap.spool_disk_full`.
4. Освободить место и проверить восстановление.

Pass: gap-событие зафиксировано, после освобождения места flush восстанавливается.

## 4) corruption
1. Повредить spool файл/индекс.
2. Перезапустить агент.
3. Проверить создание нового spool и quarantine старого.

Pass: создаётся новый spool, `observability_gap.spool_corrupted` виден в snapshot/stream.

## CI smoke (runtime)

Команда:

```bash
bash scripts/tests/agent_spool_chaos_runtime.sh
```

Smoke гарантирует runtime-прохождение сценариев:
- kill -9 + restart агента;
- full capacity (`never_drop_unacked`) с `observability_gap.spool_full`;
- `simulate_disk_full` с `observability_gap.spool_disk_full`;
- `simulate_corruption` с `observability_gap.spool_corrupted`.
