# SCA policy

Инструмент: osv-scanner.
Источник уязвимостей: OSV.
Лицензии проверяются, запрещённые licenses блокируют merge.
SCA запускается на каждом PR в `main`.
Критерии severity:
- `CRITICAL` и `HIGH` -> merge блокируется.
- `MEDIUM` и `LOW` -> допускаются только с явным risk-accept в PR.
- `NONE`/policy-only сигналы (например `unmaintained`) не блокируют merge автоматически, если:
  - запись внесена в `docs/security/osv_risk_accept.yaml`
  - указан владелец и срок истечения
  - зафиксирован план удаления зависимости из production path
Список запрещённых лицензий:
- GPL-3.0
- AGPL-3.0
- SSPL-1.0
- BUSL-1.1

## Risk-accept реестр
- `docs/security/osv_risk_accept.yaml`
- пустой allowlist по умолчанию запрещён заменять широкими исключениями;
- допускаются только точечные записи `id + package + path + owner + expires_utc + mitigation`.
