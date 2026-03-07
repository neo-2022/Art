# Политика MCP режимов

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/governance/audit_policy.md`
- `docs/governance/change_policy.md`

## Базовый принцип

MCP disabled by default.

- `enable=false` по умолчанию;
- включение MCP без явного operational решения запрещено.

## Режимы

### `read_only`

- execute action запрещён;
- разрешены только чтение, inspect, explain, export доказательств в рамках policy;
- любые попытки действия должны попасть в аудит как denied.

### `limited_actions`

Разрешён только явный allowlist:

- `read_snapshot`
- `read_stream`
- `inspect_evidence`
- `verify_audit_proof`
- `open_runbook`
- `request_preflight`
- `simulate_action`
- `create_investigation_doc`

Запрещено в `limited_actions`:

- прямой execute destructive action;
- обход preflight;
- изменение policy/config/release state;
- отключение audit/logging.

### `full_admin`

- допускается только для роли `admin` или эквивалентной операционной роли, зафиксированной в RACI;
- обязателен аудит;
- обязателен traceable owner;
- должен существовать reason/evidence для каждого действия.

## Критерий актуальности

Документ считается актуальным только если:

- указан `default: enable=false`;
- явно запрещён execute action при `read_only`;
- приведён точный allowlist для `limited_actions`;
- описан допуск в `full_admin` через роль и аудит.
