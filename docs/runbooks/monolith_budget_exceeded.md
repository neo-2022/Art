# Runbook: monolith_budget_exceeded

## Что это означает
Критичный файл или модуль вырос до опасного уровня и требует decomposition path.

## Что проверить
1. Реальный line count.
2. Сколько несущих ответственностей смешано.
3. Есть ли decomposition plan.
4. Какие stages и reviewers затронуты.

## Что делать
1. Зафиксировать decomposition plan.
2. Разделить ответственности по модулям.
3. Повторить architecture review.

## Проверка восстановления
- budget снова в допустимом диапазоне;
- responsibilities разделены;
- hostile review стал проще и дешевле.
