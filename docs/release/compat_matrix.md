# Матрица совместимости релиза

## Source of truth
- [versioning.md](versioning.md)
- [release_process.md](release_process.md)
- [../ops/platform-support.md](../ops/platform-support.md)
- [../ops/platform-runtime-compatibility-matrix.md](../ops/platform-runtime-compatibility-matrix.md)

## Назначение

Эта страница объясняет клиенту, на что он может реально опираться в текущей release-линейке.

Это не schema-документ, а клиентский compatibility statement, привязанный к release governance.

## Текущая release-линейка

| Release line | Статус | API posture | Runtime posture | Примечание |
|---|---|---|---|---|
| `v0.2.0-rc.2` | production candidate | `v1` stable, `v2` parallel rollout | Ubuntu native, Docker runtime, Kubernetes runtime execute-gated | Расширенная Linux-матрица пока validate-only до подключения выделенных runner'ов |

## Совместимость API

| API surface | Политика совместимости |
|---|---|
| `/api/v1/*` | сохраняется на период rollout `v2` |
| `/api/v2/*` | вводится параллельно и управляется контрактами и checklist program |

## Совместимость платформ

| Поверхность | Текущий уровень подтверждения |
|---|---|
| Ubuntu native | execute-gated |
| Docker runtime | execute-gated |
| Kubernetes runtime | execute-gated |
| VM Linux matrix | validate-only |
| Non-Ubuntu native Linux matrix | validate-only |

## Блокирующее правило релиза

Релиз нельзя позиционировать как полностью совместимый за пределами тех поверхностей, которые реально execute-gated в текущем release scope.
