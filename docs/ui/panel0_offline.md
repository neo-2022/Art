# Panel0 offline

Если Core недоступен, Panel0 показывает placeholder:
- текст `Core недоступен`
- причина (`network error` или `HTTP <code>`)
- кнопку `Reload`

Условия core-down:
- `/health` недоступен или `503`
- `/api/v1/snapshot` недоступен или `503`

После восстановления Core панель возвращается из placeholder в нормальный режим.
Сценарий offline reload поддерживается через кэш Service Worker.

