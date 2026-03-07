# Политика минимизации данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/data_classification.md`
- `docs/privacy/pii_surface.md`
- `docs/privacy/redaction_policy.md`

## Назначение

Этот документ фиксирует baseline privacy-minimization для Art.
Правило проекта:
- система должна собирать максимально полный набор сигналов,
- но не имеет права собирать лишний чувствительный payload, если для расследования достаточно более безопасного представления.

Это означает:
- собирать всё, что нужно для диагностики;
- не хранить сырые HTTP bodies, cookies, auth headers и произвольные user payloads без явной необходимости и policy-разрешения.

## Базовый принцип

Art применяет модель:
- `collect diagnostic signal`
- `drop or redact sensitive excess`
- `store only minimum necessary representation`

## 1. No HTTP bodies by default

Жёсткое правило:
- `HTTP request body` не хранится по умолчанию;
- `HTTP response body` не хранится по умолчанию;
- body не попадает:
  - в `RawEvent`
  - в `AuditEntry`
  - в индекс
  - в UI
  - во вложения

Исключение возможно только если:
- body прошёл отдельную policy-classification,
- body превращён в безопасное производное представление,
- это явно задокументировано в source-of-truth для конкретного интеграционного контура.

Даже при исключении приоритет имеет:
- excerpt/summary/hash
- а не raw body.

## 2. HTTP allowlist

Разрешён только фиксированный allowlist HTTP-полей контекста.

### Разрешено хранить

- `method`
- `route_template`
- `status_code`
- `latency_ms`
- `content_type`
- `content_length`
- `service_name`
- `upstream_name`
- `retry_count`
- `trace_id`
- `span_id`
- `request_id`

### Не разрешено хранить по умолчанию

- raw URL с полным query string
- request body
- response body
- произвольные headers
- cookies
- session tokens
- Authorization headers
- Set-Cookie
- custom auth headers

## 3. Headers и cookies

Жёсткое правило:
- headers вне allowlist запрещены к записи;
- cookies запрещены к записи;
- `Authorization`, `Cookie`, `Set-Cookie`, `Proxy-Authorization`, `X-Api-Key` и аналогичные поля не должны записываться ни в каком виде, кроме redacted marker.

Разрешённое поведение:
- `drop`
- или `redacted placeholder`, если это нужно для объяснения факта redaction.

Пример допустимого представления:
- `authorization=***redacted***`

Пример недопустимого представления:
- хранение первых/последних символов секрета без policy-основания.

## 4. Правила для `message`, `payload`, `context`

### `message`

- хранится только после redaction;
- не должен использоваться как контейнер для сырых секретов, cookies, токенов или полного бизнес-payload;
- при сомнении применяется `redact`, а не `store`.

### `payload`

- допускается только диагностически значимое содержимое;
- поля из `PII` и `secrets` либо `redact`, либо `drop` согласно `pii_surface` и `redaction_policy`;
- запрещено использовать `payload` как dump всего внешнего объекта “на всякий случай”.

### `context`

- допускается только allowlist operational/telemetry полей;
- context не должен становиться скрытым каналом записи `PII` или `secrets`;
- browser/agent/proxy контуры обязаны применять одинаковую дисциплину минимизации.

## 5. Правила для внешних систем

При интеграции с внешними источниками:
- webhook
- OTLP
- proxy
- REGART bridge
- agent receivers

входной поток не должен автоматически сохраняться целиком.

Обязательная последовательность:
1. классификация входных полей
2. minimization
3. redaction
4. нормализация в безопасный `RawEvent`

Запрещено:
- “сначала сохранить как есть, потом разберём”
- писать целиком upstream payload в spool/index/audit/UI

## 6. Правила для агента

`Art Agent` обязан применять минимизацию до долговременной записи в spool/outbox там, где это касается:
- auth material
- cookies
- tokens
- secrets
- raw HTTP body

Для строковых логов допускается:
- временная работа с raw line в памяти для redaction,
- но не запись unredacted секретов в persistent spool.

## 7. Allowlist полей контекста

Ниже фиксируется базовый allowlist для `context.*`:

- `context.hostname`
- `context.service_name`
- `context.pod_name`
- `context.systemd.unit`
- `context.receiver_kind`
- `context.trace_id`
- `context.span_id`
- `context.request_id`
- `context.retry_count`
- `context.error_class`
- `context.error_code`

Поля вне allowlist:
- не пишутся по умолчанию;
- либо должны быть отдельно добавлены в policy и `pii_surface`.

## 8. Производные данные вместо сырых данных

Предпочтительный способ хранения:
- hash
- excerpt
- classification label
- route template
- numeric counters
- bounded summary

Вместо:
- raw body
- full header set
- full cookie set
- full query string
- full binary dump

## 9. Failure mode

Если minimization policy не может быть применена:
- неизвестная схема
- policy conflict
- parser failure
- unsafe payload classification failure

то система не должна молча записывать сырой объект.

Разрешённое поведение:
- `drop unsafe fragment`
- зафиксировать `observability_gap.redaction_failed` или соответствующий privacy/gap event
- сохранить безопасный diagnostic envelope без утечки чувствительных полей

## 10. Критерий актуальности

Документ считается актуальным только если:
- явно зафиксировано правило `no HTTP bodies by default`;
- есть allowlist HTTP/context полей;
- запрещены headers/cookies вне allowlist;
- определены правила для `message`, `payload`, `context`;
- определено поведение для внешних систем и agent path;
- отсутствует двусмысленность “можно записывать как есть, а потом разберём”.
