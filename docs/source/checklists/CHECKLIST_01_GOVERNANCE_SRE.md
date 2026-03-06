A) Полный запрет опциональности:
# CHECKLIST 01 — Governance/SRE
Файл: CHECKLIST_01_GOVERNANCE_SRE.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение SLO/SLI; появление новых `observability_gap.*`; изменение политики MCP; изменение требований аудита actions

## Цель
Определить управляемый процесс эксплуатации и разработки: роли, инциденты, эскалации, постмортемы, change management, SLO/SLI, MCP-режимы, политика аудита действий (Actions/Audit), требования к доказательствам проверок, и enforce-механизмы репозитория.

## Границы
Только процессные артефакты и enforce-механизмы репозитория:
- документы (RU)
- шаблоны PR/Issues
- CODEOWNERS
- правила main-ветки (branch protection) с фиксацией доказательств в репозитории
- CI gate для Stage 01 (проверка наличия и минимального содержания ключевых документов)

## Зависимости
- CHECKLIST_00_MASTER_ART_REGART.md (единые правила формата, запрет двусмысленностей, правило `observability_gap.*`)

## Шаги (строго линейно)

> Правило фиксации незакрытого пункта: под пунктом добавляется подпункт в формате “причина → фикс → критерий готовности”.

1. [x] **Сделать:** Создать RACI матрицу ролей проекта: Owner, Maintainer, Reviewer, On-call, Security, Release.
   - [x] причина → фикс → критерий готовности: в текущей матрице нет явного перечня ответственных по ролям; добавить владельцев ролей и PASS после проверки содержимого.  
   **Проверка (pass/fail):** существует файл `docs/governance/roles_raci.md`, содержит таблицу RACI и ответственных по ролям.

2. [x] **Сделать:** Описать on-call процесс: расписание дежурств, канал оповещений, порядок передачи смены, контакты для эскалации.
   - [x] причина → фикс → критерий готовности: в документе нет конкретных контактов эскалации; добавить контакты/каналы и PASS после повторной проверки.  
   **Проверка (pass/fail):** существует файл `docs/governance/oncall.md`, содержит расписание, канал оповещений, порядок handover, контакты эскалации.

3. [x] **Сделать:** Ввести таксономию severity SEV0–SEV3 с формальными критериями и SLA реакции.  
   **Проверка (pass/fail):** существует файл `docs/governance/severity.md`, содержит:
   - определения SEV0–SEV3
   - время реакции (минуты)
   - требования по коммуникации для каждого уровня

4. [x] **Сделать:** Описать incident lifecycle: detect → triage → mitigate → resolve → postmortem → follow-ups.
   - [x] причина → фикс → критерий готовности: lifecycle описан без явных правил открытия/закрытия инцидента; дополнить и проверить по тексту документа.  
   **Проверка (pass/fail):** существует файл `docs/governance/incident_process.md`, содержит шаги lifecycle, роли в инциденте (Incident Commander, Communications, Scribe), правила открытия и закрытия инцидента.

5. [x] **Сделать:** Зафиксировать правила регистрации и эскалации `observability_gap.*`:
   - [x] причина → фикс → критерий готовности: раздел escalation слишком общий и не фиксирует auto-incident для ingest/spool/storage с min SEV1; привести к точным правилам шага и перепроверить.
   - любое событие `observability_gap.*` обязательно регистрируется и должно быть видимо в snapshot/stream (не “тихо пропускаться”);
   - события, связанные с доставкой/хранением (`ingest/*`, `spool/*`, `storage/*`), автоматически порождают инцидент с severity не ниже SEV1;
   - остальные `observability_gap.*` порождают инцидент только по правилам, определённым в реестре (поле `incident_rule`) и согласованным с политикой severity.  
   **Проверка (pass/fail):** в `docs/governance/incident_process.md` присутствует раздел `observability_gap escalation`, содержит:
   - требование обязательной регистрации всех `observability_gap.*` (snapshot/stream)
   - правило автоматического инцидента для `ingest/spool/storage` с min severity SEV1
   - ссылку на реестр `docs/governance/observability_gap_registry.md` как источник `incident_rule`
   - требование `action_ref` (ссылка на runbook) для каждого случая, где создаётся инцидент

6. [x] **Сделать:** Создать реестр `observability_gap.*` (единый список допустимых `observability_gap.*` событий) с обязательными полями для каждой записи:
   - `event_name` (уникальное имя, например `observability_gap.spool_corrupted`)
   - `description` (what/where/why)
   - `evidence_min` (минимум: тип ошибки, контекст, счётчики/метрики)
   - `actions` (включая `action_ref` со ссылкой на runbook в репозитории)
   - `owner_component` (конкретный компонент-источник: например `agent/spool`, `ui_proxy`, `ui/level0`, `browser/level0`)
   - `owner_role` (роль-владелец по RACI)
   - `incident_rule` (enum): `no_incident` | `create_incident` | `create_incident_min_sev0` | `create_incident_min_sev1` | `create_incident_min_sev2` | `create_incident_min_sev3`
   - `example` (пример генерации или ссылка на тест/воспроизводимый сценарий)  
   **Проверка (pass/fail):** существует файл `docs/governance/observability_gap_registry.md`, и в нём:
   - есть перечень `observability_gap.*` с уникальными именами
   - для каждой записи присутствуют все поля из списка выше
   - для всех записей с `incident_rule != no_incident` присутствует `action_ref` на runbook в `docs/runbooks/`

7. [x] **Сделать:** Описать runbook-структуру и минимальные требования к runbook для каждого случая, где создаётся инцидент (по `observability_gap.*` и по SLO breach).  
   **Проверка (pass/fail):** существует файл `docs/governance/runbook_policy.md`, содержит:
   - обязательные разделы runbook (symptoms, checks, mitigations, rollback, verification, escalation)
   - правило хранения runbook в `docs/runbooks/`
   - ссылочный формат `action_ref` (путь на runbook в репозитории)

8. [x] **Сделать:** Зафиксировать SLO/SLI с численными целями и окном измерения для минимум следующих SLI:
   - `ingest_success_rate`
   - `spool_backlog_age_sec`
   - `dlq_size`
   - `stream_lag_ms`  
   **Проверка (pass/fail):** существует файл `docs/governance/slo_sli.md`, содержит для каждого SLI:
   - определение метрики
   - окно измерения
   - численную цель
   - источник данных (метрика/лог/счётчик)

9. [x] **Сделать:** Привязать нарушение SLO к созданию инцидента, severity и действию (runbook).  
   **Проверка (pass/fail):** в `docs/governance/slo_sli.md` присутствует таблица `SLO breach mapping`, и каждая строка содержит:
   - условие нарушения
   - severity (SEV0–SEV3)
   - `action_ref` (обязательная ссылка на runbook)
   - `incident_rule` (enum): `create_incident` | `create_incident_min_sev0` | `create_incident_min_sev1` | `create_incident_min_sev2` | `create_incident_min_sev3`
   и правило: любое SLO breach из таблицы порождает инцидент согласно `incident_rule`.

10. [x] **Сделать:** Ввести error budget политику: поведение при исчерпании бюджета ошибок.  
    **Проверка (pass/fail):** существует файл `docs/governance/error_budget_policy.md`, содержит:
    - правило заморозки рискованных изменений
    - список разрешённых типов изменений
    - критерии снятия заморозки

11. [x] **Сделать:** Описать blameless postmortem политику и шаблон постмортема (RU).  
    **Проверка (pass/fail):** существуют файлы:
    - `docs/governance/postmortem_policy.md` (сроки, обязательность, owner follow-ups)
    - `docs/governance/postmortem_template.md` (шаблон с разделами impact/timeline/root cause/what went well/what went wrong/actions/evidence)

12. [x] **Сделать:** Описать change management политику: только PR в main, обязательный review, запрет прямых коммитов в main, ссылки на чек-лист этапа, требования к описанию изменений.
   - [x] причина → фикс → критерий готовности: policy не фиксирует минимум 1 reviewer из CODEOWNERS; дополнить и проверить по документу.  
    **Проверка (pass/fail):** существует файл `docs/governance/change_policy.md`, содержит:
    - запрет прямых коммитов в main
    - требования к PR (описание, ссылка на этап, evidence)
    - требования к review (минимум 1 reviewer из CODEOWNERS)

13. [x] **Сделать:** Внедрить enforce-артефакты репозитория: CODEOWNERS и PR template.  
    **Проверка (pass/fail):** существуют файлы:
    - `.github/CODEOWNERS`
    - `.github/pull_request_template.md`
    и PR template содержит секцию `Evidence` с обязательным заполнением.

14. [x] **Сделать:** Внедрить issue templates: incident и bug.  
    **Проверка (pass/fail):** существуют файлы:
    - `.github/ISSUE_TEMPLATE/incident.yml`
    - `.github/ISSUE_TEMPLATE/bug.yml`
    и incident template содержит обязательные поля:
    - `severity`
    - `impact`
    - `timeline`
    - `action_ref`
    - `evidence`
    - `related_gap` (обязательное): имя события из реестра `observability_gap_registry.md` или значение `none`

15. [ ] **Сделать:** Зафиксировать доказательство branch protection для main в репозитории.
   - [ ] причина → фикс → критерий готовности: текущий PNG-пруф является 1x1 placeholder, а evidence недостаточно; заменить реальным доказательством и проверить артефакты.  
    **Проверка (pass/fail):** существует файл `docs/governance/repo_protection_evidence.md`, содержит:
    - дату проверки
    - ссылку на PR, которым включены правила
    - скриншот-пруф в репозитории (png в `docs/governance/evidence/branch_protection_main.png`)
    и включает пункты: required reviews, required status checks, запрет force-push.

16. [x] **Сделать:** Описать release процесс: версия, changelog, тегирование, rollback.  
    **Проверка (pass/fail):** существует файл `docs/governance/release_process.md`, содержит:
    - правила versioning
    - формат changelog
    - шаги release
    - шаги rollback
    - требование smoke-check после release

17. [x] **Сделать:** Описать policy MCP режимов: enable флаг, режимы `read_only`, `limited_actions`, `full_admin`; запреты действий в `read_only`.
   - [x] причина → фикс → критерий готовности: в `limited_actions` нет явного перечня разрешённых action; добавить allowlist и проверить содержимое.  
    **Проверка (pass/fail):** существует файл `docs/governance/mcp_modes.md`, содержит:
    - default: enable=false
    - запрет execute action при mode=read_only
    - список разрешённых action при mode=limited_actions (перечень)
    - правило допуска full_admin (роль + аудит)

18. [x] **Сделать:** Описать политику аудита действий (Actions/Audit):
   - [x] причина → фикс → критерий готовности: поле `actor` не раскрыто как роль/идентификатор, требуется доведение до точного контракта шага; после правки повторить проверку.
    - все выполнения actions (автоматические по правилам, ручные через UI/API, MCP-команды) фиксируются в неизменяемом журнале;
    - журнал содержит минимум: `timestamp`, `actor` (роль/идентификатор), `action`, `target`, `result`, `evidence_ref` (ссылка на evidence);
    - срок хранения аудита: не менее 1 года;
    - запрещена модификация или удаление записей аудита.  
    **Проверка (pass/fail):** существует файл `docs/governance/audit_policy.md`, содержит все требования из списка выше в явном виде.

19. [x] **Сделать:** Описать policy обработки уязвимостей: каналы репорта, triage, сроки реакции по severity, фиксация в issues.
   - [x] причина → фикс → критерий готовности: текущая policy не фиксирует явное отражение кейсов в issues/трекере в терминах шага; дополнить и перепроверить.  
    **Проверка (pass/fail):** существуют файлы:
    - `SECURITY.md`
    - `docs/governance/vulnerability_process.md`

20. [x] **Сделать:** Описать evidence policy для проверок чек-листов и для инцидентов.  
    **Проверка (pass/fail):** существует файл `docs/governance/evidence_policy.md`, содержит:
    - формат доказательств для чек-листа (команды, логи, скрины, ссылки на PR)
    - формат доказательств для инцидента (evidence snapshot, ссылки, артефакты)
    - правило хранения артефактов в `docs/governance/evidence/`

21. [x] **Сделать:** Провести tabletop exercise по двум сценариям и зафиксировать результат:
    - `observability_gap` (Art unreachable)
    - `SLO breach` (`spool_backlog_age_sec` превышен)  
    Дополнительное правило выполнения: tabletop exercise проводится:
    - не реже 1 раза в квартал
    - после каждого SEV0 или SEV1 инцидента
    - после изменения, влияющего на `observability_gap.*` или на расчёт/порог SLO/SLI  
    **Проверка (pass/fail):** существует файл `docs/governance/tabletop_exercise.md`, содержит:
    - дату проведения
    - сценарий
    - таймлайн действий
    - принятые решения
    - ссылки на runbook
    - итоговые follow-ups
    и содержит записи минимум для двух сценариев, указанных выше.

22. [x] **Сделать:** Добавить CI gate, который валидирует Stage 01:
    - наличие governance-артефактов и enforce-файлов
    - минимальное содержание ключевых документов (разделы/таблицы/поля)  
    **Проверка (pass/fail):** существует исполняемый скрипт `scripts/ci/check_governance_stage01.sh` и он запускается в CI workflow; скрипт:
    - проверяет существование всех обязательных файлов (см. “Документация”)
    - проверяет минимальный контент:
      - `docs/governance/incident_process.md` содержит строку `observability_gap escalation`
      - `docs/governance/slo_sli.md` содержит строку `SLO breach mapping` и встречается `action_ref` и `incident_rule`
      - `docs/governance/observability_gap_registry.md` содержит поля `event_name`, `owner_component`, `owner_role`, `incident_rule`, `example`, `action_ref`
      - `docs/governance/audit_policy.md` содержит строки `immutable` (или RU-формулировку “неизменяемый”), `timestamp`, `actor`, `action`, `target`, `result`, `evidence_ref`, и `1 year` (или RU-формулировку “не менее 1 года”)
    - завершается с кодом 0 на зелёном состоянии и с кодом 1 при нарушении любой проверки.

## Документация (RU)
- docs/governance/roles_raci.md
- docs/governance/oncall.md
- docs/governance/severity.md
- docs/governance/incident_process.md (с обязательным разделом `observability_gap escalation`, см. шаг 5)
- docs/governance/observability_gap_registry.md (с обязательными полями, см. шаг 6)
- docs/governance/runbook_policy.md
- docs/governance/slo_sli.md (с таблицей `SLO breach mapping`, см. шаг 9)
- docs/governance/error_budget_policy.md
- docs/governance/postmortem_policy.md
- docs/governance/postmortem_template.md
- docs/governance/change_policy.md
- docs/governance/repo_protection_evidence.md
- docs/governance/release_process.md
- docs/governance/mcp_modes.md
- docs/governance/audit_policy.md (политика неизменяемого аудита actions, см. шаг 18)
- docs/governance/vulnerability_process.md
- docs/governance/evidence_policy.md
- docs/governance/tabletop_exercise.md
- docs/runbooks/ (папка с runbook-файлами, на которые ссылается `action_ref`)
- docs/governance/evidence/branch_protection_main.png
- scripts/ci/check_governance_stage01.sh
- .github/CODEOWNERS
- .github/pull_request_template.md
- .github/ISSUE_TEMPLATE/incident.yml
- .github/ISSUE_TEMPLATE/bug.yml
- SECURITY.md

## Тестирование
- unit: не требуется
- integration: не требуется
- e2e: tabletop exercise (шаг 21)
- chaos: не требуется
- load: не требуется
- soak: не требуется

## CI gate
- Запуск `scripts/ci/check_governance_stage01.sh` в workflow CI для каждого PR в main.

## DoD
- Все пункты 1–22 отмечены [x] после фактической проверки.
- Все файлы из раздела “Документация (RU)” существуют в репозитории и проходят CI gate шага 22.
- В MASTER (CHECKLIST_00_MASTER_ART_REGART.md) строка этапа 01 заполнена: дата, подпись/ник, commit/PR.

## Метаданные
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение SLO/SLI; появление новых `observability_gap.*`; изменение политики MCP; изменение требований аудита actions


## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
