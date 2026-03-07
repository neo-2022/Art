# Security Posture

## Source of truth (обязательно)
- `docs/security/*`
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `docs/source/checklists/CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

## Что Здесь Зафиксировано
- threat model и trust boundaries
- controls для supply chain: SBOM, signing, pinning
- policy-as-ui и границы RBAC/ABAC
- posture по audit trail и Merkle verification
- связь incident response с runbooks
- ingress/perimeter protection для hostile internet-facing среды

## Защитные Контуры

### 1. Supply chain и provenance
- SBOM;
- signing/verify;
- pinned dependencies и pinned CI actions;
- authenticity/copyright-safe baseline.

### 2. Trust boundary и identity
- `Core` не должен слепо доверять неутверждённым внешним заголовкам и контексту;
- agent/relay/bootstrap transport обязан прийти к защищённому baseline;
- privileged operations должны иметь отдельный audited path.

Что это означает practically:
- клиент не может сам назначить себе `actor_role=admin`;
- клиент не может включить `mcp_mode=full_admin`;
- `access_scope` не может приходить из query/header как готовая истина;
- `X-Forwarded-For` не считается истинным client IP без trusted proxy chain;
- при сомнении система должна fail-closed, а не “довериться для удобства”.

### 3. Ingress / perimeter defense
- app-level `429/503` не считается полноценной DDoS-защитой;
- internet-exposed deployments обязаны иметь front-door / edge / ingress shield;
- обязательны:
  - per-IP/per-source limiting;
  - per-tenant abusive traffic isolation для SaaS;
  - connection/burst limits;
  - runbooks и gap-события:
    - `observability_gap.ddos_suspected`
    - `observability_gap.ingress_shield_degraded`

### 4. Browser surface hardening
- Browser Level0, Panel0, Console и showcase/demo слой обязаны иметь единый browser security baseline;
- CSP, frame restrictions, browser security headers и asset provenance должны быть частью production baseline, а не “позднего hardening”;
- showcase/demo не имеет права ослаблять боевой browser security contour;
- при деградации browser policy должен возникать `observability_gap.browser_surface_policy_degraded`.

### 5. Privacy / evidence / audit
- evidence access должен быть policy-driven;
- redaction и scope enforcement не имеют права ослабляться ради удобства;
- audit trail должен фиксировать доступ, решение и доказательство.

### 6. Runtime resilience
- storage corruption, ingest overload, relay failure, spool corruption и другие hostile runtime paths не считаются второстепенными;
- production baseline должен уметь обнаруживать и переживать деградацию, а не только документировать happy-path.

### 7. Storage pressure / disk exhaustion protection
- защита storage не ограничивается backup и recovery после corruption;
- система обязана заранее видеть рост SQLite/WAL и свободного места на диске;
- должны существовать:
  - `high watermark`
  - `critical watermark`
  - резерв свободного места
  - controlled degraded mode до фактического `disk full`;
- сигналом этой деградации считается:
  - `observability_gap.storage_pressure_high`
- если storage почти заполнен, а система продолжает молча принимать запись до `SQLITE_FULL`, security posture считается нарушенным.

### 8. Startup configuration fail-closed
- компонент не имеет права переходить в `ready`, если его конфигурация опасна для production-профиля;
- unsafe-конфиг должен блокироваться до старта, а не после первой ошибки под нагрузкой;
- сигналом отказа является:
  - `observability_gap.unsafe_startup_config_refused`
- это защищает от ситуации, когда система сама запускается в уязвимом состоянии.

### 9. Queue integrity / duplicate / anti-loop
- очереди, backlog, replay и bridge path должны иметь budgets и anti-loop механизм;
- duplicate flood не считается “просто шумом”, а фиксируется как отдельный класс угрозы;
- защитный сигнал:
  - `observability_gap.queue_integrity_violation`
- цель этого слоя: не дать одной неисправной интеграции или одному шумному источнику quietly разрушить весь поток доставки.

### 10. Guard self-observability
- предохранитель, который сам сломан и не сообщает о своей деградации, не считается защитой;
- критичные guards обязаны иметь:
  - self-test
  - heartbeat
  - отдельный сигнал отказа
- защитный сигнал:
  - `observability_gap.guard_self_test_failed`
- release и stage closure должны блокироваться, если такой guard не проходит self-test.

## Что Это Решает
- не даёт выпускать наружу систему, у которой нет периметровой защиты;
- не позволяет путать перегрузку приложения с DDoS;
- не позволяет quietly дойти до переполнения storage и разрушения write-path;
- не даёт запускать production-компоненты в заведомо unsafe-конфигурации;
- снижает риск queue/replay loop, duplicate flood и runaway backlog;
- не даёт защитным механизмам silently умереть и оставить проект с ложной безопасностью;
- снижает риск того, что public-facing или SaaS deployment будет уничтожен простым flood/noisy-neighbor сценарием;
- делает security posture ближе к реальному hostile production, а не к бумажному baseline.
