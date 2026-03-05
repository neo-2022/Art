# Stream perf: 1000 subscribers / 60s

## Команда запуска
`/usr/bin/time -v cargo test -p art-core stream_load_1000_subscribers_60s -- --ignored --nocapture`

## Артефакты soak
- Локально/CI: `bash scripts/tests/stream_soak_with_artifacts.sh artifacts/stage14-soak`
- Workflow: `.github/workflows/stage14-soak-artifacts.yml`
- Артефакты: `stream_10k_events.log`, `stream_1000_subscribers_60s.log`, `summary.json`

## Окружение
- CPU/RAM: локальная dev-машина (Linux, x86_64)

## Результаты
- Сценарий: 1000 одновременных подписчиков, удержание 60 секунд
- Успешных подключений: 1000 / 1000
- Разрывы: 0.000%
- `stream_lag_ms` p95: 0
- Время: `60.14s` (wall time `1:00.20`)
- CPU (job): `0%`
- Peak RAM: `44704 KB` (~43.66 MiB)

## Pass/Fail
- CPU <= 80%: PASS
- RAM <= 1024 MiB: PASS
- Разрывов <= 1%: PASS
- `stream_lag_ms` p95 <= 2000 мс: PASS
