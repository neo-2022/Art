# Analytics Memory v0.2

Последняя актуализация: 2026-03-06

## Цель
Система должна запоминать статистику инцидентов и возвращать готовые выводы для графиков, диаграмм и оперативных инструкций.

## Реализация
1. Core накапливает minute-buckets по событиям (`total`, `gap`, `severity`, `kind`, `dna`).
2. Состояние аналитики сохраняется в файл (`CORE_ANALYTICS_STATE_PATH`, default `/tmp/art_core_analytics_state.json`).
3. Endpoint `GET /api/v2/analytics/summary` возвращает:
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
