A) Полный запрет опциональности:
# CHECKLIST 16 — Panel0 embedded UI
Файл: CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md  
Последняя актуализация: 2026-03-04  
Дата последней проверки: ________  
Триггер пересмотра: изменение UI; изменение gap событий; изменение offline требований

## Цель
Panel0 без двусмысленности: gap подсветка; core-down placeholder; service worker cache обязателен; минимальная диагностика (effective_profile_id, build/version).

## Границы
Минимальная встроенная панель (embedded UI), без “полного” UI Art.

## Зависимости
- CHECKLIST 14 — Stream/Snapshot v1 (SSE)
- CHECKLIST 15 — Actions/Audit/RBAC/PII

## Шаги (строго линейно)

- [ ] **1. Сделать:** Реализовать визуальное выделение всех `observability_gap.*` в Panel0 (единый дизайн).
  - [ ] Для каждого события с `kind` начинающимся на `observability_gap.` отображается:
    - [ ] иконка (фиксированная: ⚠)
    - [ ] цвет (фиксированный: amber)
    - [ ] tooltip содержит:
      - [ ] `kind`
      - [ ] `what`
      - [ ] `where`
      - [ ] `why`
      - [ ] `action_ref` (если присутствует)
      - [ ] `trace_id`
  - [ ] Tooltip не показывает PII/секреты (включая tokens/headers/cookies)
  - [ ] **Проверка (pass/fail):** e2e UI test создаёт synthetic `observability_gap.*` и проверяет иконку/цвет/tooltip поля.

- [ ] **2. Сделать:** Реализовать core-down placeholder: при недоступности API Panel0 показывает заглушку + кнопку reload.
  - [ ] Условие “core down” фиксировано: любая из ситуаций:
    - [ ] `/health` недоступен (network error) или HTTP 503
    - [ ] `/api/v1/snapshot` недоступен (network error) или HTTP 503
  - [ ] UI показывает placeholder с фиксированными элементами:
    - [ ] текст `Core недоступен`
    - [ ] краткая причина (network error / HTTP code)
    - [ ] кнопка `Reload` (перезапускает попытку загрузки snapshot/health)
  - [ ] При восстановлении Core UI автоматически уходит с placeholder и отображает нормальный вид
  - [ ] **Проверка (pass/fail):** e2e test “Core stopped”: останавливает Core, проверяет placeholder+Reload, затем поднимает Core и проверяет авто-восстановление UI.

- [ ] **3. Сделать:** Реализовать service worker cache для embedded assets Panel0.
  - [ ] Service Worker существует и регистрируется только для Panel0 (scope фиксирован)
  - [ ] Precache фиксированного набора ассетов (без двусмысленности):
    - [ ] `index.html`
    - [ ] `panel0.js`
    - [ ] `panel0.css`
    - [ ] `favicon` (если есть)
  - [ ] Cache versioning фиксирован: `panel0-cache-<build_id>`
  - [ ] Update стратегия фиксирована:
    - [ ] новый SW активируется сразу (skipWaiting)
    - [ ] новые ассеты начинают использоваться после reload
  - [ ] **Проверка (pass/fail):** offline reload test:
    - [ ] первый заход online прогревает cache
    - [ ] затем отключаем сеть
    - [ ] reload страницы загружает UI из cache (без сети) и показывает offline-индикатор.

- [ ] **4. Сделать:** Добавить в Panel0 минимальную диагностику сборки и профиля (для оперативной поддержки).
  - [ ] В Panel0 отображается `build_id` (строка)
  - [ ] В Panel0 отображается `effective_profile_id` (строка)
  - [ ] Источник `effective_profile_id` фиксирован: `GET /api/v1/snapshot` возвращает поле `effective_profile_id` в payload (одно фиксированное решение)
  - [ ] **Проверка (pass/fail):** e2e test проверяет, что `build_id` и `effective_profile_id` видны в UI и не пустые.

## Документация (RU)
- [ ] docs/ui/panel0.md
- [ ] docs/ui/panel0_offline.md
- [ ] docs/ui/panel0_sw_cache.md

## Тестирование
- [ ] e2e: gap highlight (шаг 1)
- [ ] e2e: core-down placeholder (шаг 2)
- [ ] e2e: offline cache (шаг 3)
- [ ] e2e: build_id + effective_profile_id (шаг 4)

## CI gate
- [ ] CI job `panel0-e2e` существует и запускается на PR в main; job зелёный
- [ ] CI job `stage16-docs-gate` существует и запускает `scripts/ci/check_panel0_stage16_docs.sh`, который:
  - [ ] проверяет существование файлов из раздела “Документация (RU)”
  - [ ] проверяет минимальный контент (grep):
    - [ ] `docs/ui/panel0.md` содержит `observability_gap.`
    - [ ] `docs/ui/panel0_offline.md` содержит `offline` и `reload`
    - [ ] `docs/ui/panel0_sw_cache.md` содержит `panel0-cache-` и `skipWaiting`
  - [ ] exit 1 при нарушении любой проверки

## DoD
- [ ] Panel0 отображает `observability_gap.*` с фиксированным дизайном и без утечек PII.
- [ ] Panel0 корректно показывает core-down placeholder и восстанавливается после подъёма Core.
- [ ] Panel0 работает офлайн (embedded assets через SW cache).
- [ ] Panel0 показывает `build_id` и `effective_profile_id`.
- [ ] CI gate Stage 16 зелёный.

