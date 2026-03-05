# Compression

- Порог: `payload_size_bytes > 1024`
- Кодек: `gzip`
- Точка применения: перед записью outbox записи (IndexedDB-слой Level0)
- Метаданные записи:
  - `content_encoding` (`identity` или `gzip`)
  - `original_size_bytes`
  - `stored_size_bytes`

## Flush поведение
- При `content_encoding=gzip` выполняется распаковка перед отправкой в ingest.
- В сеть отправляется исходный RawEvent (после `gunzip`).

## Ошибка распаковки
- Генерируется `observability_gap.outbox_decompress_failed`.
- Событие включает `trace_id`, `what/where/why/evidence/actions`.
- `action_ref`: `docs/runbooks/outbox_decompress_failed.md`.
