# Процесс Управления Инцидентами

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/severity.md`
- `docs/governance/oncall.md`
- `docs/governance/observability_gap_registry.md`
- `docs/governance/slo_sli.md`

## Назначение

Этот документ задаёт обязательный incident lifecycle для Art.  
Он определяет:

- как открывается инцидент;
- кто участвует в управлении инцидентом;
- как инцидент ведётся до mitigation и resolution;
- когда инцидент считается закрытым;
- как обрабатываются `observability_gap.*`;
- как инциденты связываются с severity, evidence и runbooks.

## Incident lifecycle

Обязательная последовательность:

1. `detect`
2. `triage`
3. `mitigate`
4. `resolve`
5. `postmortem`
6. `follow-ups`

Переходы между стадиями должны быть отражены в timeline инцидента.

## Роли в инциденте

- `Incident Commander`  
  управляет инцидентом, принимает operational decisions, определяет следующий шаг и момент escalation.

- `Communications`  
  отвечает за статусные сообщения, канал коммуникации, фиксацию внешнего и внутреннего статуса.

- `Scribe`  
  ведёт timeline, фиксирует evidence, решения, severity changes, runbook/action_ref и follow-ups.

Дополнительно при необходимости:

- `Owner component`  
  инженер или группа, владеющая затронутым компонентом;
- `Security`  
  подключается при privacy/security/audit issues;
- `Release`  
  подключается, если инцидент влияет на release path или rollback decision.

## Правила открытия инцидента

Инцидент обязан быть открыт, если выполняется хотя бы одно условие:

- severity определена как `SEV0`, `SEV1`, `SEV2` или `SEV3` для operational event;
- registry для `observability_gap.*` требует `incident_rule != no_incident`;
- зафиксирован `SLO breach mapping` с incident creation;
- зафиксирован release blocker;
- зафиксирован security/privacy/audit failure;
- требуется координация более чем одного человека или одной роли.

### Минимальные обязательные поля при открытии

- `incident_id`
- `opened_at`
- `opened_by`
- `severity`
- `component`
- `summary`
- `evidence`
- `action_ref`, если применимо
- `next_review_at`

### Запрещено

- устранять SEV-инцидент без открытия incident record;
- держать инцидент только в чате без timeline/evidence;
- откладывать открытие инцидента из-за спора о точной severity.

## Этапы жизненного цикла

### 1. Detect

Источник обнаружения может быть:

- `observability_gap.*`
- `SLO breach`
- alert/monitoring
- оператор/пользователь
- CI/release gate
- security/compliance signal

На этапе detect фиксируются:

- время обнаружения;
- первичный сигнал;
- первичное evidence;
- provisional severity.

### 2. Triage

На этапе triage обязательны:

- подтверждение или коррекция severity;
- определение affected scope;
- назначение `Incident Commander`;
- назначение `Communications` и `Scribe` для `SEV0/SEV1`, а также для более лёгких случаев, если инцидент длинный или сложный;
- выбор runbook или action_ref.

### 3. Mitigate

На этапе mitigate:

- выполняется runbook или безопасное действие;
- каждая команда, workaround или action фиксируется;
- каждое изменение severity фиксируется с причиной;
- при agent/Core/bridge failure фиксируется состояние доставки, backlog и observability coverage.

### 4. Resolve

Инцидент может перейти в `resolve`, только если:

- причина деградации устранена или локализована;
- ключевой affected path восстановлен;
- evidence подтверждает стабилизацию;
- назначены postmortem и follow-ups.

### 5. Postmortem

Postmortem обязателен по правилам `postmortem_policy.md`.

### 6. Follow-ups

Follow-up считается обязательной частью инцидента, а не отдельной необязательной задачей.  
У каждого follow-up должен быть:

- owner
- due date
- ссылка на incident
- expected verification artifact

## Правила закрытия инцидента

Инцидент может быть закрыт только если одновременно выполнены все условия:

- severity снижена до состояния, не требующего активного incident handling;
- mitigation подтверждён evidence;
- affected path восстановлен;
- нет незакрытого blocker для release/ops/security, связанного с этим incident;
- runbook/action_ref выполнен или зафиксирована причина отклонения;
- follow-ups заведены и назначены;
- для `SEV0/SEV1` создан postmortem obligation.

### Закрытие запрещено, если

- проблема только "перестала воспроизводиться", но не подтверждена evidence;
- backlog/outbox/spool остаётся в ненормальном состоянии;
- `observability_gap.*` исчез из UI, но причина не устранена;
- нет owner у follow-up действий;
- не зафиксировано, почему incident переведён в resolved/closed.

## observability_gap escalation

`observability_gap escalation` является обязательным operational контуром Art.

### Обязательная регистрация

- все `observability_gap.*` обязаны регистрироваться;
- все `observability_gap.*` должны быть видимы в `snapshot/stream`;
- запрещено тихо пропускать такие события.

### Auto-incident правило для критичных контуров

Любые события, относящиеся к:

- `ingest/*`
- `spool/*`
- `storage/*`

автоматически порождают incident с severity не ниже `SEV1`.

### Registry-driven правило для остальных событий

Все остальные `observability_gap.*` обрабатываются по полю `incident_rule` из:

- `docs/governance/observability_gap_registry.md`

Реестр является единственным источником решения:

- создавать incident или нет;
- какой minimum severity обязателен;
- какой `action_ref` должен быть приложен.

### Обязательный action_ref

Для каждого случая, где создаётся incident:

- обязателен `action_ref`;
- `action_ref` должен ссылаться на runbook из `docs/runbooks/` или `docs/ops/`, если это ops-runbook;
- если runbook отсутствует, incident не может считаться полностью обработанным.

## Связь с severity

Severity назначается по:

- `docs/governance/severity.md`
- `docs/governance/slo_sli.md`
- `docs/governance/observability_gap_registry.md`

Если критерии расходятся, берётся более тяжёлый уровень.

## Что обязательно фиксируется в incident record

- `incident_id`
- `severity`
- `opened_at`
- `closed_at`
- `Incident Commander`
- `Communications`
- `Scribe`
- affected component / affected scope
- timeline
- evidence
- action_ref
- follow-up actions

## Критерий актуальности

Документ считается актуальным только если:

- lifecycle описан как `detect -> triage -> mitigate -> resolve -> postmortem -> follow-ups`;
- перечислены роли `Incident Commander`, `Communications`, `Scribe`;
- зафиксированы правила открытия и закрытия инцидента;
- присутствует раздел `observability_gap escalation`;
- присутствует ссылка на `docs/governance/observability_gap_registry.md` как на источник `incident_rule`;
- зафиксировано требование `action_ref` для incident-creating случаев.
