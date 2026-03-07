# Runbook policy

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/full_line_by_line_audit_program_v0_2.md`

## Цель
Зафиксировать единый hostile-grade стандарт runbook-корпуса для всех случаев, где создаётся инцидент или требуется обязательное действие по `observability_gap.*`, `SLO breach`, security/compliance/runtime violation.

## Обязательные разделы runbook
Каждый runbook в `docs/runbooks/` обязан содержать непустые разделы:
- `Source of truth`
- `symptoms`
- `checks`
- `mitigations`
- `rollback`
- `verification`
- `escalation`
- `evidence`
- `owner`
- `degraded mode`

## Смысл обязательных разделов
- `Source of truth`: канонические документы, реестр событий, checklist или контракт, на который опирается runbook.
- `symptoms`: конкретные внешние признаки, по которым инженер распознаёт сценарий.
- `checks`: шаги triage и исключения альтернативных причин.
- `mitigations`: безопасные действия по локализации и устранению причины.
- `rollback`: когда и как откатывать последнее изменение; если rollback неприменим, это явно фиксируется.
- `verification`: как доказать восстановление и отсутствие regressions.
- `escalation`: когда и кому эскалировать, включая Incident Commander / on-call / Security.
- `evidence`: какие артефакты обязаны быть сохранены до и после remediation.
- `owner`: кто отвечает за исполнение и кто владеет компонентом.
- `degraded mode`: какой безопасный урезанный режим допускается, если полное восстановление пока невозможно.

## Обязательные правила качества
- Runbook хранится только в `docs/runbooks/`.
- `action_ref` всегда указывает на относительный путь вида `docs/runbooks/<name>.md`.
- Запрещены пустые и формальные runbook'и без эксплуатационного смысла.
- Runbook обязан исключать лечение только симптома: в `checks` и `verification` обязательно учитываются альтернативные причины и regressions в соседних слоях.
- Runbook обязан сохранять evidence до разрушительных действий, restart/rollback/redeploy.
- Если сценарий относится к hostile runtime, `verification` обязана проверять не только happy-path, но и отсутствие повторного срабатывания в смежном слое.
- Если для сценария существует допустимый degraded mode, он должен быть описан явно; если недопустим, это тоже должно быть записано явно.

## Хранение и связь с incident/action контуром
- `action_ref` в реестре `observability_gap_registry.md`, в SLO breach mapping и в других policy-файлах обязан ссылаться только на существующий runbook.
- Каждый runbook должен быть пригоден для работы без внешнего контекста: инженер должен понимать симптомы, безопасные действия, rollback и критерии успеха, открыв один файл.
