# Усиление Безопасности Релиза

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/release/release_process.md`

## Назначение

Документ фиксирует минимальные и обязательные меры безопасности, без которых релиз `Art` не может считаться допустимым к публикации.

## Базовые Правила
- локальные релизы запрещены
- релиз создаётся только через CI
- релизный тег должен быть защищённым и воспроизводимым
- публикация без зелёных security jobs запрещена

## Обязательные Требования Перед Публикацией
- сформированы SBOM, checksums и provenance attestation
- выполнена verify-проверка подписей
- release artifacts соответствуют release checklist
- release decision оформлен через `GO/NO-GO`

## Что Является Блокером
- красный `security` gate
- отсутствие подписи или verify-подтверждения
- отсутствие SBOM или checksum-файлов
- расхождение между release metadata и опубликованными артефактами
