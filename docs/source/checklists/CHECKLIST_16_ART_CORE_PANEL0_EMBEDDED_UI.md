A) Полный запрет опциональности:
# CHECKLIST 16 — Panel0 embedded UI
Файл: CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: 2026-03-05  
Триггер пересмотра: изменение UI; изменение gap событий; изменение offline требований

## Цель
Panel0 без двусмысленности: gap подсветка; core-down placeholder; service worker cache обязателен; минимальная диагностика (effective_profile_id, build/version).

## Границы
Минимальная встроенная панель (embedded UI), без “полного” UI Art.

## Зависимости
- CHECKLIST 14 — Stream/Snapshot v1 (SSE)
- CHECKLIST 15 — Actions/Audit/RBAC/PII

## Шаги (строго линейно)

- [x] **1. Сделать:** Реализовать визуальное выделение всех `observability_gap.*` в Panel0 (единый дизайн).
  - [x] Для каждого события с `kind` начинающимся на `observability_gap.` отображается:
    - [x] иконка (фиксированная: ⚠)
    - [x] цвет (фиксированный: amber)
    - [x] tooltip содержит:
      - [x] `kind`
      - [x] `what`
      - [x] `where`
      - [x] `why`
      - [x] `action_ref` (если присутствует)
      - [x] `trace_id`
  - [x] Tooltip не показывает PII/секреты (включая tokens/headers/cookies)
  - [x] **Проверка (pass/fail):** e2e UI test создаёт synthetic `observability_gap.*` и проверяет иконку/цвет/tooltip поля.

- [x] **2. Сделать:** Реализовать core-down placeholder: при недоступности API Panel0 показывает заглушку + кнопку reload.
  - [x] Условие “core down” фиксировано: любая из ситуаций:
    - [x] `/health` недоступен (network error) или HTTP 503
    - [x] `/api/v1/snapshot` недоступен (network error) или HTTP 503
  - [x] UI показывает placeholder с фиксированными элементами:
    - [x] текст `Core недоступен`
    - [x] краткая причина (network error / HTTP code)
    - [x] кнопка `Reload` (перезапускает попытку загрузки snapshot/health)
  - [x] При восстановлении Core UI автоматически уходит с placeholder и отображает нормальный вид
  - [x] **Проверка (pass/fail):** e2e test “Core stopped”: останавливает Core, проверяет placeholder+Reload, затем поднимает Core и проверяет авто-восстановление UI.

- [x] **3. Сделать:** Реализовать service worker cache для embedded assets Panel0.
  - [x] Service Worker существует и регистрируется только для Panel0 (scope фиксирован)
  - [x] Precache фиксированного набора ассетов (без двусмысленности):
    - [x] `index.html`
    - [x] `panel0.js`
    - [x] `panel0.css`
    - [x] `favicon` (если есть)
  - [x] Cache versioning фиксирован: `panel0-cache-<build_id>`
  - [x] Update стратегия фиксирована:
    - [x] новый SW активируется сразу (skipWaiting)
    - [x] новые ассеты начинают использоваться после reload
  - [x] **Проверка (pass/fail):** offline reload test:
    - [x] первый заход online прогревает cache
    - [x] затем отключаем сеть
    - [x] reload страницы загружает UI из cache (без сети) и показывает offline-индикатор.

- [x] **4. Сделать:** Добавить в Panel0 минимальную диагностику сборки и профиля (для оперативной поддержки).
  - [x] В Panel0 отображается `build_id` (строка)
  - [x] В Panel0 отображается `effective_profile_id` (строка)
  - [x] Источник `effective_profile_id` фиксирован: `GET /api/v1/snapshot` возвращает поле `effective_profile_id` в payload (одно фиксированное решение)
  - [x] **Проверка (pass/fail):** e2e test проверяет, что `build_id` и `effective_profile_id` видны в UI и не пустые.

## Документация (RU)
- [x] docs/ui/panel0.md
- [x] docs/ui/panel0_offline.md
- [x] docs/ui/panel0_sw_cache.md

## Тестирование
- [x] e2e: gap highlight (шаг 1)
- [x] e2e: core-down placeholder (шаг 2)
- [x] e2e: offline cache (шаг 3)
- [x] e2e: offline/SW negative scenarios (cache-miss→503 `x-art-offline`, cache put fail, insecure-context no-register)
- [x] e2e: build_id + effective_profile_id (шаг 4)

## CI gate
- [x] CI job `panel0-e2e` существует и запускается на PR в main; job зелёный
- [x] CI job `stage16-docs-gate` существует и запускает `scripts/ci/check_panel0_stage16_docs.sh`, который:
  - [x] проверяет существование файлов из раздела “Документация (RU)”
  - [x] проверяет минимальный контент (grep):
    - [x] `docs/ui/panel0.md` содержит `observability_gap.`
    - [x] `docs/ui/panel0_offline.md` содержит `offline` и `reload`
    - [x] `docs/ui/panel0_sw_cache.md` содержит `panel0-cache-`, `skipWaiting`, `x-art-offline`, `secure context`
  - [x] exit 1 при нарушении любой проверки

## DoD
- [x] Panel0 отображает `observability_gap.*` с фиксированным дизайном и без утечек PII.
- [x] Panel0 корректно показывает core-down placeholder и восстанавливается после подъёма Core.
- [x] Panel0 работает офлайн (embedded assets через SW cache).
- [x] Panel0 показывает `build_id` и `effective_profile_id`.
- [x] CI gate Stage 16 зелёный.
