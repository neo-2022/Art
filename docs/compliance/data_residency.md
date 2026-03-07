# Data residency

Матрица `profile_id -> allowed residency`:

| profile_id | events | incidents | audit | attachments | allowed |
|---|---|---|---|---|---|
| global | any approved region | any approved region | any approved region | any approved region | yes |
| eu | eu data centers only | eu data centers only | eu data centers only | eu data centers only | yes |
| ru | ru data centers only | ru data centers only | ru data centers only | ru data centers only | yes |
| airgapped | local isolated storage only | local isolated storage only | local isolated storage only | local isolated storage only | yes |

Типы данных: events, incidents, audit, attachments.

Правило блокировки при нарушении:
- если нарушение обнаружено на startup, Core не стартует (`startup fail`);
- если нарушение обнаружено при `POST /api/v1/profile/apply`, конфигурация отклоняется (`reject apply-config`);
- fallback на более мягкий профиль запрещён;
- дополнительно формируется `observability_gap.profile_violation`.
