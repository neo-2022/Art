# Console Boot Failed Runbook

Событие: `observability_gap.console_boot_failed`  
Компонент: `browser/panel0`  
Тип реакции: `log_only` (без авто-инцидента, но с обязательной диагностикой причины)

## Source of truth
- `docs/governance/runbook_policy.md`
- `docs/governance/observability_gap_registry.md`
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`

## symptoms
- Пользователь открывает `GET /`, но основная Console не становится доступной.
- Через 5 секунд происходит auto-fallback на `GET /panel0`.
- В Panel0 отображается аварийная панель; при недоступном Core показывается `Core недоступен`.
- В snapshot/stream появляется событие `observability_gap.console_boot_failed` (или сначала копится в browser backlog и доставляется при восстановлении Core).

## checks
1. Проверить, что Core отдаёт bootstrap и Panel0-роуты:
   - `GET /`
   - `GET /panel0`
   - `GET /panel0/panel0.js`
   - `GET /panel0/panel0.css`
   - `GET /panel0/panel0_sw.js`
   - `GET /panel0/favicon.ico`
2. Проверить событие в `GET /api/v1/snapshot` или `GET /api/v1/stream`:
   - `kind = observability_gap.console_boot_failed`
   - `details.reason_type` в одном из значений: `network_error | http_error | timeout | runtime_crash`
3. Проверить обязательные поля evidence:
   - `reason_type`
   - `url`
   - `http_status` (число или `null`)
   - `error_text` (строка)
   - `timeout_ms` (число или `null`)
   - `build_id`
   - `effective_profile_id`
   - `trace_id`
4. Проверить конфиг bootstrap:
   - `ART_CONSOLE_BASE_PATH` корректен (относительный путь вида `/...`)
   - `PANEL0_BUILD_ID` установлен ожидаемо (или используется default `dev`)

## mitigations
1. Восстановить доступность Console по пути `ART_CONSOLE_BASE_PATH`:
   - устранить сетевую ошибку (`network_error`)
   - исправить HTTP ошибку (`http_error`)
   - исправить длительный старт/ready (`timeout`)
   - устранить JS boot crash (`runtime_crash`)
2. Подтвердить восстановление:
   - `GET /` больше не уходит в fallback после 5 секунд
   - Console открывается штатно
3. При наличии backlog в браузере:
   - открыть `GET /panel0` и дождаться доступности Core
   - убедиться, что backlog доставлен и событие видно в snapshot/stream
4. Зафиксировать причину и corrective action в postmortem/ops-журнале (если повторяется).

## rollback
- Если после релиза частота `observability_gap.console_boot_failed` превышает порог (`>5/5m` на инстанс), выполнить rollback на предыдущий стабильный tag.
- После rollback запустить Linux readiness прогон:
  - `bash scripts/tests/panel0_linux_prod_readiness.sh`
- До повторного rollout убедиться, что порог больше не превышается.

## verification
- Повторная проверка не воспроизводит сигнал `observability_gap.console_boot_failed`.
- Snapshot/stream/метрики подтверждают восстановление без новых regressions.
- Смежные hostile paths не деградировали после remediation.

## escalation
- Эскалировать on-call и Incident Commander, если mitigation не восстановила сервис в рамках SLA severity.
- При SEV1+ или повторном срабатывании приложить evidence refs и связанный incident/postmortem trail.

## evidence
- Сохранить event payload, `trace_id`/`request_id`/`audit_id`, affected component, version/build, config diff и relevant log excerpts.
- Для UI/runtime проблем приложить screenshot/video reproduction и browser/runtime context.
- Для release/config проблем приложить commit/tag/PR и rollback decision.

## owner
- Основной владелец: дежурный инженер и компонент-владелец по RACI/реестру событий.
- Ответственный за эскалацию: Incident Commander для SEV1+ или затяжного инцидента.

## degraded mode
- Если полное восстановление недоступно, включить документированный degraded/read-only mode для затронутой поверхности.
- Зафиксировать scope деградации, срок действия и условие выхода из degraded mode.
