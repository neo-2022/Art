# Триаж buyer due diligence сигналов v0.2

## Source of truth
- `docs/testing/full_line_by_line_audit_program_v0_2.md`
- `docs/testing/full_line_by_line_audit_registry_v0_2.md`
- внешний входной сигнал: `/home/art/Рабочий стол/аудит`

## Цель
Перевести внешний аудит покупателя из формы мнений в рабочий инженерный артефакт:
- подтвердить только то, что воспроизводится локально;
- отделить устаревшие или недоказанные тезисы;
- использовать подтверждённые сигналы как вход в retro-audit и remediation-приоритизацию.

## Правило
В этот документ включаются только четыре класса сигналов:
- `CONFIRMED` — тезис подтверждён локально кодом, git-историей, файлами или runtime-поведением;
- `PARTIAL` — тезис подтверждён частично, но формулировка внешнего аудита сильнее факта;
- `STALE` — тезис был разумным, но уже не соответствует текущему состоянию ветки;
- `UNVERIFIED` — тезис пока не может быть доказан локально и не используется как основание для решений.

## Подтверждённые и полезные сигналы

| Сигнал покупателя | Локальная проверка | Статус | Наша польза | Checklist impact |
|---|---|---|---|---|
| Проект не выглядит фейком, но зрелость runtime ниже части заявленных claims | Подтверждено по расхождению между каноном, docs и runtime слоями в реестре построчного аудита | `CONFIRMED` | Полезно как честная формулировка статуса актива: сильный инженерный актив, но не доказанный production asset | 00, 24, 37, 38 |
| Core и Agent в inspected entrypoints выглядят in-memory относительно заявлений про SQLite/WAL/spool/outbox | Подтверждено по `core/src/main.rs` и `agent/src/main.rs`: `VecDeque/HashMap/RwLock`, отсутствие `sqlite/reqwest/relay/ack transport`, in-memory spool | `CONFIRMED` | Это один из главных корневых дефектов основания проекта; нельзя закрывать platform/prod/stage17/18/37 поверх него | 11, 12, 17, 18, 23, 37, 38 |
| Кодовая база чрезмерно монолитна в `core/src/main.rs` и `agent/src/main.rs` | Подтверждено размером и централизацией runtime логики в entrypoint-файлах | `CONFIRMED` | Повышает риск review, локальности изменений, security-аудита и bus factor; влияет на программу decomposition позже | 04, 11, 12, 17, 18, 29, 33, 37 |
| Канонический источник истины раздвоен между `main` и `prod/release-metadata-refresh` | Подтверждено: `git rev-list --left-right --count main...HEAD` = `0 96`; PR-ветка живёт на 96 коммитов вперёд main | `CONFIRMED` | Показывает buyer-risk по branch/source-of-truth drift; нужно держать это как отдельный governance и release риск | 01, 24, 38 |
| Bus factor высок: активность сконцентрирована у 1–2 авторов | Подтверждено `git shortlog -sne --all`: `Neo 177`, `art 39`, `2art260679-rgb 6` | `CONFIRMED` | Это не обвинение, а эксплуатационный риск владения и поддержки; нужен owner/delegation/decomposition контур | 01, 04, 39 |
| Stage06 strict cross-repo integration зависит от локального sibling checkout | Подтверждено в `scripts/ci/check_stage06_wrapper.sh`: strict mode требует `MY_LANGGRAPH_AGENT_DIR` или `../my_langgraph_agent` | `CONFIRMED` | Это прямой risk для buyer due diligence и для CI truthfulness: strict Art↔REGART parity ещё не self-contained | 05, 06, 20, 38 |
| Dev/test путь допускает локальный plain HTTP и тем самым отличается от строгого prod TLS контура | Подтверждено множеством `http://127.0.0.1:*` в runtime tests, runbooks, examples и source docs | `CONFIRMED` | Полезно как граница доверия: local HTTP нельзя путать с prod security truth; strict-TLS path должен проверяться отдельно | 04, 05, 06, 16, 20, 23, 37 |
| Платформенный/certified contour во многом является архитектурой проверки, а не полнотой evidence | Подтверждено нашими уже найденными разрывами: VM execute placeholder, validate-only surfaces, Docker/K8s smoke без integrated Agent→Core proof | `CONFIRMED` | Это подтверждает правильность reopening stage37 и запрет переоценивать certified/platform claims | 18, 23, 37, 38 |
| Governance/security/release верхние документы слишком тонкие для покупателя | Частично подтверждено: `SECURITY.md`, `RELEASE_CHECKLIST.md`, `docs/governance/release_process.md` и related docs реально тоньше зрелого product due diligence уровня | `PARTIAL` | Даёт нам прямой backlog на утолщение верхнего governance/release корпуса | 01, 04, 24, 37, 38 |
| IP-пакет пока не выглядит завершённым для сделки | Частично подтверждено: `LICENSE` есть, authenticity contour уже введён, но chain-of-title/contributor-rights/dependency-IP pack в repo не материализован | `PARTIAL` | Это полезный сигнал для отдельного legal/IP readiness контура, но не повод отрицать уже сделанный authenticity baseline | 04, 07, 25, 38 |
| Проект сегодня больше инженерный актив, чем traction-driven startup | Подтверждено косвенно по локальному состоянию репозитория и отсутствию признаков product-traction внутри repo | `CONFIRMED` | Полезно для buyer-позиционирования: продавать сильный инженерный актив, а не выдуманный traction | 07, 24 |

## Устаревшие или ослабленные тезисы внешнего аудита

| Тезис | Локальная проверка | Статус | Вывод |
|---|---|---|---|
| `README.md` концептуально устарел и описывает проект как раннюю заготовку | Текущее `README.md` уже обновлено и описывает `v0.2.0-rc.2`, production candidate, release/go-no-go/evidence corpus | `STALE` | Сигнал был полезен исторически, но в текущем состоянии ветки уже не подтверждается буквально |
| `docs/README.md` не знает о более поздних стадиях | Текущий `docs/README.md` уже пришит к foundation/history/ops/release/testing и не живёт на старой фазе `00..26` | `STALE` | Покупательский тезис больше не точен для текущей ветки |
| `license-checker` гарантированно падает без `npm ci` | Локально это не воспроизводится как guaranteed failure; реальная проблема тоньше: gate может давать слабый/неполный результат | `STALE` | Используем не дословно, а как урок про CI fragility |

## Неподтверждённые или требующие внешнего доступа тезисы

| Тезис | Статус | Почему пока не используем |
|---|---|---|
| GitHub Releases/Latest release несинхронны с release checklist | `UNVERIFIED` | Без внешнего API/страницы releases в текущем цикле у нас нет достаточного локального доказательства; используем только локально подтверждаемую веточную и tag-модель |
| Нет опубликованных GitHub security advisories | `UNVERIFIED` | Требует проверки внешнего GitHub security surface |

## Извлечённая польза для проекта
1. Внешний аудит подтвердил, что buyer сильнее всего бьёт не по красоте идеи, а по разрыву между claims и runtime.
2. Самые ценные сигналы покупателя совпали с нашим собственным retro-audit:
   - in-memory foundation в Core/Agent;
   - branch/source-of-truth split;
   - cross-repo strict dependency;
   - dev/prod transport split;
   - platform evidence < platform claims.
3. Это значит, что наш текущий курс правильный: нельзя просто закрывать чек-листы дальше, пока не переоткрыты и не усилены корневые основания.

## Дальнейшее использование
- Все `CONFIRMED/PARTIAL` сигналы должны быть отражены в `docs/testing/full_line_by_line_audit_registry_v0_2.md`.
- `CONFIRMED` сигналы уровня runtime/source-of-truth должны использоваться как основание для reopening stages.
- `STALE` и `UNVERIFIED` сигналы не используются как основание для решений, но сохраняются как исторический контекст due diligence.
