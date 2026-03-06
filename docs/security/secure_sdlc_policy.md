# Политика Secure SDLC

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/security/release_hardening.md`

## Назначение

Политика определяет минимальный дисциплинарный контур безопасной разработки и поставки.

## Обязательные Правила
- build выполняется в чистом CI-окружении
- build должен быть воспроизводимым
- lock-файлы обязательны
- повторная сборка из того же commit должна давать тот же artifact hash там, где это заявлено контрактом
- использование `latest` тегов инструментов в CI запрещено

## Проверяемые Контуры
- pinning toolchain и зависимостей
- контроль supply chain
- security checks в CI
- подтверждение release provenance

## Блокирующие Нарушения
- сборка вне CI
- отсутствие lock-файлов
- непинованные critical tool references
- необъяснимое расхождение hash между повторными сборками
