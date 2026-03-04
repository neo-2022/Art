# Tabletop exercise

## Периодичность
- не реже 1 раза в квартал
- после каждого SEV0/SEV1
- после изменения `observability_gap.*` или порогов SLO/SLI

## Сценарий 1: observability_gap (Art unreachable)
- дата: 2026-03-05
- таймлайн: ingest timeout -> incident open -> action runbook
- решения: failover + restart pipeline
- runbook: `docs/runbooks/art_unreachable.md`
- follow-ups: расширить alert coverage

## Сценарий 2: SLO breach (spool_backlog_age_sec)
- дата: 2026-03-05
- таймлайн: backlog_age > 120 -> SEV1 -> drain outbox
- решения: увеличить backpressure visibility
- runbook: `docs/runbooks/spool_backlog_age.md`
- follow-ups: добавить perf тест
