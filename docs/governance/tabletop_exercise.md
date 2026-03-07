# Tabletop Exercise

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/incident_process.md`
- `docs/governance/severity.md`

## Периодичность

- не реже `1 раза в квартал`;
- после каждого `SEV0` или `SEV1`;
- после изменения `observability_gap.*` или порогов `SLO/SLI`.

## Сценарий 1: observability_gap (Art unreachable)

- дата: `2026-03-05`
- сценарий: `observability_gap.art_unreachable`
- timeline: `ingest timeout -> incident open -> triage -> mitigation -> verification`
- принятые решения: `failover + restart pipeline + escalation to on-call`
- runbook: `docs/runbooks/art_unreachable.md`
- итоговые follow-ups: `расширить alert coverage`, `добавить transport visibility`

## Сценарий 2: SLO breach (spool_backlog_age_sec)

- дата: `2026-03-05`
- сценарий: `SLO breach spool_backlog_age_sec > 120`
- timeline: `threshold exceeded -> SEV1 -> drain outbox -> verification`
- принятые решения: `увеличить backpressure visibility`, `подтвердить recovery window`
- runbook: `docs/runbooks/spool_backlog_age.md`
- итоговые follow-ups: `добавить perf тест`, `усилить backlog evidence`
