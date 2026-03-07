# On-call процесс

Source of truth:
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/roles_raci.md`
- `docs/governance/severity.md`
- `docs/governance/incident_process.md`

## Назначение

Документ фиксирует текущий operating model дежурств Art. Он обязателен для incident handling, релизных окон и эскалаций `observability_gap.*`. Если дежурство не определено или handover не оформлен, on-call считается невалидным.

## Текущая схема дежурств

- `Primary on-call`: `@neo-2022`
- `Secondary / witness`: `@2art260679-rgb`
- Ротация: недельная, с понедельника `09:00 MSK` до следующего понедельника `09:00 MSK`
- Минимальный состав активного окна: один `primary` и один `secondary`
- Если `secondary` недоступен, это фиксируется в handover log до начала окна

## Каналы оповещений

### Основные

- Incident chat / bridge: `Art Incident Bridge`
- GitHub incident issue: создаётся по шаблону `incident`
- PR / release thread: для релизных блокеров

### Срочные

- `SEV0` и `SEV1`: звонок или push/pager обязателен
- `SEV2`: incident chat + mention `@neo-2022`
- `SEV3`: task / issue + запись в handover backlog

## Контакты для эскалации

| Сценарий | Primary contact | Secondary contact | Канал |
|---|---|---|---|
| Общий production incident | `@neo-2022` | `@2art260679-rgb` | `Art Incident Bridge` + incident issue |
| Release blocker | `@neo-2022` | `@2art260679-rgb` | release thread + incident bridge |
| Security / supply-chain blocker | `@neo-2022` | `@2art260679-rgb` | security review trail + incident bridge |
| Checklist truthfulness / false green | `@neo-2022` | `@2art260679-rgb` | PR review + incident issue при влиянии на prod |

## Порядок передачи смены (handover)

Передача смены обязательна в начале и в конце каждого on-call окна.

### Вход в смену

1. Проверить открытые incidents и их severity.
2. Проверить активные release blockers и незавершённые rollback risks.
3. Проверить незакрытые `observability_gap.*`, требующие наблюдения.
4. Проверить статус обязательных CI gates и ночных прогонов.
5. Зафиксировать handover в log.

### Выход из смены

1. Передать список открытых инцидентов с owner и next action.
2. Передать follow-ups и временные mitigations.
3. Передать незакрытые риски релизного окна.
4. Передать отключённые или деградированные automation paths.
5. Получить подтверждение от принимающего дежурство.

## Формат handover log

Каждый handover должен содержать минимум:

- `handover_at`
- `from`
- `to`
- `open_incidents`
- `release_blockers`
- `active_observability_gaps`
- `disabled_automation`
- `next_review_at`

Рекомендуемое место фиксации:
- evidence trail в `docs/governance/evidence/`, если handover связан с релизом или инцидентом;
- issue / incident thread, если handover относится к активному инциденту.

## Правила эскалации по severity

| Severity | Срок реакции | Что делает primary | Когда эскалировать |
|---|---|---|---|
| `SEV0` | немедленно | открывает incident bridge, назначает Incident Commander, фиксирует mitigation | сразу Owner + Security + Release |
| `SEV1` | до 15 минут | проводит triage, запускает runbook, фиксирует public/internal status | если нет mitigation за 15 минут или затронут release path |
| `SEV2` | до 60 минут | оценивает масштаб, назначает task/follow-up, уведомляет owner | если деградация растёт или затрагивает ingest/spool/storage |
| `SEV3` | в рабочее окно | оформляет backlog / task / runbook update | если повторяемость > порога из SLO/runbook policy |

## Правила для observability_gap

- Любой `observability_gap.*` обязан быть замечен в snapshot/stream и попасть в triage queue.
- Любые `ingest/*`, `spool/*`, `storage/*` gaps сразу считаются on-call сигналом и требуют реакции не ниже `SEV1`.
- Если gap влияет на release evidence, он автоматически становится release blocker до явного решения.

## Недопустимые состояния

- нет назначенного `primary on-call`;
- handover не оформлен;
- `SEV0/SEV1` обрабатывается только текстовым сообщением без звонка/pager;
- release выполняется без доступного on-call;
- security blocker остаётся без явного escalation owner.

## Критерий актуальности

Документ считается актуальным только если:

- указаны `primary` и `secondary`;
- перечислены каналы оповещений;
- есть порядок handover;
- есть контакты для эскалации;
- severity-эскалация согласована с `severity.md` и `incident_process.md`.
