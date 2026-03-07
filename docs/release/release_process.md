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
- Для privileged и internet-exposed rollout обязательны:
  - доказанная `trust boundary` для actor context и audit/security paths;
  - доказанный `browser surface` baseline для всех browser-facing routes;
  - ingress/perimeter shield baseline.

## GitHub Release Flow
1. Подготовка release PR с changelog и evidence.
2. Прогон обязательных CI gates.
3. Создание подписанного тега `vX.Y.Z` (или `vX.Y.Z-rc.N`).
4. Публикация GitHub Release с артефактами, `checksums.txt`, SBOM и provenance bundle.
5. Публикация compatibility note для клиентов:
   - `docs/release/compat_matrix.md`
   - `docs/ops/platform-runtime-compatibility-matrix.md`
6. Заполнение `GO/NO-GO` decision sheet:
   - `docs/ops/go_no_go_template.md`
   - sheet обязателен для production rollout и major upgrade rollout.
7. Подтверждение protective contours:
   - `docs/source/trust_boundary_hardening_v0_2.md`
   - `docs/source/browser_surface_hardening_v0_2.md`
   - `docs/source/ingress_perimeter_protection_v0_2.md`

## Блокирующие Условия
Релиз запрещён, если:
- есть красные обязательные gates;
- не собраны обязательные release artifacts;
- есть активные blockers из risk register/checklist 24/checklist 37.
- не заполнен или не подписан `GO/NO-GO` decision sheet.
- не доказана `trust boundary` для privileged/restricted paths.
- не доказан `browser surface` baseline для browser-facing routes.
- internet-exposed профиль не имеет ingress/perimeter shield baseline.
