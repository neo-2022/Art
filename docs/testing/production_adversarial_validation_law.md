# Закон Production-Adversarial Validation

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/TRACEABILITY_V0_2.md`

## Назначение
Этот документ вводит для проекта `Art` обязательный принцип: любая реализация, проверка, gate, тест, релизный шаг и операционный механизм должны проектироваться так, как будто production-среда активно пытается сломать систему всеми доступными способами.

Для `Art` этого недостаточно проверять только happy-path. Система расследует инциденты и должна сама выдерживать:
- ошибки конфигурации;
- нестабильные сети;
- враждебные входные данные;
- перегрузки;
- деградацию зависимостей;
- ошибки интеграций;
- действия оператора;
- ошибки агента, bridge, CI и release pipeline;
- частичные отказы и каскадные отказные режимы.

## Базовый закон
Изменение считается завершённым только после доказанного эксплуатационного эффекта, подтверждённого разносторонним дебаггингом.

Запрещено считать изменение завершённым по:
- одному удачному запуску;
- одному smoke-тесту;
- одному grep/наличию файла;
- одному симптоматическому улучшению;
- одному зелёному check без анализа альтернативных причин.

## Закон многоуровневого спуска к корню проблемы
Art рассматривается как многоуровневая система. Поэтому любой найденный дефект обязан анализироваться не только на уровне его проявления, но и на уровнях ниже.

Обязательное правило:
1. Если дефект найден на верхнем уровне (`UI`, `workflow`, `alert`, `check`, `test`, `report`), перед исправлением требуется аудит нижнего связанного уровня.
2. Если на нижнем уровне найден дефект основания (`contract`, `runtime`, `transport`, `storage`, `config`, `policy`, `integration`, `code path`), спуск продолжается дальше.
3. Исправление считается честным только после устранения корневой причины и повторной проверки верхних уровней.
4. Исправление симптома без спуска вниз считается неполным.

Примеры допустимого спуска:
- `UI defect -> API/contract -> runtime model -> storage/provenance source`
- `CI queue/problem -> workflow topology -> job duplication -> trigger design -> branch protection expectations`
- `receiver failure -> transport -> spool/outbox -> filesystem/runtime state`
- `policy violation -> rendered state -> contract -> redaction/access-control source`

## Обязательный цикл validation
Для любого важного изменения обязателен цикл:

1. `Implementation`
- изменение реализовано;
- отражено в документации/контрактах/чек-листе.

2. `Primary validation`
- подтверждён основной ожидаемый эффект.

3. `Alternative-cause debugging`
- проверены альтернативные причины проблемы;
- исключено ложное объяснение результата;
- исключён перенос дефекта в другой слой.

4. `Negative-path validation`
- проверены хотя бы ключевые сценарии отказа;
- подтверждено, что система не даёт silent-pass.

5. `Operational-effect validation`
- подтверждено, что production-like поведение улучшилось реально;
- есть артефакт: лог, run, report, evidence.

6. `Regression containment`
- добавлен или обновлён test/gate, чтобы проблема не вернулась тихо.

## Классы тестов
Все тесты и проверки проекта должны быть отнесены к одному из классов:

### 1. Формальные
Проверяют структуру, наличие файлов, маркеров, контрактов, схем, обязательных разделов.

Пример:
- docs-gate;
- schema presence;
- checklist integrity.

Формальные тесты допустимы только как минимальный guardrail и не считаются достаточными для production-grade закрытия критичного поведения.

### 2. Поведенческие
Проверяют реальное поведение модуля, API, UI, workflow, receiver, pipeline.

Пример:
- unit/integration tests;
- contract negative tests;
- UI anti-breakage tests.

### 3. Эксплуатационные
Проверяют production-like path:
- реальные workflow;
- runtime smoke;
- replay;
- rollback;
- platform execute scenarios;
- go/no-go gates.

### 4. Adversarial / hostile-environment
Проверяют поведение в агрессивной среде:
- chaos;
- malformed input;
- permission denied;
- network loss;
- disk full;
- corruption;
- stale queue;
- race;
- replay divergence;
- broken provenance;
- policy bypass attempt.

## Production-adversarial matrix
Каждая критичная подсистема должна иметь матрицу угроз минимум по следующим направлениям:

1. `Configuration failure`
- неверный конфиг;
- отсутствующий секрет;
- устаревший endpoint;
- сломанный feature-flag.

2. `Dependency failure`
- внешний инструмент не отвечает;
- зависимость меняет код возврата;
- upstream schema drift;
- package unmaintained/vulnerable.

3. `Transport failure`
- timeout;
- refused;
- partial delivery;
- backlog;
- stale queue;
- duplicate replay.

4. `Storage failure`
- disk full;
- corruption;
- partial write;
- lock contention;
- crash mid-write.

5. `Policy/security failure`
- обход RBAC;
- bypass redaction;
- неподписанный артефакт;
- неподтверждённый action;
- cross-tenant/cross-profile attempt.

6. `Operator / workflow failure`
- неверная ручная команда;
- release из неверного commit;
- сломанный rollout order;
- неверный severity assignment.

7. `UI/UX failure`
- локализация ломает рендер;
- tooltip/evidence-path пропадает;
- fallback path не включается;
- degraded mode не сохраняет управляемость.

## Что обязательно для закрытия чек-листа
Если этап влияет на runtime, security, release, platform, agent, DNA, evidence, action path или UI law, то для его честного закрытия требуется не только документ, но и:
- минимум один поведенческий тест;
- минимум один negative/adversarial сценарий;
- минимум один эксплуатационный артефакт;
- подтверждение, что исключены альтернативные причины.

## Обязательные признаки слабого теста
Тест считается недостаточным, если он:
- проверяет только наличие текста;
- проверяет только `exit 0` без анализа эффекта;
- не умеет ловить ложноположительный успех;
- не различает инфраструктурный сбой и содержательный finding;
- не даёт артефакт для разбора;
- не проверяет negative-path там, где он обязателен.

## Обязательные признаки сильного теста
Тест считается production-grade, если он:
- проверяет систему на реальном пути исполнения;
- отделяет infrastructure failure от expected finding;
- имеет positive и negative сценарий;
- даёт артефакт;
- встраивается в CI/release/process law;
- ловит возврат регрессии после изменения кода/политики/контракта.

## Что запрещено
- закрывать проблему по одному симптому;
- подменять эксплуатационный эффект документом;
- объявлять “fixed” без анализа альтернативных причин;
- идти к следующему пункту, если текущий fix не доведён до реального эффекта;
- считать формальный docs-gate эквивалентом runtime-proof.

## Minimum rollout rule
Если изменение затрагивает production path, оно не считается закрытым, пока не выполнены:
- локальное воспроизведение;
- CI/gate-подтверждение;
- анализ альтернативных причин;
- regression protection.
