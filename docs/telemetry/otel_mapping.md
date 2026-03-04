# OTel mapping

Unknown attributes сохраняются в `payload.otel_attributes`.

Правила типов:
- string -> string
- bool -> bool
- int/double -> number
- array -> array
- bytes -> base64

При конфликте ключей используется префикс `otel.<key>`.
