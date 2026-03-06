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

## Шаги (строго линейно)

- [x] **1. Сделать:** k8s TLS: cert-manager обязателен и описан как единственный способ выдачи/ротации сертификатов в k8s.
  - [x] Используется cert-manager (ровно этот компонент)
  - [x] Issuer фиксирован: `ClusterIssuer`
  - [x] Secret с TLS ключом/сертом называется `art-tls`
  - [x] Ingress (или Gateway) использует secret `art-tls`
  - [x] Описана ротация cert-manager без простоя (сертификат обновляется автоматически)
  - [x] **Проверка (pass/fail):** `docs/ops/deploy_k8s.md` содержит раздел `cert-manager` и включает:
    - [x] манифесты/фрагменты для ClusterIssuer и Certificate с именем secret `art-tls`
    - [x] описание ротации.

- [x] **2. Сделать:** systemd TLS rotation: reload через SIGHUP без простоя (фиксированная процедура).
  - [x] Core запущен как systemd service `art-core.service`
  - [x] Reload выполняется сигналом `SIGHUP`
  - [x] Reload не прерывает активные SSE соединения (stream продолжает работать)
  - [x] Smoke проверка фиксирована:
    - [x] держим SSE `/api/v1/stream` подключённым
    - [x] выполняем TLS rotation (замена файлов cert/key)
    - [x] отправляем SIGHUP
    - [x] SSE соединение остаётся активным
  - [x] **Проверка (pass/fail):** `docs/ops/tls_rotation.md` описывает процедуру + smoke сценарий и критерии pass/fail.

- [x] **3. Сделать:** DB migration runbook: обновление Core с миграцией SQLite + integrity check (фиксированная процедура).
  - [x] Процедура обновления фиксирована:
    - [x] stop Core
    - [x] backup перед миграцией (ссылка на шаг 4)
    - [x] применить миграции (фиксированная команда/скрипт)
    - [x] выполнить integrity check (фиксированная команда/скрипт)
    - [x] start Core
  - [x] При провале integrity check выполняется rollback на backup (фиксированный порядок)
  - [x] **Проверка (pass/fail):** существует `docs/ops/db_migration_runbook.md`, содержит все шаги выше в указанном порядке и содержит точные команды.

- [x] **4. Сделать:** WAL-aware backup: фиксированный способ бэкапа SQLite.
  - [x] Единственный разрешённый способ backup: `sqlite3 .backup`
  - [x] Backup выполняется при остановленном Core
  - [x] После backup выполняется integrity check на backup-файле (фиксированная команда)
  - [x] Формат хранения backup:
    - [x] каталог `backups/`
    - [x] имя `core-YYYYMMDD-HHMM.sqlite3`
  - [x] **Проверка (pass/fail):** `docs/ops/backup_restore.md` содержит:
    - [x] команду `sqlite3 <db> ".backup '<file>'"`
    - [x] условие “Core остановлен”
    - [x] integrity check после backup
    - [x] формат путей/имен backup.

- [x] **5. Сделать:** DR drill: восстановление из backup выполняется и фиксируется отчётом (воспроизводимо).
  - [x] DR drill проводится фиксированным сценарием:
    - [x] stop Core
    - [x] восстановление из backup (фиксированная команда/процедура)
    - [x] start Core
    - [x] integrity check pass
    - [x] smoke ingest→snapshot pass (фиксированные команды)
  - [x] **Проверка (pass/fail):** существует `docs/ops/dr_drill.md`, содержит:
    - [x] дату проведения
    - [x] использованный backup файл
    - [x] команды восстановления
    - [x] результаты integrity check
    - [x] результаты smoke ingest→snapshot
    - [x] явный вывод pass/fail.

- [x] **6. Сделать:** `observability_gap.tls_config_invalid` при невозможности загрузить TLS ключи/сертификаты.
  - [x] Критерий ошибки фиксирован:
    - [x] отсутствует cert файл или key файл
    - [x] cert/key не парсятся
    - [x] cert и key не соответствуют друг другу
  - [x] Поведение фиксировано: Core не стартует (fail closed)
  - [x] Процедура доставки события фиксирована:
    - [x] при ошибке TLS событие фиксируется в локальном bootstrap-логе/буфере (persisted startup backlog)
    - [x] при следующем успешном старте Core публикует сохранённое событие `observability_gap.tls_config_invalid` в snapshot/stream как “startup backlog”
  - [x] Событие содержит evidence_min:
    - [x] cert_path
    - [x] key_path
    - [x] error (строка)
    - [x] trace_id
  - [x] Событие зарегистрировано в `docs/governance/observability_gap_registry.md` с:
    - [x] `incident_rule=create_incident_min_sev1`
    - [x] `action_ref=docs/runbooks/tls_config_invalid.md`
  - [x] **Проверка (pass/fail):** induced test:
    - [x] ломает cert/key (например, пустой key файл)
    - [x] подтверждает отказ старта Core
    - [x] после исправления TLS и перезапуска Core ожидает и подтверждает появление `observability_gap.tls_config_invalid` в `/api/v1/snapshot` (startup backlog опубликован)

## Документация (RU)
- [x] docs/ops/deploy_systemd.md
- [x] docs/ops/deploy_k8s.md
- [x] docs/ops/tls_rotation.md
- [x] docs/ops/db_migration_runbook.md
- [x] docs/ops/backup_restore.md
- [x] docs/ops/dr_drill.md
- [x] docs/runbooks/tls_config_invalid.md

## Тестирование
- [x] integration: TLS reload smoke (SSE держится, шаг 2)
- [x] integration: DR drill smoke (restore + integrity + ingest→snapshot, шаг 5)
- [x] induced: tls_config_invalid (fail closed + startup backlog публикация, шаг 6)
- [x] runtime smoke: `scripts/tests/ops_stage23_smoke.sh` (backup/restore + ingest→snapshot + SIGHUP stream survival)

## CI gate
- [x] CI job `ops-smoke` существует и запускается на PR в main
- [x] CI job `ops-docs-gate` существует и запускается на PR в main
- [x] `ops-docs-gate` запускает `scripts/ci/check_ops_stage23_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/ops/deploy_k8s.md` содержит `cert-manager` и `ClusterIssuer` и `art-tls`
    - [x] `docs/ops/tls_rotation.md` содержит `SIGHUP` и `stream` и `ops_stage23_smoke.sh`
    - [x] `docs/ops/db_migration_runbook.md` содержит `integrity` и `rollback`
    - [x] `docs/ops/backup_restore.md` содержит `sqlite3` и `.backup` и `integrity`
    - [x] `docs/ops/dr_drill.md` содержит `ingest` и `snapshot` и `pass/fail` и `ops_stage23_smoke.sh`
    - [x] `docs/runbooks/tls_config_invalid.md` содержит `mitigations` и `verification`
    - [x] `docs/governance/observability_gap_registry.md` содержит `tls_config_invalid`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] k8s deploy описан и использует cert-manager как единственный TLS механизм.
- [x] systemd TLS rotation через SIGHUP без простоя описан и проверен smoke тестом.
- [x] DB migration runbook описан и содержит integrity check + rollback.
- [x] WAL-aware backup зафиксирован как `sqlite3 .backup` при остановленном Core.
- [x] DR drill выполнен и зафиксирован отчётом с pass/fail.
- [x] `observability_gap.tls_config_invalid` реализован, зарегистрирован и покрыт induced test (включая публикацию startup backlog в snapshot/stream).
- [x] CI gate Stage 23 зелёный.

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
