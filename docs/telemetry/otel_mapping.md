# OTel mapping

## Правило unknown attributes

Все неизвестные OTel атрибуты сохраняются без потерь в `payload.otel_attributes`.
Ключи атрибутов сохраняются в исходном виде (строки).

Если ключ конфликтует с фиксированным полем RawEvent/ctx, ключ в
`payload.otel_attributes` записывается как `otel.<key>`.

## Приведение типов

- string -> string
- bool -> bool
- int/double -> number
- array -> array (элементы приводятся по тем же правилам)
- bytes → base64

## Пример входа/выхода

Вход (OTel attrs):

```json
{
  "service.name": "api",
  "attempts": 3,
  "success": false,
  "raw": "AAEC",
  "severity": "warn",
  "tags": ["a", "b"]
}
```

Выход (RawEvent fragment):

```json
{
  "payload": {
    "otel_attributes": {
      "service.name": "api",
      "attempts": 3,
      "success": false,
      "raw": "AAEC",
      "otel.severity": "warn",
      "tags": ["a", "b"]
    }
  }
}
```
