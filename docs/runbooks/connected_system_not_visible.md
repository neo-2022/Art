# Runbook: connected_system_not_visible

## Сигналы
- `observability_gap.connected_system_not_visible`
- `observability_gap.connected_system_coverage_drift`

## Когда использовать
Когда Art показывает, что система:
- не стала видна после подключения;
- видна только как `declared_only`;
- показывает расхождение между promised coverage и observed coverage.

## Диагностика
1. Проверить `system_id`, `integration_kind`, `pack_id` и `last_seen_ts_ms`.
2. Проверить, есть ли свежие observed signals в пределах `freshness_threshold_ms`.
3. Сравнить:
   - `declared_data_kinds`
   - `observed_data_kinds`
   - `receiver_kinds`
   - `telemetry_endpoints`
4. Проверить активные `gap events`.
5. Для pack-based интеграции сверить `service_inventory` и `signal_coverage_claims` manifest.

## Mitigations
1. Исправить receiver или transport path.
2. Исправить drift в pack manifest и source coverage docs.
3. Если система реально молчит, оставить статус `declared_only`, а не скрывать проблему.
4. Если observed coverage меньше заявленного, зафиксировать `connected_system_coverage_drift` и исправить источник.

## Verification
1. Система видна в Connected System View.
2. `connection_status` стал `connected` или честно остался `degraded/declared_only`.
3. `observed_data_kinds` и `declared_data_kinds` больше не расходятся без gap event.
4. Есть свежий `evidence_ref`, подтверждающий поступление signal.
