# Fingerprint

- canonical_json: JSON с отсортированными ключами.
- Исключения полей: временные (`ts`, `received_at`) и UI-рендер поля.
- hash: sha256(canonical_json).

## collision detection
Collision фиксируется, если fingerprint одинаковый, а canonical_json (без ts) различается.
Событие: `data_quality.fingerprint_collision_suspected`.
