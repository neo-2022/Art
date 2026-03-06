# Матрица хранения данных

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/data_classification.md`
- `docs/privacy/redaction_policy.md`
- `docs/privacy/regional_profiles.md`

## Назначение

Матрица определяет:
- какие типы данных хранятся;
- где они хранятся;
- сколько хранятся;
- каким методом удаляются;
- какой компонент отвечает за исполнение policy.

## Каноническая матрица

| Тип данных | Срок хранения | Место хранения | Метод удаления | Owner component |
|---|---|---|---|---|
| `events` | `30 days` | `core/storage (sqlite/event store)` | `hard delete` | `core/storage` |
| `incidents` | `180 days` | `core/incidents (sqlite)` | `hard delete` | `core/incidents` |
| `audit` | `365 days` | `core/audit (append-only sqlite)` | `hard delete` | `core/audit` |
| `attachments` | `30 days` | `core/attachments (blob/local)` | `hard delete` | `core/attachments` |
| `raw archive` | `0 days / disabled by default` | `not enabled by default` | `hard delete` | `core/storage` |

## Дополнительные правила

### Events

- `events` предназначены для оперативной диагностики и replay-контуров ограниченного горизонта;
- срок хранения baseline = `30 days`;
- продление retention возможно только через профиль и отдельную policy.

### Incidents

- `incidents` хранятся дольше, чем events, потому что являются уже агрегированными проблемами и operational knowledge;
- baseline retention = `180 days`.

### Audit

- `audit` хранится не менее `365 days`;
- это minimum baseline, а не максимум;
- профили compliance могут ужесточать срок, но не сокращать ниже baseline без отдельного regulatory justification.

### Attachments

- attachments считаются наиболее рискованной категорией по privacy surface;
- baseline retention короче, чем для incidents/audit;
- attachment retention должен дополнительно уважать sensitivity label и profile constraints.

### Raw archive

- `raw archive` не считается включённым по умолчанию;
- если архивирование не активировано, retention считается `0 days / disabled by default`;
- при включении raw archive должен пройти отдельный policy review и быть отражён в profile-specific policy.

## Метод удаления

Для текущего baseline выбран один фиксированный метод:
- `hard delete`

Это означает:
- запись или объект удаляются физически из управляемого хранилища;
- в privacy baseline не используется двойственность `hard delete / crypto-shred` для одного и того же типа данных;
- если в будущем для конкретного контура будет введён `crypto-shred`, это должно быть зафиксировано как отдельное policy change.

## Ограничения и профили

- региональные или compliance-профили могут только:
  - ужесточать retention;
  - вводить более строгие export rules;
  - сокращать attachment retention;
- profile override не должен молча ослаблять privacy baseline.

## Критерий актуальности

Документ считается актуальным только если:
- перечислены `events`, `incidents`, `audit`, `attachments`, `raw archive`;
- для каждого указаны срок хранения, место хранения, метод удаления и `owner_component`;
- используется один зафиксированный метод удаления для каждого типа данных без двусмысленности.
