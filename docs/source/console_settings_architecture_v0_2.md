# Console Settings Architecture v0.2 (RU)
Дата: 2026-03-06  
Статус: normative draft (foundation-level)

## 1. Цель
Зафиксировать единую карту меню настроек Art Console, чтобы:
- развитие шло без “переезда” пунктов между этапами;
- поиск по настройкам был детерминированным;
- policy lock из Core применялся единообразно;
- любой параметр имел owner/scope/verification.

## 2. Модель уровней (scope hierarchy)
Порядок приоритета (сверху вниз):
1. `Global` (инстанс/платформа)
2. `Organization`
3. `Project`
4. `Environment` (`prod|stage|dev`)
5. `User`

Правило:
- нижний уровень может переопределять верхний только если политика это разрешает.
- locked поля отображаются в UI как read-only с указанием источника lock.

## 3. Навигация настроек (основное меню)
### 3.1 `Appearance & Layout`
- Theme profile (`auto|light|dark|high-contrast`)
- Palette preset + semantic token overrides
- Typography (font family/scale/line-height)
- Density and spacing
- Borders and corner profile
- Opacity/Brightness (global + panel + text + line)
- Motion policy (`reduced|standard|enhanced`)

### 3.2 `Audio & Haptics`
- Audio enable
- Master/UI/Alert/Melody volume
- Spatial mode (`off|subtle|immersive`)
- EQ (`bass/treble`) + reverb
- Effect map (каждый эффект: preview/replace/clear)
- Legal notice + usage log for custom uploads

### 3.3 `Notifications`
- Alert channels and priorities
- Throttling/dedup windows
- Quiet windows / on-call profiles
- Incident class routing (DNA/gap/action)

### 3.4 `Investigations`
- Evidence-first strictness level
- Claim rendering policies
- Dialogic protocol defaults
- InvestigationDoc import/export/replay defaults
- RTP/LRC/NRAC experiment toggles (feature-flag controlled)

### 3.5 `Flow / Spatial / 3D`
- Flow complexity (`read-only|advanced`)
- Node/cloud detail level
- Snapshot/replay defaults
- Weak-GPU profile and auto-downgrade
- 3D operational/cinematic mode lock

### 3.6 `Security / Privacy / Compliance`
- Redaction display policy
- Evidence access scope display
- Audit proof visibility defaults
- Data retention/anonymization profile visibility
- Session hardening options

### 3.7 `Integrations`
- Core endpoint profiles
- REGART bridge profile selectors
- External webhook connectors (if enabled)
- Import/export connector templates

### 3.8 `Performance & Diagnostics`
- Perf HUD visibility
- Worker/offload diagnostics
- Local stores diagnostics (cache/index/analytics/spatial)
- Log verbosity for client runtime
- Safe mode toggles

### 3.9 `Language & Accessibility`
- UI language (`EN` default, `RU` required)
- Tooltip verbosity
- Keyboard hints
- Reduced motion
- Contrast assist

## 4. Подкатегории и формат пункта
Каждый пункт настроек описывается структурой:
- `id`
- `label_key`
- `scope` (`global|org|project|env|user`)
- `type` (`toggle|select|range|color|file|action`)
- `default`
- `policy_lockable` (`true|false`)
- `verify` (команда/тест)
- `owner_component`

## 5. Поиск по настройкам
Поиск работает по:
- label
- synonyms/tags
- техническому id
- связанным поверхностям (`command-center`, `flow`, `incident-room`)

Поведение:
- фильтрует пункты и группы без потери структуры;
- показывает `N` найденных;
- подсвечивает совпадения;
- пустой query возвращает полный список.

## 5.1 Settings Profile Manager (обязательный)
- Операции: `save`, `apply`, `delete`, `export`, `import`.
- Профиль содержит полный snapshot пользовательских настроек.
- Ограничения:
  - лимит количества профилей (защита от засорения local storage),
  - валидация структуры при import,
  - policy-locked поля не должны изменяться через профиль.
- UI обязан показывать status операций профиля и текущий выбранный профиль.

## 6. Policy lock model
UI обязан показывать:
- locked status
- источник lock (scope + policy id)
- reason text
- возможный путь эскалации (runbook/action)

## 7. Ownership и верификация
Минимум:
- каждый блок настроек связан с checklist stage;
- для каждого блока есть CI/test gate;
- изменение default требует обновления Foundation и changelog.

## 8. Stage mapping (28..38)
- Stage 28: foundation framework + search + audio baseline
- Stage 30/31: investigation/protocol defaults
- Stage 33: secure actions settings + policy simulation defaults
- Stage 35: flow/spatial/3D settings
- Stage 37: linux prod lock profiles and hardening defaults

## 9. DoD для Settings Architecture
- Меню покрывает все ключевые поверхности и runtime контуры.
- Есть иерархия scope + policy lock.
- Есть search model и id-based спецификация пунктов.
- Есть stage mapping и тестовые артефакты.
