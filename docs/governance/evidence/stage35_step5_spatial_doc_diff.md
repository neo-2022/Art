# Spatial Store v0.2

Последняя актуализация: 2026-03-06

## Цель
Реализовать слой пространственных данных для deterministic 3D/XR projection.

## Runtime model
- TypedArrays (SoA)
- spatial index для picking/visibility
- keyframes для time playback

## Persist model
- IndexedDB binary chunks
- rebuildable index metadata

## Инварианты
- Нет полного перебора всех узлов на кадр.
- LOD и picking воспроизводимы.

## 3D MVP Scope
1. Отображение объектов с deterministic layout.
2. Picking/visibility с индексом (без brute-force).
3. Синхронизация выбора 2D<->3D.
4. Feature-flag fallback при слабом GPU.
5. Без 3D-редактирования и без XR authoring на этапе v0.2.

## Weak GPU Policy
- Обязательный профиль тестирования `weak-gpu`.
- На старте выполняется GPU capability profiling и выбор fallback profile.
- При риске выхода за budget включается авто-деградация качества (LOD + упрощённая графика, затем 2D mode при необходимости).
- Событие деградации: `observability_gap.spatial_index_degraded`.
- Минимальный класс устройств: Intel UHD 620 и эквивалентный VM GPU.
- Бюджет weak-gpu: целевой `p95 latency < 50 ms` (для picking и scene update).

## Проверка
- unit spatial primitives
- integration 2D<->3D sync
- perf picking budgets
