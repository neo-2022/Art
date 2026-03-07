# Runbook: agent_identity_untrusted

## Что это означает
`Art` не доверяет агенту или relay-цепочке и поэтому не должен считать такой источник trusted.

## Что проверить
1. `agent_id` и `site_id`.
2. enrollment token / certificate.
3. relay path и его trust status.
4. не истёк ли credential.

## Что делать
1. Остановить trust этого агента.
2. Перепройти enrollment.
3. Проверить revocation и rotation.
4. Убедиться, что relay принадлежит ожидаемой цепочке доверия.

## Проверка восстановления
- агент снова проходит trusted enrollment;
- события приходят как trusted, без active identity gap.
