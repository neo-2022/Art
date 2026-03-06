A) Полный запрет опциональности:
# CHECKLIST 23 — Ops/Deploy/Runbooks/DR
Файл: CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение TLS; изменение миграций БД; изменение deploy моделей; изменение формата backup; изменение runbook registry
Master checklist: docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md

## Цель
Ops/DR без двусмысленности: k8s TLS через cert-manager обязателен; systemd TLS rotation выполняется через SIGHUP без простоя; DB migration runbook с integrity check; WAL-aware backups фиксированным способом; DR drill воспроизводим; `observability_gap.tls_config_invalid` обязателен.

## Границы
Ops/Deploy/Runbooks/DR (systemd + k8s). Не включает разработку Core/Agent логики, только процедуры и проверяемые артефакты/тесты.

## Зависимости
- CHECKLIST 22 — E2E/Stress/Chaos/Soak/Perf
- CHECKLIST 14 — Stream/Snapshot v1 (TLS для API)
- CHECKLIST 15 — Actions/Audit/RBAC/PII (TLS для Actions/Audit)
- CHECKLIST 18 — Art Agent Receivers v1

## Шаги (строго линейно)

- [ ] **1. Сделать:** k8s TLS: cert-manager обязателен и описан как единственный способ выдачи/ротации сертификатов в k8s.
  - [ ] Используется cert-manager (ровно этот компонент)
  - [ ] Issuer фиксирован: `ClusterIssuer`
  - [ ] Secret с TLS ключом/сертом называется `art-tls`
  - [ ] Ingress (или Gateway) использует secret `art-tls`
  - [ ] Описана ротация cert-manager без простоя (сертификат обновляется автоматически)
  - [ ] **Проверка (pass/fail):** `docs/ops/deploy_k8s.md` содержит раздел `cert-manager` и включает:
    - [ ] манифесты/фрагменты для ClusterIssuer и Certificate с именем secret `art-tls`
    - [ ] описание ротации.

- [ ] **2. Сделать:** systemd TLS rotation: reload через SIGHUP без простоя (фиксированная процедура).
  - [ ] Core запущен как systemd service `art-core.service`
  - [ ] Reload выполняется сигналом `SIGHUP`
  - [ ] Reload не прерывает активные SSE соединения (stream продолжает работать)
  - [ ] Smoke проверка фиксирована:
    - [ ] держим SSE `/api/v1/stream` подключённым
    - [ ] выполняем TLS rotation (замена файлов cert/key)
    - [ ] отправляем SIGHUP
    - [ ] SSE соединение остаётся активным
  - [ ] **Проверка (pass/fail):** `docs/ops/tls_rotation.md` описывает процедуру + smoke сценарий и критерии pass/fail.

- [ ] **3. Сделать:** DB migration runbook: обновление Core с миграцией SQLite + integrity check (фиксированная процедура).
  - [ ] Процедура обновления фиксирована:
    - [ ] stop Core
    - [ ] backup перед миграцией (ссылка на шаг 4)
    - [ ] применить миграции (фиксированная команда/скрипт)
    - [ ] выполнить integrity check (фиксированная команда/скрипт)
    - [ ] start Core
  - [ ] При провале integrity check выполняется rollback на backup (фиксированный порядок)
  - [ ] **Проверка (pass/fail):** существует `docs/ops/db_migration_runbook.md`, содержит все шаги выше в указанном порядке и содержит точные команды.

- [ ] **4. Сделать:** WAL-aware backup: фиксированный способ бэкапа SQLite.
  - [ ] Единственный разрешённый способ backup: `sqlite3 .backup`
  - [ ] Backup выполняется при остановленном Core
  - [ ] После backup выполняется integrity check на backup-файле (фиксированная команда)
  - [ ] Формат хранения backup:
    - [ ] каталог `backups/`
    - [ ] имя `core-YYYYMMDD-HHMM.sqlite3`
  - [ ] **Проверка (pass/fail):** `docs/ops/backup_restore.md` содержит:
    - [ ] команду `sqlite3 <db> ".backup '<file>'"`
    - [ ] условие “Core остановлен”
    - [ ] integrity check после backup
    - [ ] формат путей/имен backup.

- [ ] **5. Сделать:** DR drill: восстановление из backup выполняется и фиксируется отчётом (воспроизводимо).
  - [ ] DR drill проводится фиксированным сценарием:
    - [ ] stop Core
    - [ ] восстановление из backup (фиксированная команда/процедура)
    - [ ] start Core
    - [ ] integrity check pass
    - [ ] smoke ingest→snapshot pass (фиксированные команды)
  - [ ] **Проверка (pass/fail):** существует `docs/ops/dr_drill.md`, содержит:
    - [ ] дату проведения
    - [ ] использованный backup файл
    - [ ] команды восстановления
    - [ ] результаты integrity check
    - [ ] результаты smoke ingest→snapshot
    - [ ] явный вывод pass/fail.

- [ ] **6. Сделать:** `observability_gap.tls_config_invalid` при невозможности загрузить TLS ключи/сертификаты.
  - [ ] Критерий ошибки фиксирован:
    - [ ] отсутствует cert файл или key файл
    - [ ] cert/key не парсятся
    - [ ] cert и key не соответствуют друг другу
  - [ ] Поведение фиксировано: Core не стартует (fail closed)
  - [ ] Процедура доставки события фиксирована:
    - [ ] при ошибке TLS событие фиксируется в локальном bootstrap-логе/буфере (persisted startup backlog)
    - [ ] при следующем успешном старте Core публикует сохранённое событие `observability_gap.tls_config_invalid` в snapshot/stream как “startup backlog”
  - [ ] Событие содержит evidence_min:
    - [ ] cert_path
    - [ ] key_path
    - [ ] error (строка)
    - [ ] trace_id
  - [ ] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [ ] `incident_rule=create_incident_min_sev1`
    - [ ] `action_ref=docs/runbooks/tls_config_invalid.md`
  - [ ] **Проверка (pass/fail):** induced test:
    - [ ] ломает cert/key (например, пустой key файл)
    - [ ] подтверждает отказ старта Core
    - [ ] после исправления TLS и перезапуска Core ожидает и подтверждает появление `observability_gap.tls_config_invalid` в `/api/v1/snapshot` (startup backlog опубликован)

- [ ] **7. Сделать:** Зафиксировать multi-site deployment и transport runbook для Art Agent.
  - [ ] существует `docs/ops/agent_multisite_deploy.md`
  - [ ] документ содержит сценарии:
    - [ ] `single-site`
    - [ ] `multi-site / WAN`
    - [ ] `segmented network`
    - [ ] `air-gapped relay/export`
  - [ ] для каждого сценария описаны:
    - [ ] способ установки агента
    - [ ] путь доставки в Core/relay
    - [ ] локальный spool/outbox boundary
    - [ ] retry/replay поведение
    - [ ] команды проверки health и backlog
    - [ ] rollback / isolate процедура
  - [ ] **Проверка (pass/fail):** документ существует и содержит все сценарии и обязательные подпункты.

## Документация (RU)
- [ ] docs/ops/deploy_systemd.md
- [ ] docs/ops/deploy_k8s.md
- [ ] docs/ops/tls_rotation.md
- [ ] docs/ops/db_migration_runbook.md
- [ ] docs/ops/backup_restore.md
- [ ] docs/ops/dr_drill.md
- [ ] docs/ops/agent_multisite_deploy.md
- [ ] docs/runbooks/tls_config_invalid.md

## Тестирование
- [ ] integration: TLS reload smoke (SSE держится, шаг 2)
- [ ] integration: DR drill smoke (restore + integrity + ingest→snapshot, шаг 5)
- [ ] induced: tls_config_invalid (fail closed + startup backlog публикация, шаг 6)
- [ ] runtime smoke: `scripts/tests/ops_stage23_smoke.sh` (backup/restore + ingest→snapshot + SIGHUP stream survival)

## CI gate
- [ ] CI job `ops-smoke` существует и запускается на PR в main
- [ ] CI job `ops-docs-gate` существует и запускается на PR в main
- [ ] `ops-docs-gate` запускает `scripts/ci/check_ops_stage23_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/ops/deploy_k8s.md` содержит `cert-manager` и `ClusterIssuer` и `art-tls`
    - [ ] `docs/ops/tls_rotation.md` содержит `SIGHUP` и `stream` и `ops_stage23_smoke.sh`
    - [ ] `docs/ops/db_migration_runbook.md` содержит `integrity` и `rollback`
    - [ ] `docs/ops/backup_restore.md` содержит `sqlite3` и `.backup` и `integrity`
    - [ ] `docs/ops/dr_drill.md` содержит `ingest` и `snapshot` и `pass/fail` и `ops_stage23_smoke.sh`
    - [ ] `docs/runbooks/tls_config_invalid.md` содержит `mitigations` и `verification`
    - [ ] `docs/governance/observability_gap_registry.md` содержит `tls_config_invalid`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] k8s deploy описан и использует cert-manager как единственный TLS механизм.
- [ ] systemd TLS rotation через SIGHUP без простоя описан и проверен smoke тестом.
- [ ] DB migration runbook описан и содержит integrity check + rollback.
- [ ] WAL-aware backup зафиксирован как `sqlite3 .backup` при остановленном Core.
- [ ] DR drill выполнен и зафиксирован отчётом с pass/fail.
- [ ] `observability_gap.tls_config_invalid` реализован, зарегистрирован и покрыт induced test (включая публикацию startup backlog в snapshot/stream).
- [ ] Multi-site deployment/transport runbook Art Agent зафиксирован для single-site, WAN, segmented и air-gapped контуров.
- [ ] CI gate Stage 23 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
