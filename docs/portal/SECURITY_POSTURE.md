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

### 4. Privacy / evidence / audit
- evidence access должен быть policy-driven;
- redaction и scope enforcement не имеют права ослабляться ради удобства;
- audit trail должен фиксировать доступ, решение и доказательство.

### 5. Runtime resilience
- storage corruption, ingest overload, relay failure, spool corruption и другие hostile runtime paths не считаются второстепенными;
- production baseline должен уметь обнаруживать и переживать деградацию, а не только документировать happy-path.

## Что Это Решает
- не даёт выпускать наружу систему, у которой нет периметровой защиты;
- не позволяет путать перегрузку приложения с DDoS;
- снижает риск того, что public-facing или SaaS deployment будет уничтожен простым flood/noisy-neighbor сценарием;
- делает security posture ближе к реальному hostile production, а не к бумажному baseline.
