# Версионирование

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/release/release_process.md`

## Модель Версий
Используется SemVer: `MAJOR.MINOR.PATCH`.

Правила инкремента:
- `MAJOR`: несовместимые изменения контрактов/API/поведения.
- `MINOR`: обратносуместимые расширения функциональности.
- `PATCH`: исправления дефектов без изменения совместимости.

## Git-Теги И GitHub Releases
- Stable release tag: `vX.Y.Z`
- Prerelease tag: `vX.Y.Z-rc.N`
- Tag обязан ссылаться на commit с зелёными обязательными gates.
- Для каждого тега публикуется GitHub Release с changelog и артефактами.

## Обязательные Релизные Артефакты
- `artcore-<version>-linux-x86_64-static.tar.gz`
- `artagent-<version>-linux-x86_64-static.tar.gz`
- `checksums.txt`
- SBOM (формат по текущей release policy)

## Коммуникация Совместимости Для Клиентов
- Runtime/platform compatibility: `docs/ops/platform-runtime-compatibility-matrix.md`
- OS/platform support levels: `docs/ops/platform-support.md`
- Product compatibility matrix: `docs/release/compat_matrix.md`

## Блокеры Релиза
Релиз блокируется при любом активном blocker из чек-листов 24/37 и risk register v0.2.
