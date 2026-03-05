# RBAC

Роли:
- `viewer`
- `operator`
- `admin`

Матрица:
- Snapshot/Stream/Incidents: `viewer`, `operator`, `admin` = allow
- Incidents ack/resolve: `viewer` = deny, `operator`/`admin` = allow
- Actions execute: `viewer` = deny, `operator`/`admin` = allow
- Audit read: только `admin` = allow

Неизвестная роль: deny (fail closed).

