# Certified Build Profile (FSTEC-Oriented)

## Source of truth
- `formats/platform_support.yaml`
- `Cargo.toml` (`profile.general`, `profile.certified`)
- `scripts/ci/check_certified_profile.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Назначение
`certified` профиль вводит строгий build-контур для A-уровня матрицы (Astra Linux SE, RED OS). Даже пока натурные тесты исполняются только на Ubuntu, контрактные требования certified-профиля должны проходить уже сейчас.

## Обязательные инварианты certified-профиля
- Нет динамической загрузки расширений (`dlopen`, `libloading`) в кодовой базе.
- Dependency allowlist зафиксирован и проверяется в CI.
- Профиль сборки воспроизводимый: lockfiles + фиксированные профильные флаги.
- Релизный pipeline содержит hook на подпись артефактов.

## CI сейчас
- Выполняется контрактная проверка `scripts/ci/check_certified_profile.sh` на Ubuntu.
- Проверяется сборка `--profile certified` для `art-core` и `art-agent`.

## Nat testing после финала
После включения `ENABLE_NATURAL_MATRIX=true` профиль `certified` дополнительно проверяется в:
- `astra-certified-smoke`
- `redos-certified-smoke`

## Ограничение
Документ описывает именно профиль и проверки. Политики комплаенса и эксплуатационные требования остаются в профильных runbook/checklist документах.
