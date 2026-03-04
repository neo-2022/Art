# Incident process

## Lifecycle
1. detect
2. triage
3. mitigate
4. resolve
5. postmortem
6. follow-ups

## Роли
- Incident Commander
- Communications
- Scribe

## observability_gap escalation
- Все `observability_gap.*` обязательно регистрируются и видимы в snapshot/stream.
- Для `ingest/*`, `spool/*`, `storage/*` инцидент создаётся автоматически с min severity SEV1.
- Для остальных случаев правило берётся из `docs/governance/observability_gap_registry.md` (`incident_rule`).
- Для всех случаев, где создаётся инцидент, обязателен `action_ref` на runbook в `docs/runbooks/`.
