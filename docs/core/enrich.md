# Enrich

Этап enrich добавляет производные поля в payload/context.

## template injection matrix
- $(command)
- `command`
- ${VAR}
- ; rm -rf /
- | curl ...
- ../../

Политика: escape-only (никакого исполнения шаблонов/команд).
При блокировке генерируется `security.template_injection_blocked`.
