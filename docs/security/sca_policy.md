# SCA policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/security_stage04.yml`
- `docs/security/osv_risk_accept.yaml`

## Инструменты и baseline
- единый инструмент SCA: `osv-scanner`
- единый источник уязвимостей: `OSV`
- license checks обязательны и выполняются на каждом PR в `main`
- policy разделяет:
  - vulnerability findings;
  - license findings;
  - policy-only signals

## Точки запуска
- SCA запускается на каждом PR в `main`
- SCA запускается на каждом push в `main`
- release path использует ту же baseline policy

## Fail policy для уязвимостей
Критерии severity:
- `CRITICAL` и `HIGH` -> merge блокируется
- `MEDIUM` и `LOW` -> допускаются только с явным risk-accept в PR и в `docs/security/osv_risk_accept.yaml`
- `NONE`/policy-only сигналы (например `unmaintained`) не блокируют merge автоматически, если:
  - запись внесена в `docs/security/osv_risk_accept.yaml`
  - указан владелец и срок истечения
  - зафиксирован план удаления зависимости из production path

## License policy
Запрещённые лицензии блокируют merge.

Явный список запрещённых лицензий:
- GPL-3.0
- AGPL-3.0
- SSPL-1.0
- BUSL-1.1

## Risk-accept реестр
- `docs/security/osv_risk_accept.yaml`
- пустой allowlist по умолчанию запрещён заменять широкими исключениями
- допускаются только точечные записи `id + package + path + owner + expires_utc + mitigation`

## Risk-accept реестр
- `docs/security/osv_risk_accept.yaml`
- пустой allowlist по умолчанию запрещён заменять широкими исключениями;
- допускаются только точечные записи `id + package + path + owner + expires_utc + mitigation`.
