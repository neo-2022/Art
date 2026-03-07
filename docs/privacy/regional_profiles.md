# Privacy regional profiles

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/source/checklists/CHECKLIST_03_REGIONAL_PROFILES.md`
- `docs/privacy/retention_matrix.md`

## Назначение

Документ фиксирует региональные различия privacy baseline и механизм выбора профиля.

## Профили

| profile | retention difference | DSR difference |
|---|---|---|
| `global` | baseline retention | baseline DSR |
| `eu` | stricter retention for attachments and export artifacts | extended export constraints |
| `ru` | local residency constraints, stricter export handling | export restrictions and local processing requirements |

## Механизм выбора профиля

Механизм выбора профиля:
- config key: `profile_id`
- effective profile: `effective_profile_id`
- silent default profile запрещён

Жёсткое правило:
- выбор профиля должен быть явным и auditable;
- profile switch не должен происходить “по неявной эвристике”;
- если профиль не определён или невалиден, запуск и apply-config блокируются, а не переключаются на `global`.

## Правило различий

Regional profile имеет право:
- ужесточать retention;
- ужесточать export policy;
- ужесточать attachment handling;

Regional profile не имеет права:
- молча ослаблять baseline privacy protection.

## Критерий актуальности

Документ считается актуальным только если:
- перечислены профили;
- различия retention/DSR даны таблично;
- указан механизм выбора профиля;
- указан default profile.
