# Stream perf: 10k events

## Команда запуска
`/usr/bin/time -v cargo test -p art-core stream_load_10k_events_single_subscriber -- --nocapture`

## Окружение
- CPU/RAM: локальная dev-машина (Linux, x86_64)

## Результаты
- Получено событий: 10000
- Порядок `id:`: монотонный
- Ошибки разрывов: 0
- Время теста: `0.13s` (wall time `0:00.19`)
- Max RSS: `45664 KB`

## Pass/Fail
- Все 10000 событий получены: PASS
- Порядок монотонный: PASS
- Разрывов нет: PASS
- Время <= 120s: PASS
