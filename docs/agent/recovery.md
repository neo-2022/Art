# Recovery политики агента

## `spool_corrupted`
- При детекте corruption текущий spool переводится в quarantine.
- Создаётся новый spool (новый путь/каталог).
- Приём событий продолжается в новый spool.
- Генерируется `observability_gap.spool_corrupted`.

## `spool_disk_full`
- При заполнении диска запись в spool останавливается по active policy.
- Генерируется `observability_gap.spool_disk_full`.
- После освобождения места агент возвращается в штатный режим flush.
