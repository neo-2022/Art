# Authenticity Baseline v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/governance/authenticity_copyright_policy.md`
- `formats/authenticity_assets_allowlist.yaml`
- `scripts/ci/check_authenticity_assets.sh`

## Что это такое
Это предохранитель, который не даёт проекту включать в baseline спорные по происхождению или правам сущности.

## Зачем он нужен
Даже хороший код можно сделать юридически уязвимым, если в проект тихо попадут:
- чужие иконки;
- аудиофайлы;
- шрифты;
- фрагменты текстов;
- демонстрационные медиа;
- pack/demo assets без понятного происхождения.

## Основной закон
В baseline разрешены только:
- project-owned assets;
- procedural/generated assets;
- synthetic fixtures;
- internal evidence artifacts;
- явно allowlisted элементы.

## Что это даёт
- снижает legal/IP риск;
- делает проект по-настоящему аутентичным;
- не даёт show/demo/UI слою тайно стать чужим продуктом.

## Observability и реакция
Gap:
- `observability_gap.authenticity_policy_violation`

## Связанные runbooks
- `docs/runbooks/authenticity_policy_violation.md`
