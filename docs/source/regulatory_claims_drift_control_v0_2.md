# Regulatory Claims Drift Control v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/risk_register_v0_2.md`
- `formats/ru_regulatory_scope.yaml`
- `docs/security/fstec-certified-profile.md`
- `docs/ops/platform-support.md`

## Что это такое
Это предохранитель от завышенных regulatory и certification claims.

## Простыми словами
Если проект реально доказал только `certified-ready`, он не имеет права писать или показывать `certified`.

То же правило относится к:
- RU profile;
- platform support;
- audit-ready;
- gov/regulated deployment claims.

## Зачем он нужен
Этот проект будет смотреть не только инженер, но и:
- заказчик;
- аудитор;
- закупка;
- security/compliance команда.

Ложный claim здесь опаснее обычной ошибки документации.

## Что обязан делать guard
- проверять разницу между `готово к сертификации` и `сертифицировано`;
- не давать release/docs/process говорить больше, чем есть в evidence;
- связывать claims с machine-readable нормативным контуром.

## Observability и реакция
Gap:
- `observability_gap.regulatory_claim_drift`

## Связанные runbooks
- `docs/runbooks/regulatory_claim_drift.md`
