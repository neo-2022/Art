# Attachments security

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/retention_matrix.md`
- `docs/privacy/data_classification.md`

## Назначение

Документ фиксирует минимальный security/privacy baseline для attachments и attachment metadata.

## MIME allowlist

Разрешённый MIME allowlist:
- `text/plain`
- `application/json`
- `application/pdf`
- `text/csv`
- `application/zip`
- `image/png`
- `image/jpeg`

Всё вне allowlist:
- отклоняется;
- не хранится как attachment;
- не рендерится в UI.

## Magic bytes

Проверка magic bytes обязательна для бинарных и файловых типов.

Жёсткое правило:
- MIME из metadata недостаточен сам по себе;
- при конфликте между declared MIME и magic bytes приоритет у безопасного reject path.

## Max size

Baseline `max size`:
- `5 MiB`

Поведение при превышении:
- reject attachment;
- не сохранять content;
- зафиксировать безопасный diagnostic outcome.

## Sanitize filename

Filename обязателен к sanitization.

Запрещено:
- path traversal
- hidden path segments
- shell-control characters
- embedded HTML/script fragments в имени файла

Sanitize должен:
- убирать directory components;
- нормализовать unsafe symbols;
- сохранять только безопасное имя.

## Активный контент и XSS

Жёсткое правило:
- активный контент запрещён.

Явно запрещённые типы:
- `text/html`
- `image/svg+xml`
- `application/xhtml+xml`
- `application/javascript`
- `text/javascript`

Причина:
- XSS
- embedded scripts
- active rendering path in browser/UI

## Privacy baseline для вложений

Attachments рассматриваются как потенциальная PII и потенциальный container for secrets.

Следствие:
- attachment нельзя считать безопасным только по extension;
- attachment metadata и content проходят отдельный privacy/security review path;
- preview/excerpt возможен только после sanitization/redaction policy.

## Retention

Retention для attachments определяется в:
- `docs/privacy/retention_matrix.md`

Жёсткое правило:
- attachment retention не может жить отдельно от общей privacy matrix;
- profile-specific overrides должны ссылаться на retention matrix, а не вводиться локально “в обход”.

## Критерий актуальности

Документ считается актуальным только если:
- указан MIME allowlist;
- указана обязательная проверка magic bytes;
- указан `max size` и поведение при превышении;
- описан `sanitize filename`;
- явно запрещён active content / XSS;
- есть ссылка на retention matrix.
