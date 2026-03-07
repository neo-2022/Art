# Политика Secure SDLC

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/security/release_hardening.md`

## Назначение

Политика определяет минимальный дисциплинарный контур безопасной разработки и поставки.

## Обязательные Правила
- `clean build` выполняется только в чистом CI-окружении без использования локальных артефактов разработчика, локальных caches как источника истины и ручных prebuilt binaries.
- build выполняется в чистом CI-окружении от зафиксированного коммита и зафиксированного workflow.
- build должен быть `reproducible`: одинаковый вход (`repo state + lockfiles + pinned tools + pinned workflow actions`) обязан давать одинаковый результат.
- lock-файлы обязательны для всех менеджеров зависимостей, где они поддерживаются.
- зависимости и инструменты фиксируются lock-файлами и/или pinned версиями; плавающие версии запрещены.
- повторная релизная сборка из того же commit должна давать тот же `artifact hash` для каждого релизного артефакта из фиксированного перечня.
- использование `latest` тегов инструментов, линтеров, сканеров и CI actions запрещено.

## Проверяемые Контуры
- pinning toolchain и зависимостей
- контроль supply chain
- security checks в CI
- подтверждение release provenance

## Release reproducibility contract
- release rebuild запускается из того же git commit и того же release workflow definition;
- итоговые артефакты сравниваются по `artifact hash`;
- несовпадение `artifact hash` без документированной причины считается release-blocker;
- локальная сборка разработчика не является доказательством reproducibility.

## Блокирующие Нарушения
- сборка вне CI
- отсутствие lock-файлов
- непинованные critical tool references
- необъяснимое расхождение hash между повторными сборками
