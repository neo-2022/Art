# Browser Level0 chaos/e2e matrix

Команда запуска:

```bash
bash scripts/tests/browser_level0_chaos_e2e.sh
```

Сценарии:

1. Multi-tab dedup + лидерство:
   - 2 вкладки видят локально;
   - в ingest уходит 1 событие по `dedup_key`.
2. CORS blocked:
   - генерируется `observability_gap.cors_blocked` с обязательным evidence.
3. Транзиентная ошибка ingest:
   - первая отправка падает;
   - повторная отправка тем же лидером проходит;
   - событие не теряется из-за dedup.
4. Worker fallback:
   - при недоступном Worker работает main-thread fallback;
   - фиксируется `observability_gap.worker_unavailable`.
5. Outbox overflow политики:
   - `never_drop_unacked` → reject + `observability_gap.outbox_full`;
   - `drop_oldest_when_full` → `data_quality.lossy_outbox_drop` + `incident.lossy_mode_active`.
6. Outbox flush retry:
   - после временного upstream fail запись остаётся pending;
   - повторный flush доставляет payload и очищает pending.
