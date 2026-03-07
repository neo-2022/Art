# Политика Severity `SEV0`–`SEV3`

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/oncall.md`
- `docs/governance/incident_process.md`
- `docs/governance/observability_gap_registry.md`
- `docs/governance/slo_sli.md`

## Назначение

Этот документ фиксирует единую шкалу тяжести инцидентов Art.  
Severity определяет:

- максимальное допустимое время первой реакции;
- обязательные каналы коммуникации;
- уровень эскалации;
- требования к фиксации evidence и follow-up;
- нижнюю границу реакции для `observability_gap.*`, SLO breach, security и release-blocker событий.

Severity не может назначаться "на глаз" без привязки к критериям ниже.

## Базовые правила

- `SEV0`–`SEV3` назначаются по фактическому impact, а не по внутренней тревожности команды.
- Если событие подпадает под несколько критериев, берётся более тяжёлый уровень.
- Если impact пока неясен, на время triage используется более тяжёлый provisional severity.
- Любой `observability_gap.*`, для которого в registry задан `create_incident_*`, обязан получить severity не ниже значения, заданного registry или таблицей ниже.
- Любой `SLO breach` из `docs/governance/slo_sli.md` обязан получать severity не ниже указанной в `SLO breach mapping`.
- Любое security-событие с риском компрометации данных, обхода policy, неподтверждённого действия или потери целостности аудита не может быть ниже `SEV1`.

## Формальная шкала

| Severity | Формальный критерий impact | Время первой реакции | Время назначения Incident Commander | Коммуникация | Эскалация |
|---|---|---:|---:|---|---|
| `SEV0` | Полная недоступность критического контура, риск потери/искажения данных, потеря управляемости расследования, массовый отказ ключевого продукта, нарушение целостности аудита/доказательств | `5 минут` | `5 минут` | Incident bridge, звонок/pager, статусное сообщение, явный owner | Owner + On-call + Security + Release |
| `SEV1` | Критичная деградация ключевого потока, auto-incident для `ingest/spool/storage`, подтверждённый security/privacy сбой, блокировка релиза, деградация с реальным риском перерастания в SEV0 | `15 минут` | `15 минут` | Incident bridge, mention primary/secondary, обязательный timeline | On-call + владелец компонента, при необходимости Security/Release |
| `SEV2` | Частичная деградация, затронута существенная функциональность, SLO breach без полной остановки, повторяющиеся `observability_gap.*`, локальная деградация tenant/site/segment | `60 минут` | `60 минут` | Incident chat или task thread, обновление статуса, owner assigned | On-call + владелец компонента |
| `SEV3` | Некритичный дефект, ограниченный impact, разовая деградация без нарушения ключевого потока, документационный/operational gap без немедленного пользовательского ущерба | `1 рабочий день` | не требуется | backlog / issue / review trail | владелец компонента |

## Детализация критериев по уровням

### `SEV0`

`SEV0` назначается, если выполняется хотя бы одно условие:

- недоступен центральный path расследования и нет подтверждённого безопасного fallback;
- существует риск потери production-данных, audit-цепочки или evidence trail;
- потерян контроль над действиями в production;
- ключевой customer-facing сервис полностью недоступен;
- нарушена целостность crypto/audit verify path;
- проблема одновременно массовая и немедленная.

Типовые примеры:

- `Core` не принимает ingest, snapshot и stream одновременно;
- corruption хранилища без подтверждённого recovery path;
- silent execution actions без audit trail;
- массовая недоступность прод-сервиса у банка или гос-системы;
- невозможность восстановить факт, кто и что сделал в production.

### `SEV1`

`SEV1` назначается, если выполняется хотя бы одно условие:

- registry требует `create_incident_min_sev1` или выше;
- критичный контур работает с серьёзной деградацией, но без полной остановки;
- существует риск эскалации в `SEV0` в ближайшем операционном окне;
- нарушен security/privacy policy с подтверждённым impact;
- release blocker подтверждён для основного продукта;
- backlog/outbox/spool растёт и угрожает доставке или потере наблюдаемости.

Типовые примеры:

- `observability_gap.spool_full`
- `observability_gap.storage_corrupted`
- `observability_gap.ingest_unavailable`
- `observability_gap.audit_merkle_verify_failed`
- подтверждённая утечка evidence вне `access_scope`

### `SEV2`

`SEV2` назначается, если:

- impact ограничен одной подсистемой, tenant, сайтом или частью функциональности;
- есть нарушение SLO, но без массовой остановки;
- есть повторяющийся `observability_gap.*`, который ухудшает качество расследований;
- есть деградация UI/Console/Flow/Local Stores, влияющая на операторов, но не убивающая расследование полностью.

Типовые примеры:

- `stream_lag_ms` выше бюджета;
- `observability_gap.local_store_latency_exceeded`;
- `observability_gap.ui_law_violation`;
- `observability_gap.pack_install_failed`;
- частичная недоступность REGART bridge без потери Core truth.

### `SEV3`

`SEV3` назначается, если:

- impact ограничен, обратим и не мешает ключевому operational path;
- проблема не нарушает SLO/SLA немедленно;
- есть дефект, который нужно исправить, но он не требует incident bridge.

Типовые примеры:

- единичный неопасный дефект документации или policy;
- разовая локальная ошибка без повторяемости и без customer impact;
- необходимость уточнить runbook или evidence format.

## Требования по коммуникации

| Severity | Обязательные коммуникации | Что должно быть зафиксировано |
|---|---|---|
| `SEV0` | Incident bridge, звонок/pager, запись в incident issue, первичное обновление статуса | impact, предположительный scope, owner, next update time, mitigation hypothesis |
| `SEV1` | Incident bridge или эквивалентный оперативный канал, mention primary/secondary, incident issue | severity, affected component, evidence, runbook/action_ref, next review time |
| `SEV2` | incident thread / issue / task с owner | impact, owner, deadline triage, runbook/action_ref если применимо |
| `SEV3` | backlog / issue / PR discussion | проблема, owner, planned fix |

### Правила обновления статуса

- `SEV0`: обновление статуса не реже одного раза в `15 минут`
- `SEV1`: обновление статуса не реже одного раза в `30 минут`
- `SEV2`: обновление статуса по завершении triage и при смене решения
- `SEV3`: обновление по мере планирования и закрытия

## Обязательные связи с `observability_gap.*`

Если registry задаёт:

- `create_incident_min_sev0` -> severity не ниже `SEV0`
- `create_incident_min_sev1` -> severity не ниже `SEV1`
- `create_incident_min_sev2` -> severity не ниже `SEV2`
- `create_incident_min_sev3` -> severity не ниже `SEV3`
- `create_incident` -> severity определяется impact, но не может быть ниже operational смысла события

Жёсткое правило:

- любые `ingest/*`, `spool/*`, `storage/*` incidents не могут быть ниже `SEV1`;
- `audit`, `security`, `privacy`, `cross-tenant`, `cross-border export`, `proof-chain` нарушения не могут быть ниже `SEV1`;
- `console-only` деградация может быть `SEV2` или `SEV3`, только если `Panel0` и Core truth path остаются рабочими.

## Обязательные связи с SLO breach

Severity для SLO breach назначается по `docs/governance/slo_sli.md`, но не может быть понижена ниже реального impact.

Примеры:

- `ingest_success_rate < target` -> минимум `SEV1`
- `spool_backlog_age_sec > target` -> минимум `SEV1`
- `dlq_size > 0` длительное время -> минимум `SEV2`
- `stream_lag_ms > target` длительное время -> минимум `SEV2`

## Правило provisional severity

Если в момент открытия инцидента нет полной картины:

1. назначить provisional severity;
2. в течение окна первой реакции подтвердить или понизить/повысить уровень;
3. зафиксировать причину изменения severity в timeline.

Запрещено:

- задерживать открытие инцидента из-за спора о severity;
- занижать severity, чтобы не запускать escalation path;
- менять severity без фиксации причины.

## Примеры для типовых заказчиков

### Банк

- отказ карточного процессинга или риск потери аудита операций -> `SEV0`
- деградация критичного API платежей с подтверждённым backlog -> `SEV1`
- деградация части операторского интерфейса без остановки транзакций -> `SEV2`

### Гос-система

- недоступность контура оказания услуги или потеря доказуемости действий -> `SEV0`
- блокировка безопасного экспорта / privacy breach / policy mismatch -> `SEV1`
- локальная деградация одного сегмента без общей остановки -> `SEV2`

### Оператор связи

- массовый outage ключевого customer-facing path -> `SEV0`
- деградация биллингового/маршрутизирующего контура с риском масштабирования -> `SEV1`
- локальная деградация одного региона или support UI -> `SEV2`

### Промышленный контур

- потеря управляемости критического operational data flow -> `SEV0`
- подтверждённая деградация сбора сигналов/relay/segment path -> `SEV1`
- повторяющийся локальный сигнал без полной остановки -> `SEV2`

## Критерий актуальности

Документ считается актуальным только если:

- присутствуют определения `SEV0`–`SEV3`;
- для каждого уровня указано время реакции в минутах;
- для каждого уровня указаны требования по коммуникации;
- severity согласована с `oncall.md`, `incident_process.md`, `observability_gap_registry.md`, `slo_sli.md`.
