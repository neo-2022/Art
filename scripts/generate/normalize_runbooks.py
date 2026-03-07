#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from collections import OrderedDict
import re

RUNBOOKS_DIR = Path('docs/runbooks')

CANONICAL_ORDER = [
    'source_of_truth',
    'symptoms',
    'checks',
    'mitigations',
    'rollback',
    'verification',
    'escalation',
    'evidence',
    'owner',
    'degraded_mode',
]

DISPLAY = {
    'source_of_truth': 'Source of truth',
    'symptoms': 'symptoms',
    'checks': 'checks',
    'mitigations': 'mitigations',
    'rollback': 'rollback',
    'verification': 'verification',
    'escalation': 'escalation',
    'evidence': 'evidence',
    'owner': 'owner',
    'degraded_mode': 'degraded mode',
}

ALIASES = {
    'source of truth': 'source_of_truth',
    'symptoms': 'symptoms',
    'diagnosis': 'checks',
    'checks': 'checks',
    'resolution': 'mitigations',
    'mitigations': 'mitigations',
    'rollback': 'rollback',
    'verification': 'verification',
    'escalation': 'escalation',
    'evidence': 'evidence',
    'owner': 'owner',
    'degraded mode': 'degraded_mode',
}


def event_hint(title: str, preamble: str) -> str:
    m = re.search(r'`([^`]+)`', title + '\n' + preamble)
    if m:
        return m.group(1)
    raw = title.replace('# Runbook:', '').replace('#', '').strip()
    return raw


def default_source(event: str) -> str:
    lines = ['- `docs/governance/runbook_policy.md`']
    if event.startswith('observability_gap.'):
        lines.append('- `docs/governance/observability_gap_registry.md`')
    lines.append('- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`')
    return '\n'.join(lines)


def default_texts(event: str) -> dict[str, str]:
    return {
        'source_of_truth': default_source(event),
        'symptoms': (
            f'- В snapshot/stream/логах наблюдается сигнал `{event}` или эквивалентный сбой.\n'
            '- Нарушение влияет на связанный компонент и требует triage в рамках текущего SLA.'
        ),
        'checks': (
            '- Проверить последнее событие, `trace_id`/`request_id`/`audit_id`, affected component и time window.\n'
            '- Проверить связанный конфиг, последний релиз, feature flags и состояние зависимостей.\n'
            '- Исключить смежные причины: transport, storage, auth, network, data drift.'
        ),
        'mitigations': (
            '- Ограничить воздействие на пользователей и зависимые контуры безопасным способом.\n'
            '- Применить исправляющее действие только после подтверждения причины и evidence chain.\n'
            '- Зафиксировать, что было изменено, кем и в какой момент.'
        ),
        'rollback': (
            '- Если инцидент вызван последним релизом, конфигом или ручным изменением, откатить последнее подтверждённое изменение до stable baseline.\n'
            '- Если rollback неприменим, явно зафиксировать это в evidence и перейти к эскалации.'
        ),
        'verification': (
            f'- Повторная проверка не воспроизводит сигнал `{event}`.\n'
            '- Snapshot/stream/метрики подтверждают восстановление без новых regressions.\n'
            '- Смежные hostile paths не деградировали после remediation.'
        ),
        'escalation': (
            '- Эскалировать on-call и Incident Commander, если mitigation не восстановила сервис в рамках SLA severity.\n'
            '- При SEV1+ или повторном срабатывании приложить evidence refs и связанный incident/postmortem trail.'
        ),
        'evidence': (
            '- Сохранить event payload, `trace_id`/`request_id`/`audit_id`, affected component, version/build, config diff и relevant log excerpts.\n'
            '- Для UI/runtime проблем приложить screenshot/video reproduction и browser/runtime context.\n'
            '- Для release/config проблем приложить commit/tag/PR и rollback decision.'
        ),
        'owner': (
            '- Основной владелец: дежурный инженер и компонент-владелец по RACI/реестру событий.\n'
            '- Ответственный за эскалацию: Incident Commander для SEV1+ или затяжного инцидента.'
        ),
        'degraded_mode': (
            '- Если полное восстановление недоступно, включить документированный degraded/read-only mode для затронутой поверхности.\n'
            '- Зафиксировать scope деградации, срок действия и условие выхода из degraded mode.'
        ),
    }


def parse(path: Path):
    lines = path.read_text().splitlines()
    title = lines[0].rstrip() if lines else '# Runbook'
    preamble: list[str] = []
    sections: OrderedDict[str, list[str]] = OrderedDict()
    extras: list[tuple[str, list[str]]] = []
    current_key = None
    current_title = None
    current_lines: list[str] = []
    before_sections = True

    def flush():
        nonlocal current_key, current_title, current_lines
        if current_title is None:
            return
        key = current_key or current_title
        target = sections if current_key else OrderedDict()
        if current_key:
            if current_key in sections:
                sections[current_key].extend(current_lines)
            else:
                sections[current_key] = current_lines[:]
        else:
            extras.append((current_title, current_lines[:]))
        current_key = None
        current_title = None
        current_lines = []

    for line in lines[1:]:
        if line.startswith('## '):
            before_sections = False
            flush()
            heading = line[3:].strip()
            key = ALIASES.get(heading.lower())
            current_key = key
            current_title = heading
            current_lines = []
        else:
            if before_sections:
                preamble.append(line)
            else:
                current_lines.append(line)
    flush()
    while preamble and not preamble[0].strip():
        preamble.pop(0)
    while preamble and not preamble[-1].strip():
        preamble.pop()
    return title, preamble, sections, extras


def render(path: Path):
    title, preamble, sections, extras = parse(path)
    event = event_hint(title, '\n'.join(preamble))
    defaults = default_texts(event)
    out: list[str] = [title]
    if preamble:
        out.append('')
        out.extend(preamble)
    for key in CANONICAL_ORDER:
        body = sections.get(key)
        if body is None:
            body = defaults[key].splitlines()
        body = body[:] if body else []
        while body and not body[0].strip():
            body.pop(0)
        while body and not body[-1].strip():
            body.pop()
        out.append('')
        out.append(f'## {DISPLAY[key]}')
        if body:
            out.extend(body)
        else:
            out.append('- Непустой раздел обязателен по policy.')
    for heading, body in extras:
        out.append('')
        out.append(f'## {heading}')
        out.extend(body)
    text = '\n'.join(out).rstrip() + '\n'
    path.write_text(text)


def main():
    for path in sorted(RUNBOOKS_DIR.glob('*.md')):
        render(path)


if __name__ == '__main__':
    main()
