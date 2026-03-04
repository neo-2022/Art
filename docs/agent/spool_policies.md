# Политики переполнения spool

## `never_drop_unacked` (default)
- Значение по умолчанию: `spool_overflow_policy=never_drop_unacked`.
- При full новые события от receivers не принимаются (source pause).
- Неудалённые unacked записи не перезаписываются.
- Периодический recheck: каждые `1000 ms`.
- Генерируется `observability_gap.spool_full`.

## `drop_oldest_when_full`
- Включается только явным конфигом: `spool_overflow_policy=drop_oldest_when_full`.
- При full удаляется oldest запись.
- Генерируется `data_quality.lossy_spool_drop`.
- Растёт `spool_dropped_total`.
- Создаётся инцидент `lossy_mode_active` с `action_ref=docs/runbooks/lossy_mode_active.md`.
