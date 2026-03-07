# Ingress / Perimeter Protection v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/checklists/CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md`
- `docs/governance/observability_gap_registry.md`

Последняя актуализация: 2026-03-07
Статус: ACTIVE

## Назначение
Этот документ фиксирует обязательный защитный контур для internet-facing и межсегментных ingress-поверхностей Art.

Он нужен, чтобы:
- отделить обычный `backpressure` приложения от полноценной защиты от DDoS и hostile ingress;
- зафиксировать обязательный front-door / edge baseline;
- не позволить выпускать production-профиль, у которого публичный ingress не защищён на периметре.

## Базовый закон
`413/429/503 + retry_after_ms` внутри `art-core` — это защита уровня приложения от перегрузки.

Это **не считается** полноценной защитой от:
- DDoS;
- L4/L7 flood;
- abusive burst;
- connection exhaustion;
- noisy-neighbor abuse в multi-tenant режиме.

Если deployment доступен из недоверенной сети, production baseline обязан включать внешний ingress/perimeter shield.

## Обязательная архитектура для internet-exposed deployments
Для deployment-профилей, где ingress доступен:
- из Интернета;
- из недоверенных внешних сетей;
- из межсегментного routed контура;
- через публичный CDN / reverse-proxy / ingress-gateway,

обязателен следующий защитный слой:

1. Edge/front-door компонент:
- reverse proxy, ingress gateway, WAF или cloud edge слой;
- отдельный policy point до `art-core`.

2. Ограничения трафика:
- per-IP / per-source-key rate limit;
- connection limit;
- burst limit;
- request body size limit;
- header normalization и early reject для заведомо мусорного трафика.

3. Изоляция злоупотребления:
- per-tenant и per-identity throttling для SaaS;
- выделение trusted internal traffic отдельно от public ingress;
- controlled degraded/read-only mode без потери control-plane.

4. Наблюдаемость:
- метрики и журналы shield-слоя;
- корреляция shield events с `trace_id`/`source_key`/`tenant_id`, где это допустимо;
- gap-события при атаке и при деградации самого shield.

## Разрешённые модели deployment

### 1. Internal-only
Если Art развёрнут только во внутреннем trusted контуре:
- отдельный internet-edge shield не обязателен;
- но остаются обязательными app-level limits, auth boundary и basic reverse-proxy hygiene.

### 2. Internet-exposed / partner-exposed
Если ingress виден из внешней или частично недоверенной среды:
- shield обязателен;
- отсутствие shield считается release blocker.

### 3. Segmented / multi-site
Если ingress идёт через relay, gateway, DMZ или межсегментный proxy:
- boundary и limits обязательны на каждом ingress hop;
- недопустим blind tunnel напрямую в `art-core`.

## Обязательные защитные сигналы

### `observability_gap.ddos_suspected`
Генерируется, когда система видит признаки hostile ingress-поведения, которые вышли за пределы обычного business burst.

Обязательные поля evidence:
- `endpoint`
- `source_key`
- `current_rps`
- `current_connections`
- `limit_name`
- `shield_mode`
- `trace_id`

### `observability_gap.ingress_shield_degraded`
Генерируется, когда сам front-door / ingress shield деградировал или работает в сниженной защите.

Обязательные поля evidence:
- `shield_component`
- `endpoint`
- `failure_mode`
- `fallback_mode`
- `current_rps`
- `trace_id`

## Обязательные release-blockers
Release блокируется, если одновременно выполняется хотя бы одно условие:
1. deployment profile internet-exposed, но ingress shield policy не определена;
2. не существует runbook для `ddos_suspected` или `ingress_shield_degraded`;
3. нет hostile test, который доказывает работу ingress limits;
4. нет evidence, что shield и app-level backpressure согласованы;
5. SaaS-профиль не имеет per-tenant abusive traffic boundary.

## Привязка к программе

### Stage 12
- `art-core` должен различать обычную перегрузку приложения и подозрение на hostile ingress;
- `ddos_suspected` и `ingress_shield_degraded` обязательны.

### Stage 24
- release path обязан блокировать internet-exposed rollout без ingress shield baseline.

### Stage 36
- SaaS mode обязан иметь per-tenant abuse isolation и rate policies.

### Stage 37
- Linux production hardening обязан включать edge/perimeter reference architecture и runtime validate-path.

### Stage 45
- forensic enrichment обязан уметь отличать hostile ingress patterns от обычной нагрузки и давать объяснимую трассировку.

## Anti-patterns
Запрещено:
- считать `429/503` внутри приложения эквивалентом DDoS-защиты;
- публиковать `art-core` напрямую наружу без front-door policy;
- смешивать trusted internal traffic и public ingress в одной безлимитной поверхности;
- выпускать SaaS-профиль без abusive traffic isolation;
- не фиксировать attack/degradation события как gap-сигналы.

## Критерий PASS
Ingress/perimeter contour считается внедрённым только если одновременно:
- front-door/shield architecture определена;
- release-blockers задокументированы;
- gap events зарегистрированы;
- runbooks существуют;
- hostile-path tests подтверждают реальную работу ограничений;
- affected checklists и release gates синхронизированы.
