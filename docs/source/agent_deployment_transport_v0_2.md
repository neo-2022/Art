# Art Agent Deployment And Transport v0.2

## Source of truth
- `docs/source/Art_v1_spec_final.md`
- `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md`
- `docs/source/checklists/CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md`
- `docs/source/checklists/CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `formats/platform_support.yaml`

## Цель
Зафиксировать без двусмысленности, как `Art Agent` ставится на узлы и как передаёт данные в `Art Core`, если узлы находятся в разных сетях, зданиях, городах, Kubernetes-кластерах или изолированных сегментах.

## Базовый закон
`Art Agent` ставится рядом с источником данных. Источник не должен передавать сигнал напрямую в UI или в произвольный внешний сервис. Единственный допустимый путь:

`receiver -> normalizer -> pre-write redaction -> spool/outbox -> transport -> Core ingest -> ack`

Если transport-path недоступен, данные не теряются молча:
- сохраняются в локальном `spool/outbox`;
- повторно доставляются после восстановления связи;
- при ошибке/переполнении/разрыве связи порождаются `observability_gap.*`.

## Модели установки

### 1. Systemd service
Используется для Linux host, VM, bare metal и удалённых площадок.

Обязательные свойства:
- агент ставится как отдельный сервис;
- локально читает `journald`, `systemd_unit`, `file_tail`, `proc_probe`, `net_probe`;
- локальный `spool/outbox` находится на том же узле;
- перезапуск сервиса не должен нарушать сохранённый `offset/cursor/spool`.

### 2. Container sidecar
Используется рядом с отдельным приложением, если нужен локальный `stdout/stderr`, sidecar `otlp_logs` или близкий сетевой probe-контур.

Обязательные свойства:
- sidecar не заменяет host-level агент для systemd/journald;
- sidecar отвечает только за локальный app-scope signal path;
- backlog и replay остаются локальными для контейнера/volume.

### 3. Kubernetes DaemonSet
Используется для host-level покрытия узлов кластера.

Обязательные свойства:
- DaemonSet обязателен для node-level signals;
- sidecar допускается только как дополнение для app-local signal path;
- `spool/outbox` не должен зависеть от памяти Pod без persistence policy;
- потери node connectivity обязаны приводить к backlog/replay или `observability_gap.*`.

### 4. Air-gapped package
Используется в изолированных сегментах и регулируемых контурах.

Обязательные свойства:
- установка идёт из локально доставленного пакета;
- bootstrap-конфиг и policy-файлы приходят офлайн;
- передача в центральный контур разрешена только через утверждённый relay/export path;
- при отсутствии такого пути агент работает локально и сохраняет evidence о недоставке.

## Топологии доставки

### 1. Single-site
Один ЦОД или одна площадка, прямая связь с `Art Core`.

Путь:
`agent -> direct transport -> Core ingest`

### 2. Multi-site / WAN
Несколько площадок, зданий или городов, связь через WAN.

Путь:
`agent -> local spool/outbox -> WAN transport -> Core ingest`

Обязательные свойства:
- WAN-разрывы не должны приводить к silent loss;
- обязательны `retry`, `backoff`, `replay backlog`;
- при длительной недоступности канала должны появляться `observability_gap.*` по delivery path.

### 3. Segmented network
Сегментированные сети с ограниченными маршрутами.

Путь:
`agent -> local spool/outbox -> approved relay/bridge -> Core ingest`

Обязательные свойства:
- relay/bridge фиксируется как часть approved transport path;
- агент не открывает произвольные внешние соединения;
- policy доступа и transport endpoints фиксируются заранее;
- если relay недоступен, backlog сохраняется локально.

### 4. Air-gapped relay / export
Изолированный сегмент без постоянной связи с центральным Core.

Путь:
`agent -> local spool/outbox -> approved export artifact or scheduled relay -> receiving Core`

Обязательные свойства:
- используется только утверждённый export/relay path;
- transfer policy определяется профилем окружения;
- экспорт без policy считается нарушением и должен фиксироваться audit/gap-событиями.

## Bootstrap / Enrollment

### Общий принцип
Агент получает только минимально необходимый bootstrap:
- identity/instance id;
- transport endpoint или relay endpoint;
- receiver config;
- privacy/redaction policy reference;
- spool policy;
- profile id.

Bootstrap не должен требовать ручного вмешательства в код продукта.

### Enrollment boundary
Независимо от среды должны быть определены:
- откуда агент получает конфиг;
- чем подтверждает свою identity;
- как ротируется transport identity;
- как выполняется revoke/disable.

Для Linux production-ready baseline допускаются:
- локальный bootstrap-file;
- environment-based bootstrap;
- approved secret/config object для k8s.

## Security boundary
Для каждой топологии должны быть определены:
- разрешённые transport endpoints;
- кто может менять receiver config;
- где проходит privacy boundary;
- где хранятся `spool/outbox` данные;
- что считается нарушением policy.

## Delivery / Replay Law
Обязательное поведение:
- событие сначала попадает в локальный `spool/outbox`;
- удаляется только после `ack` от Core;
- при network partition включаются retry/backoff;
- после восстановления связи backlog догоняется в том же transport path;
- при переполнении или невозможности продолжать доставку генерируются `observability_gap.*`.

## Gap events
Минимум для deployment/transport контура должны существовать и быть зарегистрированы:
- `observability_gap.spool_full`
- `observability_gap.spool_corrupted`
- `observability_gap.spool_disk_full`
- `observability_gap.receiver_paused_spool_full`
- `observability_gap.receiver_target_unreachable`
- `observability_gap.receiver_probe_failed`
- `observability_gap.receiver_config_invalid`

Если для конкретной топологии вводятся relay/export ошибки, они обязаны быть добавлены в реестр `observability_gap.*`.

## Что запрещено
- прямой сбор в UI в обход `Core`;
- silent loss при разрыве связи;
- хранение необработанных секретов до `pre-write redaction`;
- ветвление логики `core/agent/browser` по дистрибутивам Linux;
- временный transport path без checklist/gate.

## Что должно быть проверено дальше по программе
- Stage 18: topology doc, receiver coverage, transport law.
- Stage 23: ops runbook для single-site/WAN/segmented/air-gapped deployment.
- Stage 26: ограничения RU/air-gapped профиля.
- Stage 37: Linux production boundary и runtime compatibility для multi-site delivery.
