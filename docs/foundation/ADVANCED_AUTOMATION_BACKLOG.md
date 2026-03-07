# Advanced Automation Backlog (Art)

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/foundation/revolutionary_hypotheses.md`
- `docs/foundation/frontier_tech_radar.md`

Последняя актуализация: 2026-03-06
Статус: ACTIVE BACKLOG

## 1. Назначение
Собрать в одном месте продвинутые механизмы автоматизации, которые должны повысить зрелость Art сверх обычного CI/CD уровня.

## 2. Почему это важно
Art слишком велик и слишком строг по требованиям, чтобы полагаться только на ручную дисциплину. Продвинутая автоматизация нужна не для красоты, а чтобы:
- не терять концепции;
- не расходились contracts/tests/docs;
- не расползались UI-laws;
- DNA не деградировал скрыто;
- платформа выдерживала рост сложности.

## 3. Backlog направлений

### 3.1 AST-driven UI law enforcement
Смысл:
- проверять `tooltip everywhere`, `one-click-to-evidence`, `claim without evidence` на уровне AST/типов.

Польза:
- раньше ловятся ошибки;
- меньше reliance на runtime-only проверки;
- выше дисциплина фронтенда.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`

### 3.2 Self-healing tests from contract diff
Смысл:
- при изменении OpenAPI/JSON Schema автоматически выявлять, какие тесты нужно обновить.

Польза:
- меньше ложных падений;
- быстрее поддержка v1/v2 API;
- ниже стоимость evolution.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md`
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`

### 3.3 Docs-from-code / docs-from-tests pipeline
Смысл:
- извлекать из кода и тестов примеры, инварианты и usage fragments для документации.

Польза:
- docs меньше устаревают;
- примеры становятся живыми;
- снижается ручная нагрузка на docs maintenance.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`

### 3.4 eBPF evidence linking
Смысл:
- дополнять evidence системными следами Linux.

Польза:
- усиливает forensic depth;
- делает расследование убедительнее;
- даёт продукту редкий differentiator.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

### 3.5 Contract live-verification / fingerprint monitoring
Смысл:
- контролировать drift контрактов не только в CI, но и на runtime-потоках и release artifacts.

Польза:
- раньше обнаруживается расхождение между схемами и поведением;
- легче держать v1/v2 в совместимости.

Статус:
- trial/approved backlog.
Checklist mapping:
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md`
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`

### 3.6 Deterministic replay twins
Смысл:
- строить воспроизводимую twin-среду для DNA/investigation/action replay.

Польза:
- сильнее RCA;
- безопаснее обучение;
- выше доверие к replay assertions.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`
- `CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md`

### 3.7 Policy-aware test adaptation
Смысл:
- при изменении policy/rbac/redaction автоматически пересобирать матрицу тестов разрешений и отказов.

Польза:
- ниже риск непокрытых policy regression;
- лучше Zero-Trust discipline.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`

### 3.8 Evidence-backed release narratives
Смысл:
- автоматически собирать клиентский progress narrative из evidence ledger, delivery artifacts и release decisions.

Польза:
- заказчик видит не просто commit history, а доказательный прогресс;
- легче показывать зрелость проекта вовне.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`

### 3.9 Wasm sandbox for actions
Смысл:
- выполнять расширяемые действия в безопасной песочнице.

Польза:
- безопаснее automation;
- расширяемость без пробития runtime boundaries.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md`

### 3.10 Graph-backed DNA exploration
Смысл:
- добавить graph-native исследование связей DNA/evidence/incidents/actions.

Польза:
- сильнее relationship navigation;
- лучше поиск похожих причинных цепочек.

Статус:
- approved backlog.
Checklist mapping:
- `CHECKLIST_29_EVENT_DNA_CORE_V2.md`
- `CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md`

## 4. Контроль полноты идей из истории обсуждений
Этот backlog нужен в том числе для того, чтобы предложения из утверждённых чатов и review-итераций не терялись между разговорами, README, foundation и checklist execution.

Текущий вывод после повторной сверки истории:
- основные крупные предложения по глубокой автоматизации уже перенесены сюда;
- если новая идея из чата не получает записи в этом backlog или в `revolutionary_hypotheses.md`, она считается потерянной для программы.

## 5. Правило внедрения
Ни один пункт из этого backlog не считается внедрённым, пока он не получит:
1. foundation mapping;
2. checklist mapping;
3. verification path;
4. evidence или gate;
5. честный статус mandatory/experimental/deferred.
