# Protective Safeguards Catalog v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `formats/protective_safeguards_catalog_v0_2.yaml`

## Назначение
Этот каталог фиксирует все обязательные предохранители проекта как единый защитный слой.

Он нужен, чтобы:
- не терять защитные механизмы между обсуждениями, аудитом и remediation;
- не путать уже материализованные контуры с идеями;
- быстро видеть, какой предохранитель от чего защищает, где он задокументирован, какими `observability_gap.*` событиями подтверждается и какими stage-листами контролируется.

## Список обязательных предохранителей

### 1. Ingress / perimeter anti-DDoS
- Назначение: не дать internet-facing или partner-facing контуру быть уничтоженным flood-атакой или abusive ingress.
- Базовый документ: `docs/source/ingress_perimeter_protection_v0_2.md`
- Gap-события:
  - `observability_gap.ddos_suspected`
  - `observability_gap.ingress_shield_degraded`
- Основные stages: `12`, `24`, `36`, `37`, `45`

### 2. Trust boundary / canonical actor context
- Назначение: не дать системе поверить поддельному actor-context, ролям, scope и audit identity.
- Базовый документ: `docs/source/trust_boundary_hardening_v0_2.md`
- Gap-событие:
  - `observability_gap.trust_boundary_violation`
- Основные stages: `15`, `24`, `33`, `37`

### 3. Browser surface hardening
- Назначение: не дать Browser Level0, Panel0, Console и showcase стать слабой точкой проекта.
- Базовый документ: `docs/source/browser_surface_hardening_v0_2.md`
- Gap-событие:
  - `observability_gap.browser_surface_policy_degraded`
- Основные stages: `10`, `16`, `24`, `28`, `37`, `40`

### 4. Connected system visibility
- Назначение: не дать интеграции считаться "подключённой" без реальной операторской видимости и declared-vs-observed truth.
- Базовый документ: `docs/source/connected_system_visibility_v0_2.md`
- Gap-события:
  - `observability_gap.connected_system_not_visible`
  - `observability_gap.connected_system_coverage_drift`
- Основные stages: `18`, `19`, `20`, `28`

### 5. Pinned external adversarial harness
- Назначение: не дать external integration proof жить на floating checkout и неповторяемом внешнем окружении.
- Базовый документ: `docs/source/regart_adversarial_integration_harness_v0_2.md`
- Основные stages: `05`, `06`, `20`, `24`, `38`

### 6. Storage pressure / disk exhaustion protection
- Назначение: не дать `Core` и его SQLite/WAL quietly погибнуть от долгого роста storage и `disk full`.
- Базовый документ: `docs/source/storage_pressure_protection_v0_2.md`
- Gap-событие:
  - `observability_gap.storage_pressure_high`
- Основные stages: `11`, `12`, `24`, `37`

### 7. Startup configuration fail-closed
- Назначение: не дать системе стартовать в опасной конфигурации и только потом уже ломаться под нагрузкой.
- Базовый документ: `docs/source/startup_config_safety_validator_v0_2.md`
- Gap-событие:
  - `observability_gap.unsafe_startup_config_refused`
- Основные stages: `12`, `18`, `24`, `37`

### 8. Queue integrity / duplicate / anti-loop protection
- Назначение: не дать очередям, backlog и event-pipeline разрастись, дублироваться или зациклиться.
- Базовый документ: `docs/source/queue_integrity_protection_v0_2.md`
- Gap-событие:
  - `observability_gap.queue_integrity_violation`
- Основные stages: `12`, `17`, `18`, `24`, `37`

### 9. Guard self-observability / self-test
- Назначение: не дать защитному контуру silently умереть и остаться только на бумаге.
- Базовый документ: `docs/source/guard_self_observability_v0_2.md`
- Gap-событие:
  - `observability_gap.guard_self_test_failed`
- Основные stages: `24`, `37`, `38`

### 10. Action execution safety guard
- Назначение: не дать destructive или high-impact действию выполниться только потому, что схема запроса формально валидна.
- Простыми словами:
  - система должна уметь сказать: "действие технически возможно, но выполнять его ещё нельзя";
  - перед опасным действием должны быть policy checks, preflight, bounded-regret или явное ручное исключение.
- Базовый документ: `docs/source/action_execution_safety_guard_v0_2.md`
- Gap-событие:
  - `observability_gap.action_safety_guard_blocked`
- Основные stages: `15`, `24`, `33`, `37`, `43`

### 11. Agent identity / enrollment / relay trust
- Назначение: не дать неизвестному, подменённому или чужому агенту стать "доверенным источником" только потому, что он умеет отправлять события.
- Простыми словами:
  - агент должен не только стучаться в `Core`, но и доказывать, кто он, где он и почему ему можно доверять.
- Базовый документ: `docs/source/agent_identity_enrollment_trust_v0_2.md`
- Gap-событие:
  - `observability_gap.agent_identity_untrusted`
- Основные stages: `18`, `23`, `37`

### 12. Release truth enforcement
- Назначение: не дать релизному контуру говорить больше, чем реально доказано текущим кодом, CI, evidence и runtime.
- Простыми словами:
  - релиз не может быть "красивой бумагой"; всё, что обещано в `GO/NO-GO`, `README`, `CHANGELOG` и release evidence, должно быть подтверждено.
- Базовый документ: `docs/source/release_truth_enforcement_v0_2.md`
- Gap-событие:
  - `observability_gap.release_truth_mismatch`
- Основные stages: `04`, `07`, `24`, `38`

### 13. Authenticity / copyright-safe baseline
- Назначение: не дать проекту тихо впитать чужие спорные assets, медиа, тексты и демонстрационные сущности.
- Простыми словами:
  - всё, что попадает в baseline проекта, должно иметь понятное и безопасное происхождение.
- Базовый документ: `docs/source/authenticity_baseline_v0_2.md`
- Gap-событие:
  - `observability_gap.authenticity_policy_violation`
- Основные stages: `04`, `07`, `19`, `20`, `28`, `37`, `40`

### 14. Regulatory claims drift control
- Назначение: не дать проекту заявлять "сертифицировано", "поддерживается", "готово для регулятора" там, где это не доказано evidence и runtime.
- Простыми словами:
  - обещания по ФСТЭК, Astra, RED OS, RU profile и regulated deployment должны быть честными и проверяемыми.
- Базовый документ: `docs/source/regulatory_claims_drift_control_v0_2.md`
- Gap-событие:
  - `observability_gap.regulatory_claim_drift`
- Основные stages: `25`, `26`, `37`, `38`

### 15. Monolith budget guard
- Назначение: не дать ключевым entrypoint-файлам и runtime-модулям перерасти в тяжёлый монолит, который опасно менять.
- Простыми словами:
  - это предохранитель от "код знает только один человек" и "любой фикс ломает всё вокруг".
- Базовый документ: `docs/source/monolith_budget_guard_v0_2.md`
- Machine-readable бюджет: `formats/monolith_budget_guard_v0_2.yaml`
- Автоматический guard: `scripts/ci/check_monolith_budget_guard.sh`
- Gap-событие:
  - `observability_gap.monolith_budget_exceeded`
- Основные stages: `10`, `11`, `17`, `18`, `28`, `35`, `37`, `39`

### 16. Test strength guard
- Назначение: не дать проекту жить на красивых, но слабых тестах, которые не держат hostile production реальность.
- Простыми словами:
  - если у важного контура есть только `grep`, snapshot или HTML includes, такой контур считается недозащищённым.
- Базовый документ: `docs/source/test_strength_guard_v0_2.md`
- Gap-событие:
  - `observability_gap.test_strength_guard_failed`
- Основные stages: `10`, `16`, `22`, `24`, `28`, `34`, `36`, `38`

### 17. Documentation drift control
- Назначение: не дать корню, стволу, README, overview-страницам и stage-документам разъехаться между собой.
- Простыми словами:
  - если документ изменился, проект должен вовремя понять, какие зависимые документы теперь тоже нужно скорректировать.
- Базовый документ: `docs/source/documentation_drift_control_v0_2.md`
- Gap-событие:
  - `observability_gap.documentation_drift_detected`
- Основные stages: `07`, `24`, `28`, `38`

## Жёсткое правило
Предохранитель не считается существующим, если он:
- описан только в docs;
- не имеет `observability_gap.*` события или явного blocker-механизма;
- не привязан к stage-листам;
- не проходит guard-проверку в CI.

## Связанные runbooks
- `docs/runbooks/ddos_suspected.md`
- `docs/runbooks/ingress_shield_degraded.md`
- `docs/runbooks/trust_boundary_violation.md`
- `docs/runbooks/browser_surface_policy_degraded.md`
- `docs/runbooks/connected_system_not_visible.md`
- `docs/runbooks/storage_pressure_high.md`
- `docs/runbooks/unsafe_startup_config_refused.md`
- `docs/runbooks/queue_integrity_violation.md`
- `docs/runbooks/guard_self_test_failed.md`
- `docs/runbooks/action_safety_guard_blocked.md`
- `docs/runbooks/agent_identity_untrusted.md`
- `docs/runbooks/release_truth_mismatch.md`
- `docs/runbooks/authenticity_policy_violation.md`
- `docs/runbooks/regulatory_claim_drift.md`
- `docs/runbooks/monolith_budget_exceeded.md`
- `docs/runbooks/test_strength_guard_failed.md`
- `docs/runbooks/documentation_drift_detected.md`
