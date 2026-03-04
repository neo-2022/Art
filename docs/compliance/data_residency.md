# Data residency

Матрица `profile_id -> allowed residency`:

| profile_id | allowed |
|---|---|
| global | any approved region |
| eu | eu data centers only |
| ru | ru data centers only |
| airgapped | local isolated storage only |

Типы данных: events, incidents, audit, attachments.
Нарушение policy: startup fail или reject apply-config.
