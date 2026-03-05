# Panel0

Panel0 — минимальная embedded панель.

Отображение gap:
- Все события с префиксом `observability_gap.` выделяются фиксированно:
  - иконка: `⚠`
  - цвет: `amber`
  - tooltip: `kind`, `what`, `where`, `why`, `action_ref`, `trace_id`
- В tooltip запрещены утечки PII/секретов (token/header/cookie и подобные поля редактируются).

Диагностика:
- `build_id`
- `effective_profile_id` (из payload `GET /api/v1/snapshot`)

