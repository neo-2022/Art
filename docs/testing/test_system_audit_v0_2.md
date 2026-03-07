# Аудит тестового контура v0.2

## Source of truth
- `docs/testing/production_adversarial_validation_law.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/TRACEABILITY_V0_2.md`

## Назначение
Этот документ фиксирует текущее состояние тестового корпуса проекта `Art` относительно production-adversarial стандарта.

## Классы аудита
- `F` — формальный
- `B` — поведенческий
- `O` — эксплуатационный
- `A` — adversarial / hostile-environment

## Сводка состояния

### Сильные зоны
- stages `10`, `11`, `12`, `17`, `18`, `22`, `29`, `32`, `33`, `34`, `37`
- здесь уже есть mix из runtime, chaos, anti-breakage, replay, Linux/container execute paths

### Слабые зоны
- stages `01..09`
- части `19`, `20`, `24`, `25`, `26`
- значительная часть docs-gates

Основная проблема слабых зон:
- тесты часто проверяют наличие текста/файлов/маркеров;
- эксплуатационный эффект подтверждается не всегда;
- adversarial-сценарии выражены не везде;
- некоторые gates исторически были “структурно-правильными”, но не production-строгими.

## Матрица по стадиям

| Этап | Текущее состояние | Класс преобладающих проверок | Основной gap |
|---|---|---|---|
| 01 | частично усилен | `F + B` | не хватает system-level governance misuse scenarios |
| 02 | усилен | `F + B` | privacy runtime negative coverage ещё надо углублять |
| 03 | усилен | `F + B` | migration/profile misuse negative path нужно делать глубже |
| 04 | активно усиливается | `F + B + O` | часть security workflow только сейчас доводится до реального operational эффекта |
| 05 | смешанный | `F + B` | внешний wrapper path требует больше hostile integration coverage |
| 06 | смешанный | `F + B` | bridge negative/correlation misuse надо усиливать |
| 07 | слабый | `F` | слишком много repo/docs/meta gates без behavioural counterpart |
| 08 | средний | `F + B` | contract negative suite нужно держать ближе к runtime consumers |
| 09 | средний | `F + B` | source-coverage и external telemetry adapters требуют runtime hostile cases |
| 10 | сильный | `B + O + A` | baseline хороший |
| 11 | сильный | `B + O + A` | baseline хороший |
| 12 | сильный | `B + O + A` | baseline хороший |
| 13 | средний | `F + B` | rules security/false-correlation adversarial depth стоит нарастить |
| 14 | средний | `B + O` | stream pressure/reconnect adversarial matrix можно усилить |
| 15 | средний | `F + B` | policy bypass hostile checks нужно углублять |
| 16 | сильный | `B + O + A` | baseline хороший |
| 17 | сильный | `B + O + A` | baseline хороший |
| 18 | сильный | `B + O + A` | baseline хороший |
| 19 | слабый | `F` | pack runtime/materialization недостаточны |
| 20 | слабый | `F + B` | REGART payload/runtime proof недостаточен |
| 21 | средний | `F + B` | self-obs hostile matrix требует усиления |
| 22 | сильный | `B + O + A` | baseline хороший |
| 23 | средний | `F + O` | DR hostile execute paths надо усиливать |
| 24 | средний | `F + O` | release regression должен стать ещё менее документозависимым |
| 25 | средний | `F + O` | compliance export hostile/tamper cases не везде доведены |
| 26 | средний | `F + O` | RU/certified profile требует больше runtime hostility |
| 27 | служебный | `F` | это audit/remediation слой |
| 28..45 | смешанный | зависит от этапа | continuation stages изначально должны проектироваться по A-law |

## Обязательная программа усиления

### 1. Для всех docs-gates
Каждый важный docs-gate должен иметь связанный behavioural или operational counterpart.

### 2. Для security/release paths
Каждый gate обязан различать:
- infrastructure failure;
- содержательный finding;
- policy violation;
- expected negative scenario.

### 3. Для platform/agent/runtime paths
Каждый критичный путь должен иметь:
- runtime smoke;
- negative scenario;
- hostile scenario;
- evidence artifact.

### 4. Для UI and console paths
Каждый важный UX law должен иметь:
- render/assertion test;
- anti-breakage path;
- degraded/fallback path;
- locale-sensitive negative scenario.

## Правило использования аудита
Этот документ не закрывает чек-листы сам по себе. Он обязан использоваться как:
- источник расширения checklist-пунктов;
- источник усиления gates;
- источник решений, где формальный тест должен быть заменён runtime/adversarial проверкой.
