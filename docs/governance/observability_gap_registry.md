# observability_gap registry

| event_name | description | evidence_min | actions | owner_component | owner_role | incident_rule | action_ref | example |
|---|---|---|---|---|---|---|---|---|
| observability_gap.art_unreachable | what=Art недоступен; where=ui_proxy; why=network/connect | error, endpoint, retry_count | retry + проверка доступности | ui_proxy | On-call | create_incident_min_sev1 | docs/runbooks/art_unreachable.md | остановить Art и вызвать ingest |
| observability_gap.spool_corrupted | what=повреждение spool; where=agent/spool; why=sqlite_error | error, file_path, counters | fallback + восстановление | agent/spool | On-call | create_incident_min_sev1 | docs/runbooks/spool_corrupted.md | подменить spool битым файлом |
| observability_gap.ui_proxy_unavailable | what=UI Proxy недоступен; where=browser level0; why=http_error | status, endpoint, retry_count | restart ui_proxy | browser/level0 | On-call | create_incident | docs/runbooks/ui_proxy_unavailable.md | выключить ui_proxy service |
| observability_gap.redaction_failed | what=redaction сломан; where=pipeline; why=rule_error | error, rule_id, counters | отключить rule и откатить конфиг | core/pipeline | Security | create_incident_min_sev1 | docs/runbooks/redaction_failed.md | сломанный redaction config |
