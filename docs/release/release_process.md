# Процесс Релиза

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/release/versioning.md`
- `docs/ops/go_no_go_template.md`

## Политика
- Релиз только manual через CI; локальный релиз запрещён.
- Версионирование: SemVer.
- CHANGELOG обязателен в PR до тега.
- Тегирование разрешено только после полного `RELEASE_CHECKLIST`.

## GitHub Release Flow
1. Подготовка release PR с changelog и evidence.
2. Прогон обязательных CI gates.
3. Создание подписанного тега `vX.Y.Z` (или `vX.Y.Z-rc.N`).
4. Публикация GitHub Release с артефактами и checksum/SBOM.
5. Публикация compatibility note для клиентов:
   - `docs/release/compat_matrix.md`
   - `docs/ops/platform-runtime-compatibility-matrix.md`
6. Заполнение `GO/NO-GO` decision sheet:
   - `docs/ops/go_no_go_template.md`
   - sheet обязателен для production rollout и major upgrade rollout.

## Блокирующие Условия
Релиз запрещён, если:
- есть красные обязательные gates;
- не собраны обязательные release artifacts;
- есть активные blockers из risk register/checklist 24/checklist 37.
- не заполнен или не подписан `GO/NO-GO` decision sheet.
