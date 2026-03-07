# Архитектурный обзор Art

## Source of truth
- [Art_v1_spec_final.md](source/Art_v1_spec_final.md)
- [FOUNDATION_CONSTITUTION_V0_2.md](source/FOUNDATION_CONSTITUTION_V0_2.md)
- [UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md](foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md)
- [CHECKLIST_00_MASTER_ART_REGART.md](source/checklists/CHECKLIST_00_MASTER_ART_REGART.md)
- [REGART -  LangGraph  взаимодействие с Art описание.md](source/REGART -  LangGraph  взаимодействие с Art описание.md)
- [defect_remediation_control_matrix_v0_2.md](testing/defect_remediation_control_matrix_v0_2.md)
- [defect_remediation_ladder_v0_2.md](testing/defect_remediation_ladder_v0_2.md)
- `formats/root_decision_tree_dependencies.yaml`

## Общая картина

Art строится как единый продукт с тремя архитектурными уровнями:
- Tier A: аварийный и degraded-интерфейс
- Tier B: основной операционный интерфейс расследования
- Tier C: SaaS и governance-слой

Базовый закон архитектуры: `Core` — единственный источник истины.  
Все остальные слои являются либо проекцией, либо транспортом, либо derived-хранилищем.

## Базовые runtime-компоненты

### art-core
- ingest, validation, normalization, rules, incidents, actions, audit
- snapshot и stream API
- хост для встроенного `Panel0`
- опорная точка release и certified profile
- corrective baseline `stage11` уже полностью закрыл durable SQLite basement: не только `events/incidents/audit`, но и `fingerprint/source indexes`, `dna/evidence` и analytics/counters; hostile backup/restore proof для полного состояния уже получен, backup-root разведен по `db_path`, backup cadence `15 минут` enforced в runtime самого `Core`, live corruption/read_only contour материализован end-to-end, live `kill -9 during ingest` chaos доказан как отдельный runtime-proof, `storage pressure / disk exhaustion` contour materialized с high/critical watermarks, `storage_disk_full`, archive/prune discipline и recovery после увеличения budget, stage-level concurrency proof зафиксирован отдельным runtime-evidence `8/4/10000`, а production-proof `VACUUM/systemd` подтверждён отдельным runtime smoke; downstream continuation этого basement остаётся уже в `stage23` и `stage37`

### art-agent
- сбор сигналов на уровне ОС и сервисов
- целевая модель — надёжная доставка через spool и outbox
- фактический runtime-контур доставки и relay/TLS basement остаётся corrective-зоной следующих стадий и не считается закрытым
- деградация должна фиксироваться явно, а не маскироваться

### browser / Level0
- браузерный backlog и capture path
- мост для клиентских и runtime-сигналов
- потеря доставки оформляется как evidence/gap, а не как тишина

## Продуктовые поверхности

### Tier A: Panel0
- аварийный встроенный UI внутри Core
- доступен при отказе Console
- показывает статус, gaps, evidence и fallback-путь операций

### Tier B: Console
- находится в `apps/console-web`
- использует только Core API и workspace packages
- покрывает Command Center, Event River, Incident Room, Audit Explorer, Investigation Library и Visual Flow Mode

### Tier C: SaaS Layer
- tenant isolation и policy boundary
- quota, retention и compliance rules
- release и операционное управление для hosted-модели

## Архитектурные законы
- Core является единственным источником истины
- evidence-first рендеринг обязателен
- degraded-path встроен в основную архитектуру
- переход к следующему этапу запрещён без подтверждённого закрытия текущего
- архитектурная документация обязана быть человекочитаемой: любой критичный архитектурный механизм должен быть объяснён так, чтобы его понял новый инженер и оператор, а не только автор исходной реализации
- платформенные различия разрешены только в packaging/install/runtime profiles, но не в бизнес-логике
- порядок remediation определяется корневым деревом решений, дефектовочной контрольной ведомостью и дефектовочной лестницей, а не “следующим номером этапа”
- defect-remediation control matrix задаёт поштучный corrective-контроль каждого дефекта, а дефектовочная лестница определяет порядок их исполнения по слоям
- архитектурные решения принимаются только по пути `корень -> ствол -> крона`
- hardcoding запрещён как архитектурный anti-pattern и допускается только как явно оформленный test fixture вне production baseline
- internet-exposed deployment без ingress/perimeter shield запрещён как архитектурный anti-pattern
- если нижний corrective-basement уже доведён и закрыт честно, активный corrective baseline обязан явно смещаться в следующий downstream stage; архитектурный обзор не имеет права оставлять проект “мысленно” в уже закрытом нижнем слое
- high-risk монолитные entrypoint-файлы считаются архитектурным долгом и должны разрезаться после стабилизации basement по defect-линии `DEF-017`
- рост высокорисковых entrypoint-файлов запрещён уже сейчас: до завершения `DEF-017/DEF-032` действует machine-readable budget и CI guard, который не позволяет дальше наращивать плотность в этих файлах
- string/render-only test corpus не считается достаточным архитектурным доказательством поведения; hostile integration/e2e hardening обязателен по defect-линии `DEF-018`

## Ingress / perimeter boundary
- app-level backpressure внутри `art-core` обязателен, но не считается полноценной DDoS-защитой;
- для internet-exposed и partner-exposed deployment-профилей обязателен front-door / edge / ingress shield;
- hostile ingress scenarios должны материализоваться не только в release/docs, но и в runbooks, observability gaps и validate-path.

## Trust boundary и browser surface
- доверительный actor-context должен рождаться в trusted auth / edge / relay контуре, а не в клиентских заголовках;
- `Core` не имеет права принимать `actor_role`, `mcp_mode`, `access_scope` и `client_ip` как security truth из недоверенного источника;
- browser surface (Browser Level0, Panel0, Console, showcase) обязана иметь единый security baseline:
  - CSP;
  - frame restrictions;
  - browser security headers;
  - asset integrity/provenance;
  - safe fallback при policy degradation.
- Эти два protective contour считаются обязательной частью архитектуры hostile production среды, а не поздним hardening.

## Граница с REGART
- Art и REGART остаются отдельными репозиториями
- границы контрактов, событий и runtime-поведения жёстко определены
- Console не встраивается в REGART
- интеграция идёт через transport, events, Level0 и операционные контракты
- доказательство readiness этой границы допускается только через pinned external adversarial harness, а не через floating local checkout.

Детальный интеграционный слой: [INTEGRATION.md](INTEGRATION.md)
