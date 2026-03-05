# RU profile

| field_path | rule |
|---|---|
| message | store_ru_only |
| ctx.* | store_ru_only |
| payload.* | redact_on_export |
| audit.client_ip | store_ru_only |
| audit.user_agent | redact_on_export |
