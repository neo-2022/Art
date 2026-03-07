# Runbook: test_strength_guard_failed

## Что это означает
Критичный контур пытаются закрыть на слабых тестах, которые не доказывают production-grade поведение.

## Что проверить
1. Каких test families не хватает.
2. Не является ли текущий proof только `grep`, snapshot или HTML-string test.
3. Есть ли hostile/adversarial path.
4. Есть ли regression guard.

## Что делать
1. Добавить недостающие test families.
2. Повысить тест с decorative до operational/adversarial уровня.
3. Повторить gate.

## Проверка восстановления
- contour доказан через достаточную глубину тестирования, а не только через структуру.
