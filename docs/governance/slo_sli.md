# SLO/SLI

| SLI | Определение | Окно измерения | Цель | Источник |
|---|---|---|---|---|
| ingest_success_rate | успешные ingest / все ingest | 30 минут | >= 99.9% | metrics |
| spool_backlog_age_sec | максимальный возраст backlog | 5 минут | <= 120 сек | metrics |
| dlq_size | размер DLQ | 5 минут | = 0 | metrics |
| stream_lag_ms | лаг stream | 1 минута | <= 2000 мс | metrics |

## SLO breach mapping

| Нарушение | severity | action_ref | incident_rule |
|---|---|---|---|
| ingest_success_rate < 99.9% | SEV1 | docs/runbooks/ingest_overloaded.md | create_incident_min_sev1 |
| spool_backlog_age_sec > 120 | SEV1 | docs/runbooks/spool_backlog_age.md | create_incident_min_sev1 |
| dlq_size > 0 более 15 минут | SEV2 | docs/runbooks/dlq_non_empty.md | create_incident_min_sev2 |
| stream_lag_ms > 2000 более 5 минут | SEV2 | docs/runbooks/stream_lag.md | create_incident_min_sev2 |
