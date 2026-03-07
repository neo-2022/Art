# Дефектовочная ведомость и лестница remediation v0.2

## Source of truth
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- `formats/root_decision_tree_dependencies.yaml`
- `docs/testing/full_line_by_line_audit_program_v0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/stage_reopening_matrix_v0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Назначение
Этот документ переводит завершённый полный аудит в управляемую программу исправления.

Он нужен, чтобы работа шла не по инерции и не по привычке "снова закрывать листы сверху вниз", а по дереву решений:
- корневые документы проекта определяют замысел и законы;
- аудит показывает, где проект от них отклонился;
- дефектовочная ведомость превращает эти отклонения в строгую лестницу remediation;
- `MASTER` выполняется уже не как линейный список пожеланий, а как исполнительный слой этой лестницы.

## Дерево решений проекта

### Уровень 0 — Корень
Корень дерева — не чек-листы, а канон проекта:
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`

Именно эти документы отвечают на вопрос:
- что такое Art;
- каким он должен быть;
- какие differentiators уже утверждены;
- какие законы нельзя нарушать.

Их изменение не имеет права жить отдельно от зависимых документов:
- карта зависимостей задаётся в `formats/root_decision_tree_dependencies.yaml`;
- синхронность контролируется CI-gate `scripts/ci/check_root_decision_tree_sync.sh`.

### Уровень 1 — Ствол, часть 1: Полный аудит
Аудит не исправляет проект, а определяет:
- где проект отклонился от корня;
- где дефект поверхностный, а где корневой;
- какие стадии должны быть reopened;
- какой слой нельзя чинить, пока не исправлен нижележащий.

Артефакты этого уровня:
- `docs/testing/full_line_by_line_audit_program_v0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- `docs/testing/stage_reopening_matrix_v0_2.md`

### Уровень 2 — Ствол, часть 2: Дефектовочная ведомость
Этот документ — первая несущая часть ствола дерева. Он переводит аудит в линейную corrective-программу.

Он отвечает на вопрос:
- в каком порядке реально чинить проект;
- какие стадии блокируют другие;
- где корневой дефект, а где симптом.

### Уровень 3 — Ствол, часть 3: MASTER
`MASTER` является второй несущей частью ствола, завершает ствол дерева и служит последней управляющей точкой перед кроной.

После завершения audit coverage он обязан опираться на эту дефектовочную ведомость:
- если корневой дефект находится ниже по лестнице, `MASTER` не может вести работу в обход него;
- если стадия reopened по аудиту, её нельзя закрывать до прохождения нижнего уровня;
- если корневой уровень не исправлен, верхний этап считается запрещённым к повторному закрытию.

### Уровень 4 — Крона: Stage checklist execution
Остальные чек-листы, contracts, runbooks, ops/security/privacy/docs слои образуют крону дерева.

Но теперь они работают так:
- stage берётся из `MASTER`;
- `MASTER` берёт corrective-порядок из этой ведомости;
- эта ведомость берёт порядок из аудита и канона проекта.

Итоговая цепочка:

`Корень (канон) -> Ствол (аудит -> дефектовочная ведомость -> MASTER) -> Крона (stage checklists -> код/тесты/документы/runtime)`

## Законы лестницы remediation

### Закон 1 — Никаких прыжков через уровень
Если дефект найден на верхнем уровне, работа идёт вниз до корневой причины.

Запрещено:
- чинить симптом и считать проблему закрытой;
- возвращаться к верхнему этапу, если нижележащий слой всё ещё слаб;
- закрывать пункт checklist, если его basement ещё не исправлен.

### Закон 2 — Один активный уровень
В каждый момент времени активен только один уровень лестницы remediation.

Разрешено усиливать соседние документы/скрипты только в объёме, который нужен текущему активному уровню.

### Закон 3 — Внутри уровня порядок тоже линейный
Если уровень содержит несколько стадий, они выполняются в указанном ниже порядке.

Нельзя:
- перепрыгивать на "интересную" стадию выше;
- брать stage, которая зависит от ещё не исправленного basement.

### Закон 4 — Закрытие идёт снизу вверх
Повторное закрытие возможно только так:
1. исправлен самый нижний корневой дефект;
2. эксплуатационный эффект подтверждён разносторонним дебаггингом;
3. только потом разрешено подниматься уровнем выше.

## Лестница remediation

### Уровень A — Runtime basement
Это нижний несущий слой проекта. Пока он слаб, всё выше — недостоверно.

Порядок исполнения:
1. `11` Storage / vacuum / systemd basement
2. `17` Agent spool durability
3. `18` Agent receivers / transport / relay / TLS
4. `19` Packs runtime framework
5. `20` REGART pack runtime truth
6. `37` Linux / VM / platform runtime truth

Почему этот уровень первый:
- здесь лежат реальные durable storage/transport/runtime claims;
- здесь уже доказаны broken или placeholder-backed paths;
- любые верхние доказательства сейчас опираются на этот слой.

Что считается успехом уровня:
- broken runtime paths устранены;
- placeholder-backed execute paths исчезли;
- runtime storage/transport/platform доказаны эксплуатационно;
- верхние stages перестают зависеть от ложного basement.

### Уровень B — Policy and consistency basement
После укрепления runtime basement исправляется нормативная и policy-согласованность.

Порядок исполнения:
1. `01` Governance/SRE
2. `02` Privacy baseline
3. `03` Regional profiles
4. `25` Compliance / audit ready
5. `26` RU profile

Почему уровень идёт вторым:
- policy нельзя честно закрыть, пока runtime-path либо отсутствует, либо врёт;
- после исправления нижнего слоя здесь устраняются противоречия документов, retention drift, compliance evidence gaps.

Что считается успехом уровня:
- policy corpus внутренне непротиворечив;
- privacy/compliance/runtime больше не конфликтуют;
- ранние governance/privacy/compliance stages перестают быть формальными.

### Уровень C — Interface and UX/runtime truth
Здесь исправляются claims про browser, Panel0, Console, i18n и spatial/UI basement.

Порядок исполнения:
1. `10` Browser Level0
2. `16` Panel0
3. `28` Console foundation
4. `35` Spatial / 3D readiness

Почему этот уровень идёт после basement:
- UI claims бесполезно закрывать, если storage/agent/platform ещё лгут;
- bilingual, fallback, visual truth и local-stores нужно чинить уже на честном runtime слое.

Что считается успехом уровня:
- bilingual parity доказана;
- browser/Panel0/Console/fallback не содержат ложных claims;
- spatial/local-stores/worker-runtime больше не опираются на stub basement.

### Уровень D — Contracts, SDLC, release and CI truth
На этом уровне восстанавливается доверие к contracts/release/CI-process.

Порядок исполнения:
1. `04` Secure SDLC + supply-chain
2. `07` Repo CI/docs
3. `08` Contracts/OpenAPI/codegen
4. `24` Release / upgrade / regression
5. `38` Stage ladder enforcement

Почему это не первый уровень:
- пока runtime basement врёт, security/release/CI могут быть зелёными на ложном основании;
- после исправления нижних уровней можно честно ужесточать gates и release truth.

Что считается успехом уровня:
- gates доказывают behaviour, а не только structure;
- release/provenance/CI не дают false-green;
- stage order снова становится честным.

### Уровень E — Product differentiators and advanced tracks
Это верхний уровень, где materialize утверждённые differentiators.

Порядок исполнения:
1. `29`
2. `30`
3. `31`
4. `32`
5. `33`
6. `34`
7. `36`
8. `39`
9. `40`
10. `41`
11. `42`
12. `43`
13. `44`
14. `45`

Почему этот уровень последний:
- differentiators нельзя честно закрывать на слабом basement;
- исторический корпус уже утверждён, но его реализация должна опираться на исправленное основание.

Что считается успехом уровня:
- historical differentiators больше не висят только в foundation;
- их contracts/runtime/tests/evidence materialized;
- проект перестаёт расходиться между замыслом и кодом.

## Запрещённые маршруты
Запрещено:
- переходить к уровню `B`, если не закрыт уровень `A`;
- переходить к уровню `C`, если policy consistency ещё не исправлена;
- закрывать `29..45`, пока нижние уровни ещё reopened;
- закрывать `MASTER` по стадиям просто по номеру, игнорируя эту лестницу.

## Текущая активная точка входа
Текущая правильная стартовая точка remediation:
- уровень `A`
- stage `11`

После его реального исправления и доказанного эксплуатационного эффекта:
- stage `17`
- затем `18`
- затем `19`
- затем `20`
- затем `37`

Только после этого разрешён переход к уровню `B`.

## Что делать после каждого уровня
После завершения каждого уровня обязательно:
1. обновить эту ведомость;
2. обновить `stage_reopening_matrix_v0_2.md`, если статус стадий изменился;
3. обновить `MASTER`, если разрешён переход на следующий уровень;
4. только потом начинать remediation следующего уровня.

## Статус
- Статус ведомости: `ACTIVE`
- Статус программы: `REMEDIATION_ORDER_FIXED`
- Первый разрешённый corrective step: `Stage 11`
