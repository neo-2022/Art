# Art v1 — Полная мастер-спецификация (финальная редакция)

## Статус документа
Нормативная спецификация (RFC-стиль). В тексте используются только формулировки **MUST** и явные пометки **«вне v1»**. Двусмысленные слова («опционально», «как в другой версии», «см. ранее») не используются.

**Цель:**
- **Инженерный 100%:** Art фиксирует **все доступные** измеримые сигналы проекта и окружения (браузер, процессы, systemd/journald, сеть, OTLP/sidecar, здоровье Art).
- **Продуктовый 100%:** Art объясняет: **Что / Где / Почему / Влияние / Что делать**, предоставляет действия/линки/runbook, ведёт жизненный цикл инцидентов.

---

## Оглавление
1. Цель и принцип 100%  
2. Термины  
3. Архитектура и компоненты  
4. Профили развёртывания (systemd и Kubernetes)  
5. Модель данных RawEvent / Incident  
6. Ingest протокол (ack/seq/dedupe/invalid/backpressure)  
7. Delivery semantics (spool/outbox)  
8. Pipeline Core (normalize→rules→incidents→store→stream)  
9. Инциденты: уникальность, fingerprint, коллизии, lifecycle  
10. Storage v1 (SQLite DDL + миграции + retention)  
11. Rules DSL v1 и severity policy  
12. Actions и аудит  
13. UI: Bootstrap Panel 0 и правило «UI как экран»  
14. Agent receivers (journald/systemd/files/proc/ports/net_probe/OTLP)  
15. Отказоустойчивость и нестандартные ситуации (обязательные сценарии)  
16. Производительность и масштабирование v1  
17. Безопасность, приватность, роли и доступ  
18. Российский профиль: 152‑ФЗ / ФСТЭК / КИИ / ГосСОПКА  
19. Интеграции: Prometheus/OTLP/SIEM, экспорт инцидентов, webhook  
20. Управление изменениями и версиями (release/upgrade/regression)  
21. Документация и процесс её поддержки  
22. Репозиторий и Integration Packs  
23. План реализации (WP0..WP9)  
24. Контракты (JSON Schema) и примеры конфигов  

---

## 1) Принцип 100% (строго)
1) Art MUST собирать 100% сигналов, **доступных** на данной системе и при данных правах.  
2) Любая недоступность источника/права/канала MUST оформляться RawEvent `observability_gap.*` и быть видимой в snapshot/stream.  
3) `observability_gap.*` MUST при необходимости превращаться правилами в Incident.

---

## 2) Термины
- **RawEvent** — единичный «сырой» сигнал.
- **Incident** — агрегированная проблема, полученная из RawEvent по правилам.
- **Evidence** — доказательства (стек, выдержки логов, результаты проб).
- **Action** — безопасное действие, предлагаемое системой, с аудитом.
- **Source** — источник событий (Agent, Browser Level0, сервис, ручной ввод).
- **Spool/Outbox** — надёжное локальное накопление событий до подтверждения доставки (ack).
- **Panel 0** — Bootstrap UI от Art Core, работающий до и независимо от наблюдаемого проекта.

---

## 3) Архитектура и компоненты

### 3.1 Компоненты v1 (все MUST)
- **Art Core (Rust)** — ingest → pipeline → storage → incidents → snapshot/stream → Bootstrap UI → Actions API.
- **Art Agent (Rust)** — journald/systemd/files/proc/ports/net_probe/OTLP + spool/outbox + доставка в Core.
- **Browser Level0 (JS)** — runtime ошибки, UX sensors, IndexedDB backlog, отправка в Agent/Core.

### 3.2 Sidecar Collector pipeline (встроен в Agent)
В v1 «Sidecar Collector» реализован как часть Art Agent: OTLP receivers/processors/exporters, outbox, доставка в Core.

### 3.3 Языки (жёстко)
- Core: Rust (MUST)
- Agent (+ sidecar pipeline): Rust (MUST)

---

## 4) Профили развёртывания

### 4.1 Профиль A: systemd (локальная машина / VPS)
- Core MUST запускаться как systemd user service (дефолт).
- Agent MUST запускаться как systemd user service (дефолт).
- Режим system service допускается только при явном выборе установки.

### 4.2 Профиль B: Kubernetes
- Core MUST: StatefulSet replicas=1 + PVC (SQLite) в v1.
- Agent MUST: DaemonSet.
- Panel 0 MUST доступна через Service/Ingress.
- Core replicas>1 — вне v1.

---

## 5) Модель данных RawEvent / Incident

### 5.1 RawEvent v1
Поле называется **severity** (строго). Другие имена не используются.

### 5.2 Incident v1
Incident содержит id/key/status/severity/category/scope/summary/impact/where/why/what_to_do/evidence/history/actions.

---

## 6) Ingest протокол

### 6.1 Endpoints (все MUST)
POST /api/v1/ingest  
GET /api/v1/snapshot  
GET /api/v1/stream (SSE)  
GET /api/v1/incidents  
POST /api/v1/incidents/{id}/ack  
POST /api/v1/incidents/{id}/resolve  
POST /api/v1/actions/execute  
GET /health  
GET /metrics  

### 6.2 Лимиты и backpressure (MUST)
429/503/413 + retry_after_ms + ack.upto_seq если возможно.

### 6.3 Дедуп (MUST)
primary event_id; fallback (source_id, seq).

### 6.4 invalid (MUST)
partial accept + invalid_details; data_quality.invalid_event.

### 6.5 ack semantics (MUST)
ack.upto_seq = max seq принятых (accepted+deduped).

---

## 7) Delivery semantics (Spool/Outbox)

### 7.1 Spool/outbox алгоритм (MUST)
write → send → ack → delete confirmed.

### 7.2 Spool policy (строго)
- never_drop_unacked (дефолт для 100%)
- drop_oldest_when_full (degraded) + data_quality.lossy_spool_drop + Incident lossy_mode_active

### 7.3 Потеря связи Core↔Agent (MUST)
Agent буферизует, экспортирует health, генерирует pipeline.spool_near_full.

### 7.4 Source stale (MUST)
Core создаёт observability_gap.source_stale при превышении source_stale_sec.

---

## 8) Pipeline Core (строго)
parse → validate → quality gates → fingerprint → rules → aggregate → incident → enrich → store → publish.

---

## 9) Инциденты: уникальность, fingerprint, lifecycle

### 9.1 Uniqueness (MUST)
incident_key = rule.id + fingerprint, UNIQUE в storage.

### 9.2 Одинаковый fingerprint (MUST)
один incident_key → один Incident, обновление counters/evidence/history.

### 9.3 Подозрение на коллизию fingerprint (MUST)
data_quality.fingerprint_collision_suspected с evidence.

### 9.4 Recovery Core (MUST)
WAL + dedupe.

---

## 10) Storage v1 (SQLite)

### 10.1 v1 backend (MUST)
SQLite WAL + migrations + retention.

### 10.2 Расширяемость (MUST)
storage abstraction; Postgres — вне v1; raw archive mechanism (mode=off|files|rocksdb, дефолт off).

---

## 11) Rules DSL v1 и severity policy
rules engine mode first|all; severity policy с escalation/cooldown.

---

## 12) Actions и аудит
actions декларативны; audit append-only; executor whitelist; requires_confirmation для опасных.

---

## 13) UI: Panel 0 и правило «UI как экран»
Bootstrap UI встроен в бинар (embedded) и работает без файловой системы/внешних ассетов.

---

## 14) Agent receivers
journald/systemd/files/proc/ports/net_probe/OTLP (OTLP дефолт выключен конфигом). При недоступности — observability_gap.*.

---

## 15) Отказоустойчивость и нестандартные ситуации

### 15.1 Обязательные сценарии (MUST)
offline→catchup; disk pressure; crash ingest; source stale; fingerprint collision suspected; template sanitization blocked.

### 15.2 Enrich-шаблоны: тесты экранирования/санитайзинга (MUST)
url_escape/json_escape/shell_safe_unit/path_safe/truncate + data_quality.template_sanitization_blocked.

---

## 16) Производительность и масштабирование v1
vertical core; many sources; raw archive; multi-replica core — вне v1; perf methodology + report MUST.

---

## 17) Безопасность/приватность/роли
roles viewer/operator/admin; локальная auth + header-based auth; TLS support; PII filter before store; default no HTTP bodies.

---

## 18) Российский профиль (152‑ФЗ/ФСТЭК/КИИ/ГосСОПКА)
Art v1 предоставляет тех.возможности: доступ/аудит/PII/TLS/экспорт инцидентов/шаблоны уведомлений. Юридические обязательства и сертификации обеспечиваются организацией и её средой.

---

## 19) Интеграции
Prometheus /metrics; OTLP ingest into Agent; webhooks + JSON export.

---

## 20) Управление изменениями и версиями
SemVer + release checklist + regression (schema/migrations/ack/dedupe/offline).

---

## 21) Документация и процесс поддержки
docs updated with changes; release gate; feedback templates.

---

## 22) Репозиторий и Integration Packs
packs — единственное место знаний о конкретном проекте, без хардкода в core/agent.

---

## 23) WP0..WP9
WP0 Repo/CI; WP1 Ingest; WP2 Storage; WP3 Rules; WP4 Incidents/Actions/Audit; WP5 UI embedded; WP6 Agent; WP7 Browser; WP8 Auth/Roles+Remote/K8s; WP9 Docs+Perf+Change.

---

## 24) Контракты и примеры

### 24.1 RawEvent schema (контракт)
~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "art://schemas/raw_event.json",
  "title": "Art RawEvent v1",
  "type": "object",
  "required": ["event_schema_version", "event_id", "seq", "ts", "kind", "scope", "severity", "message"],
  "additionalProperties": false,
  "properties": {
    "event_schema_version": { "type": "string", "const": "1.0" },
    "event_id": { "type": "string", "minLength": 8, "maxLength": 80 },
    "seq": { "type": "integer", "minimum": 0 },
    "ts": { "type": "string", "format": "date-time" },

    "kind": { "type": "string", "minLength": 1, "maxLength": 120 },
    "scope": { "type": "string", "minLength": 1, "maxLength": 120 },
    "severity": { "type": "string", "enum": ["debug", "info", "warn", "error", "fatal"] },

    "title": { "type": ["string", "null"], "maxLength": 256 },
    "message": { "type": "string", "minLength": 1, "maxLength": 32768 },

    "payload": { "type": "object", "additionalProperties": true },
    "context": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "trace_id": { "type": ["string", "null"], "maxLength": 128 },
        "span_id": { "type": ["string", "null"], "maxLength": 128 },
        "correlation_id": { "type": ["string", "null"], "maxLength": 128 },
        "run_id": { "type": ["string", "null"], "maxLength": 128 },
        "assistant_id": { "type": ["string", "null"], "maxLength": 128 },
        "thread_id": { "type": ["string", "null"], "maxLength": 128 },
        "node_id": { "type": ["string", "null"], "maxLength": 128 }
      }
    },

    "location": {
      "type": ["object", "null"],
      "additionalProperties": false,
      "properties": {
        "file": { "type": ["string", "null"], "maxLength": 4096 },
        "line": { "type": ["integer", "null"], "minimum": 1 },
        "col": { "type": ["integer", "null"], "minimum": 1 },
        "func": { "type": ["string", "null"], "maxLength": 512 }
      }
    },

    "evidence": {
      "type": "array",
      "maxItems": 200,
      "items": {
        "type": "object",
        "required": ["type"],
        "additionalProperties": true,
        "properties": {
          "type": { "type": "string", "minLength": 1, "maxLength": 64 },
          "text": { "type": "string", "maxLength": 65536 }
        }
      }
    },

    "tags": { "type": "array", "maxItems": 64, "items": { "type": "string", "maxLength": 64 } },
    "attrs": { "type": "object", "additionalProperties": { "type": ["string", "number", "boolean", "null"] } }
  }
}
~~~

### 24.2 IngestEnvelope schema (контракт)
~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "art://schemas/ingest_envelope.json",
  "title": "Art IngestEnvelope v1",
  "type": "object",
  "required": ["source", "events"],
  "additionalProperties": false,
  "properties": {
    "source": {
      "type": "object",
      "required": ["id", "type", "hostname", "version"],
      "additionalProperties": false,
      "properties": {
        "id": { "type": "string", "minLength": 1, "maxLength": 200 },
        "type": { "type": "string", "minLength": 1, "maxLength": 80 },
        "hostname": { "type": "string", "minLength": 1, "maxLength": 200 },
        "boot_id": { "type": ["string", "null"], "maxLength": 200 },
        "version": { "type": "string", "minLength": 1, "maxLength": 80 },
        "instance": { "type": ["string", "null"], "maxLength": 200 },
        "labels": { "type": "object", "additionalProperties": { "type": "string", "maxLength": 256 } }
      }
    },
    "events": {
      "type": "array",
      "minItems": 1,
      "items": { "$ref": "art://schemas/raw_event.json" }
    }
  }
}
~~~

### 24.3 IngestResponse schema (контракт)
~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "art://schemas/ingest_response.json",
  "title": "Art IngestResponse v1",
  "type": "object",
  "required": ["ok"],
  "additionalProperties": true,
  "properties": {
    "ok": { "type": "boolean" },
    "accepted": { "type": "integer", "minimum": 0 },
    "deduped": { "type": "integer", "minimum": 0 },
    "dropped": { "type": "integer", "minimum": 0 },
    "invalid": { "type": "integer", "minimum": 0 },
    "invalid_details": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["index", "reason"],
        "properties": {
          "index": { "type": "integer", "minimum": 0 },
          "event_id": { "type": ["string", "null"] },
          "seq": { "type": ["integer", "null"] },
          "reason": { "type": "string", "maxLength": 1024 }
        }
      }
    },
    "ack": {
      "type": ["object", "null"],
      "required": ["source_id", "upto_seq"],
      "properties": {
        "source_id": { "type": "string" },
        "upto_seq": { "type": "integer", "minimum": 0 }
      }
    },
    "error_type": { "type": ["string", "null"] },
    "reason": { "type": ["string", "null"] },
    "retry_after_ms": { "type": ["integer", "null"], "minimum": 0 },
    "hints": { "type": "array", "items": { "type": "string", "maxLength": 256 } }
  }
}
~~~

### 24.4 Incident schema (контракт)
~~~json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "art://schemas/incident.json",
  "title": "Art Incident v1",
  "type": "object",
  "required": ["incident_id", "schema_version", "status", "severity", "category", "scope", "title", "summary", "fingerprint", "incident_key", "opened_at", "updated_at"],
  "additionalProperties": true,
  "properties": {
    "incident_id": { "type": "string", "minLength": 8, "maxLength": 80 },
    "schema_version": { "type": "string", "const": "1.0" },
    "status": { "type": "string", "enum": ["active", "acknowledged", "resolved"] },
    "severity": { "type": "string", "enum": ["info", "warn", "error", "fatal"] },
    "category": { "type": "string", "minLength": 1, "maxLength": 120 },
    "scope": { "type": "string", "minLength": 1, "maxLength": 120 },

    "title": { "type": "string", "maxLength": 256 },
    "summary": { "type": "string", "maxLength": 4096 },

    "impact": { "type": "object", "additionalProperties": true },

    "fingerprint": { "type": "string", "minLength": 8, "maxLength": 128 },
    "incident_key": { "type": "string", "minLength": 1, "maxLength": 256 },
    "rule": { "type": "object", "additionalProperties": true },

    "opened_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "resolved_at": { "type": ["string", "null"], "format": "date-time" },

    "ack": { "type": ["object", "null"], "additionalProperties": true },
    "counters": { "type": "object", "additionalProperties": true },
    "evidence": { "type": "array", "items": { "type": "object", "additionalProperties": true } },
    "where": { "type": "object", "additionalProperties": true },
    "why": { "type": "object", "additionalProperties": true },
    "what_to_do": { "type": "object", "additionalProperties": true },
    "history": { "type": "array", "items": { "type": "object", "additionalProperties": true } }
  }
}
~~~

### 24.5 art.toml (пример)
~~~toml
[core]
listen_http = "127.0.0.1:7331"
listen_unix = "/run/user/1000/art.sock"          # локально (unix socket предпочтителен)
ui_enable = true                                 # Bootstrap UI
ui_static_dir = "embedded"                       # встроенные ассеты в бинар (обязательно для v1)
token_enable = false                             # дефолт: выключен
token_value = ""                                 # требуется при token_enable=true

[limits]
max_batch_events = 5000
max_batch_bytes = 10485760
max_event_bytes = 262144
max_payload_depth = 20
max_string_len = 32768

[rate_limits]
global_events_per_sec = 0                        # 0 = выключено
global_bytes_per_sec  = 0                        # 0 = выключено

[storage]
type = "sqlite"
path = "~/.local/share/art/art.db"
wal_enable = true
max_disk_mb = 20480
raw_retention_days = 7
incident_retention_days = 0                      # 0 = бессрочно
evidence_retention_days = 30

[storage.raw_archive]
mode = "off"                                     # off|files|rocksdb
path = "~/.local/share/art/raw_archive"          # используется если mode != off

[incidents.lifecycle]
auto_resolve = true
resolve_quiet_window_sec = 120
resolve_requires_health_ok = true
severity_cooldown_sec = 60

[rules.engine]
mode = "all"                                     # first|all

[actions]
default_executor = "ui"
allow_art_executor = false

[mcp]
enable = false                                   # дефолт: выключен
listen = "127.0.0.1:7332"
mode = "read_only"                               # read_only|limited_actions|full_admin

~~~

### 24.6 agent.toml (пример)
~~~toml
[agent]
id = "art-agent@devbox-01"
core_url = "http://127.0.0.1:7331/api/v1/ingest"
use_msgpack = true
flush_interval_ms = 500
batch_max_events = 2000
batch_max_bytes = 5242880

[spool]
type = "sqlite"
path = "~/.local/share/art-agent/spool.db"
max_disk_mb = 2048
retry_backoff_ms = [200, 500, 1000, 2000, 5000, 10000]
drop_policy = "never_drop_unacked"               # never_drop_unacked|drop_oldest_when_full

[receivers.journald]
enable = true
units = ["my_langgraph_langgraph.service", "my_langgraph_react_ui.service", "my_langgraph_ui_proxy.service"]
include_system = true

[receivers.file_tail]
enable = true
files = [
  { path="~/my_langgraph_agent/agent/logs/*.log", parser="plain" }
]

[receivers.proc_probe]
enable = true
interval_ms = 1500
targets = [
  { name="langgraph", port=2024, host="127.0.0.1" },
  { name="ui_proxy",  port=8090, host="127.0.0.1" }
]

[receivers.net_probe]
enable = true
interval_ms = 2000
timeout_ms = 800
targets = [
  { name="langgraph_openapi", url="http://127.0.0.1:2024/openapi.json", expect_status=[200] },
  { name="ui_proxy_health",   url="http://127.0.0.1:8090/health", expect_status=[200] }
]

[receivers.otlp]
enable = false
listen = "127.0.0.1:4318"                        # OTLP/HTTP

[mcp]
enable = false
listen = "127.0.0.1:7333"
mode = "read_only"

~~~

### 24.7 rules.toml (пример)
~~~toml
[[rules]]
id = "upstream_langgraph_connect"
priority = 800
match = { kind="http_error", scope="langgraph" }
window_sec = 30
threshold = 1
action = "open_incident"
severity = "error"
category = "upstream_unavailable"
summary_tpl = "LangGraph недоступен: {{raw_event.payload.error}}"
what_to_do_next_steps = [
  "Проверь, что сервис LangGraph запущен",
  "Проверь порт {{raw_event.payload.upstream_port}}",
  "Открой логи systemd unit LangGraph"
]
[[rules.actions]]
type = "systemd_restart"
executor = "sidecar"
label_tpl = "Перезапустить LangGraph"
params_tpl = { unit="{{raw_event.payload.unit | shell_safe_unit}}" }

[[rules]]
id = "build_failed_react_ui"
priority = 900
match = { kind="build_failed", scope="react_ui" }
window_sec = 60
threshold = 1
action = "open_incident"
severity = "error"
category = "build_failed"
summary_tpl = "Сборка/Dev-server React UI упал: {{raw_event.message}}"
[[rules.actions]]
type = "open_logs"
executor = "sidecar"
label_tpl = "Открыть логи React UI"
params_tpl = { unit="my_langgraph_react_ui.service" }

[[rules]]
id = "ui_layout_overlap"
priority = 300
match = { kind="ui.layout.overlap_detected", scope="ui" }
window_sec = 120
threshold = 3
action = "open_incident"
severity = "warn"
category = "ui_layout"
summary_tpl = "В UI обнаружено перекрытие элементов ({{counters.events_window}} раз за окно)."

[[rules]]
id = "dq_invalid_spike"
priority = 950
match = { kind="data_quality.invalid_event" }
window_sec = 60
threshold = 20
action = "open_incident"
severity = "warn"
category = "data_quality"
summary_tpl = "Источник {{source.id}} шлёт много невалидных событий ({{counters.events_window}}/мин)."

~~~
