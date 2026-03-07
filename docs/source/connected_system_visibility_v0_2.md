# Connected System Visibility v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/source/agent_deployment_transport_v0_2.md`
- `docs/agent/receiver_source_coverage.md`
- `docs/packs/source_coverage.md`
- `docs/source/checklists/CHECKLIST_18_ART_AGENT_RECEIVERS.md`
- `docs/source/checklists/CHECKLIST_19_PACKS_FRAMEWORK.md`
- `docs/source/checklists/CHECKLIST_20_PACK_REGART.md`
- `docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
- `docs/governance/observability_gap_registry.md`
- `formats/connected_system_visibility_v0_2.yaml`

Статус: ACTIVE
Последняя актуализация: 2026-03-07

## Назначение
Art не имеет права считать внешнюю систему "подключённой", если оператор не видит:
- что именно за система подключена;
- по какому механизму она подключена;
- какие типы данных она реально отдаёт;
- какие типы данных только заявлены, но ещё не наблюдались;
- есть ли у этой системы активные разрывы наблюдаемости или проблемы доставки.

Этот документ вводит обязательную проекцию `Connected System View`:
- для человека это наглядная карточка или строка системы;
- для runtime и тестов это детерминированный набор полей;
- для packs и receivers это обязательный contract declared-vs-observed truth.

Этот документ должен читаться легко и без скрытого контекста: оператор и новый инженер должны сразу понимать, что именно считается подключением, чем отличается "заявлено" от "наблюдается" и почему зелёный статус без evidence запрещён.

## Главный принцип
Успешное подключение не считается доказанным по одному факту "конфиг принят" или "pack установлен".

Система считается реально подключённой только если одновременно выполнено:
1. у неё есть устойчивая identity;
2. есть declared source coverage;
3. пришёл хотя бы один свежий observed signal в разрешённом окне свежести;
4. типы данных и механизмы получения видны оператору;
5. все активные gap-события этой системы тоже видны оператору.

## Что должен показать Art после подключения системы
После успешного подключения Art обязан показать оператору минимум:
- `system_id` — стабильный идентификатор системы;
- `display_name` — понятное человеку имя;
- `integration_kind` — тип интеграции;
- `pack_id` или `integration_profile_id`;
- `owner_component`;
- `site_id` и `segment_id`, если они известны;
- `connection_status`;
- `status_reason`;
- `first_seen_ts_ms`;
- `last_seen_ts_ms`;
- `freshness_threshold_ms`;
- `declared_data_kinds`;
- `observed_data_kinds`;
- `receiver_kinds`;
- `transport_paths`;
- `telemetry_endpoints`;
- `active_gap_events`;
- `evidence_refs`.

Если хотя бы часть этой информации отсутствует, Art обязан показать это явно, а не скрывать за зелёным статусом.

## Семантика состояний подключения
- `connected` — declared coverage есть, свежие observed signals есть, gap не блокирует доверие к факту подключения.
- `degraded` — система подключена, но есть активные gap-события, уменьшающие доверие к полноте картины.
- `declared_only` — интеграция/pack/конфиг известны, но свежих observed signals ещё нет.
- `disconnected` — ранее система была видна, но окно свежести вышло и новых signals нет.
- `unknown` — система фигурирует в конфигурации или документации, но runtime truth для неё не определён.

Зелёный статус допустим только для `connected`.

## Declared vs Observed
Art обязан различать два класса информации:

### Declared
То, что обещают:
- pack manifest;
- receiver configuration;
- integration profile;
- docs/source coverage;
- topology/deployment contract.

### Observed
То, что реально произошло:
- пришедшие RawEvent;
- receiver telemetry;
- snapshot/stream evidence;
- active gap events;
- correlation с runtime traces/incidents.

Если declared и observed расходятся, Art не имеет права молчать. Он обязан:
- показать расхождение оператору;
- породить gap-событие;
- дать runbook.

## Connected System View (обязательная модель)
Machine-readable canonical model задаётся в:
- `formats/connected_system_visibility_v0_2.yaml`

Обязательные поля:
- `system_id`
- `display_name`
- `integration_kind`
- `connection_status`
- `declared_data_kinds`
- `observed_data_kinds`
- `receiver_kinds`
- `telemetry_endpoints`
- `active_gap_events`
- `evidence_refs`

Допустимые дополнительные поля:
- `pack_id`
- `pack_version`
- `owner_component`
- `site_id`
- `segment_id`
- `regulatory_tags`
- `transport_paths`
- `first_seen_ts_ms`
- `last_seen_ts_ms`
- `freshness_threshold_ms`
- `status_reason`

## Источники для заполнения проекции
Connected System View строится из трёх слоёв:

1. `receiver_source_coverage`
- что агент умеет реально собирать;
- какими receiver kinds;
- какие data kinds они производят.

2. `pack source coverage`
- какие сервисы/системы pack описывает;
- какие data kinds и endpoints декларирует;
- как pack ожидает их видеть в Art.

3. `runtime observed signals`
- что реально пришло в Core;
- что отразилось в incidents/evidence/gap events.

## Обязательства Packs
Каждый pack, который интегрирует внешнюю систему, обязан нести:
- `service_inventory`
- `signal_coverage_claims`
- `telemetry_endpoints`
- `receiver_examples`
- `regulatory_tags`
- `connected_system_projection`

Эти поля не декоративны. Они обязаны быть пригодны для построения Connected System View.

## Обязательства Console
Console обязан иметь отдельную поверхность или встроенный блок, где Connected System View доступен без поиска по сырому логу.

Минимальный UX-контракт:
- видно, произошло подключение или нет;
- видно, какие типы данных заявлены;
- видно, какие типы данных реально приходят;
- видно, какие receiver kinds участвуют;
- видно, какие gap events активны;
- видно, на каком evidence это основано.

## Обязательные gap-события
- `observability_gap.connected_system_not_visible`
- `observability_gap.connected_system_coverage_drift`

Они регистрируются в:
- `docs/governance/observability_gap_registry.md`

Runbook:
- `docs/runbooks/connected_system_not_visible.md`

## Зачем это нужно проекту
Этот контур решает сразу несколько проблем:
- оператор сразу видит, интеграция реально жива или только "вроде настроена";
- pack и docs перестают быть декларативными и должны совпасть с runtime truth;
- легче понимать, какие данные реально поступают от внешней системы;
- легче ловить drift между обещанной и фактической интеграцией;
- уменьшается риск ложной уверенности "подключили и забыли".

## Что считается FAIL
Контур считается не реализованным, если выполняется хотя бы одно условие:
- система считается подключённой без observed signals;
- нет различия declared/observed data kinds;
- pack не даёт достаточной service inventory;
- Console не показывает оператору типы данных и connection status;
- gap-события для этой области отсутствуют;
- docs и machine-readable model расходятся.
