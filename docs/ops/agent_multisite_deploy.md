# Multi-Site Deployment Art Agent

## Source of truth
- `docs/source/agent_deployment_transport_v0_2.md`
- `docs/source/checklists/CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `formats/platform_support.yaml`

## Цель
Дать операционный runbook, как ставить и проверять `Art Agent` в четырёх обязательных сценариях:
- `single-site`
- `multi-site / WAN`
- `segmented network`
- `air-gapped relay/export`

## Общее правило
Агент ставится рядом с источником данных. При потере связи с `Art Core` или relay данные сохраняются в локальном `spool/outbox` и повторно доставляются после восстановления связи.

## 1. Single-site

### Установка
- установить `art-agent` как `systemd service` или container рядом с приложением;
- задать receiver config;
- задать direct endpoint `Art Core`.

### Проверка
- проверить `/health`;
- проверить `/api/v1/agent/receivers`;
- выполнить enqueue в spool и убедиться в доставке.

### Rollback / isolate
- остановить `art-agent`;
- сохранить spool path и config;
- отключить transport endpoint до выяснения причины.

## 2. Multi-site / WAN

### Установка
- агент ставится на каждой площадке локально;
- для каждой площадки задаётся собственный `source_id` scope и transport endpoint;
- local spool обязателен.

### Проверка
- подтвердить delivery в Core при нормальной связи;
- искусственно разорвать связь;
- убедиться, что backlog растёт локально;
- восстановить связь и подтвердить replay.

### Rollback / isolate
- отключить transport endpoint;
- оставить локальный spool в режиме сохранения backlog;
- зафиксировать `observability_gap.*` и открыть инцидент по runbook.

## 3. Segmented network

### Установка
- агент ставится в каждом сегменте;
- delivery идёт только через approved relay/bridge;
- прямой выход наружу запрещён.

### Проверка
- подтвердить доступность relay;
- подтвердить replay backlog через relay;
- подтвердить отсутствие прямого обходного канала.

### Rollback / isolate
- отключить relay path;
- оставить backlog локально;
- документировать сегмент как degraded contour.

## 4. Air-gapped relay / export

### Установка
- агент ставится из offline package;
- bootstrap приходит из локального approved source;
- transport в центральный контур выполняется только через approved export или scheduled relay.

### Проверка
- подтвердить локальную работу receivers;
- подтвердить запись в spool/outbox;
- подтвердить approved export/relay path;
- подтвердить отсутствие несанкционированного outbound path.

### Rollback / isolate
- остановить export/relay path;
- сохранить локальные spool/evidence;
- зафиксировать статус сегмента как isolated.

## Health / Backlog команды

```bash
curl -fsS http://127.0.0.1:9001/health
curl -fsS http://127.0.0.1:9001/api/v1/agent/receivers
curl -fsS http://127.0.0.1:9001/api/v1/agent/spool/status
curl -fsS http://127.0.0.1:9001/api/v1/agent/spool/events
```

## Что считать PASS
- агент стартует и отдаёт `health`;
- backlog не теряется при разрыве связи;
- replay после восстановления связи работает;
- transport path соответствует утверждённой topology;
- нет silent loss.

## Что считать FAIL
- данные пропадают без `observability_gap.*`;
- transport идёт в обход approved relay/path;
- backlog не догоняется после восстановления;
- agent install требует изменения бизнес-логики `core/agent/browser`.
