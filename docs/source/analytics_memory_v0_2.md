# Analytics Memory v0.2

Последняя актуализация: 2026-03-06

## Цель
Система должна запоминать статистику инцидентов и возвращать готовые выводы для графиков, диаграмм и оперативных инструкций.

## Реализация
1. Core накапливает minute-buckets по событиям (`total`, `gap`, `severity`, `kind`, `dna`).
2. Основное состояние аналитики сохраняется в SQLite вместе с durable storage-контуром Core.
3. Путь `CORE_ANALYTICS_STATE_PATH` сохраняется как legacy mirror/import path:
   - может использоваться для одноразового импорта или внешней диагностики;
   - не считается primary source of truth для восстановления после рестарта.
4. Endpoint `GET /api/v2/analytics/summary` возвращает:
   - totals,
   - chart-ready series,
   - top kinds/DNA,
   - auto-instructions для triage.

## Пример запроса
```bash
curl -s "http://127.0.0.1:7070/api/v2/analytics/summary?window_minutes=120&top=5"
```

## Авто-выводы
- высокий gap-rate -> сначала стабилизировать сбор/доставку;
- высокий invalid payload -> проверка producer schema;
- доминирующий kind -> выделенный план remediation;
- доминирующий DNA -> приоритизация Investigation-as-Code.

## Текущее corrective-ограничение
- durable analytics recovery уже переведён в SQLite;
- hostile backup/restore доказательство на полном `Core state` уже есть;
- live runtime-контур `corruption -> 503/retry_after_ms -> restore -> read_only fallback` уже доказан;
- live-process chaos сценарий `kill -9` во время ingest уже доказан отдельным smoke;
- concurrency proof для долгой многопоточной нагрузки теперь тоже зафиксирован отдельным stage-level evidence на `8 writer / 4 reader / 10000 ops`;
- открытым в `stage11` остаётся production-proof для `VACUUM/systemd`.
