# SCA policy

Инструмент: osv-scanner.
Источник уязвимостей: OSV.
Лицензии проверяются, запрещённые licenses блокируют merge.
SCA запускается на каждом PR в `main`.
Критерии severity:
- `CRITICAL` и `HIGH` -> merge блокируется.
- `MEDIUM` и `LOW` -> допускаются только с явным risk-accept в PR.
Список запрещённых лицензий:
- GPL-3.0
- AGPL-3.0
- SSPL-1.0
- BUSL-1.1
