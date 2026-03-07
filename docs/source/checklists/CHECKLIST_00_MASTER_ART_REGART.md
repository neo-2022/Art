A) Полный запрет опциональности:
# CHECKLIST 00 — MASTER (Art v1 + REGART) + STANDARD (единые правила)
Файл: CHECKLIST_00_MASTER_ART_REGART.md  
Последняя актуализация: 2026-03-06  
Дата последней проверки: 2026-03-06 (усиление программы v0.2: stages 28..45 + ladder enforcement)  
Триггер пересмотра: любые изменения в Art_v1_spec_final.md / FOUNDATION_CONSTITUTION_V0_2.md / REGART↔Art описание / CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md / CHECKLIST_06_REGART_ART_BRIDGE.md / внешние источники в my_langgraph_agent
Отчёт аудита: docs/source/checklists/CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md

Источники требований:
- Art: `docs/source/Art_v1_spec_final.md`
- REGART ↔ Art: `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- Дефектовочная ведомость remediation: `docs/testing/defect_remediation_ladder_v0_2.md`
- Дефектовочная контрольная ведомость remediation: `docs/testing/defect_remediation_control_matrix_v0_2.md`
- Machine-readable дефектовочная контрольная ведомость: `formats/defect_remediation_control_matrix_v0_2.yaml`
- Корневая карта зависимостей: `formats/root_decision_tree_dependencies.yaml`
- Дерево документации и документный контроль дрейфа: `docs/portal/DOCUMENTATION_TREE.md`, `formats/documentation_tree_v0_2.yaml`
- Исторический корпус и встроенный Threat Model Appendix: `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- REGART UI/Debugger wrapper (в Art): `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- REGART Bridge wrapper (в Art): `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- REGART UI/Debugger source-of-truth (внешний репозиторий): `my_langgraph_agent/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`  
  GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
- REGART Bridge source-of-truth (внешний репозиторий): `my_langgraph_agent/CHECKLIST_REGART_ART_INTEGRATION.md`  
  GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`
- Risk register v0.2: `docs/source/risk_register_v0_2.md`
- Ingress / perimeter protection baseline: `docs/source/ingress_perimeter_protection_v0_2.md`
- Trust boundary / canonical actor context baseline: `docs/source/trust_boundary_hardening_v0_2.md`
- Browser surface hardening baseline: `docs/source/browser_surface_hardening_v0_2.md`
- Connected system visibility baseline: `docs/source/connected_system_visibility_v0_2.md`
- Protective safeguards catalog baseline: `docs/source/protective_safeguards_catalog_v0_2.md`
- Storage pressure protection baseline: `docs/source/storage_pressure_protection_v0_2.md`
- Startup config fail-closed baseline: `docs/source/startup_config_safety_validator_v0_2.md`
- Queue integrity / anti-loop baseline: `docs/source/queue_integrity_protection_v0_2.md`
- Guard self-observability baseline: `docs/source/guard_self_observability_v0_2.md`
- Action execution safety guard baseline: `docs/source/action_execution_safety_guard_v0_2.md`
- Agent identity / enrollment trust baseline: `docs/source/agent_identity_enrollment_trust_v0_2.md`
- Release truth enforcement baseline: `docs/source/release_truth_enforcement_v0_2.md`
- Authenticity baseline: `docs/source/authenticity_baseline_v0_2.md`
- Regulatory claims drift control baseline: `docs/source/regulatory_claims_drift_control_v0_2.md`
- Monolith budget guard baseline: `docs/source/monolith_budget_guard_v0_2.md`
- Machine-readable monolith budget: `formats/monolith_budget_guard_v0_2.yaml`
- Monolith budget CI guard: `scripts/ci/check_monolith_budget_guard.sh`
- Test strength guard baseline: `docs/source/test_strength_guard_v0_2.md`
- Documentation drift control baseline: `docs/source/documentation_drift_control_v0_2.md`
- Machine-readable protective safeguards catalog: `formats/protective_safeguards_catalog_v0_2.yaml`
- Pinned external adversarial harness baseline: `docs/source/regart_adversarial_integration_harness_v0_2.md`

⚠️ ПРАВИЛО: переход к следующему этапу возможен только после полного закрытия предыдущего.  
⚠️ ПРАВИЛО: запрещено удалять пункты из чек-листов без согласования с владельцем проекта.  
⚠️ ПРАВИЛО: отметка [x] ставится ТОЛЬКО после реальной проверки (команда/тест/сценарий) и фиксации результата (дата+commit/PR).  
⚠️ ПРАВИЛО: запрещены “временные решения” в репозитории — только финальные реализации (временное — только локально и сразу удалить).  
⚠️ ПРАВИЛО: полный запрет опциональности — запрещены формулировки “опционально/где применимо/если нужно/решение зафиксировано/либо A либо B”.
⚠️ ПРАВИЛО: запрещено создавать и хранить копии чек-листов (`*.bak`, `*_copy*`, `*_old*` и аналоги). Разрешён только один актуальный файл каждого чек-листа.
⚠️ ПРАВИЛО: всегда держать в контексте файл `/home/art/my_langgraph_agent/AGENTS.md`; для Codex он считается системным промтом проекта.
⚠️ ПРАВИЛО: после завершения audit coverage порядок remediation задаётся `docs/testing/defect_remediation_ladder_v0_2.md`, а не “следующим номером этапа”.
⚠️ ПРАВИЛО: если меняется документ из корня, ствола или обзорного контура, `DOCUMENTATION_TREE.md` и `formats/documentation_tree_v0_2.yaml` обязаны быть синхронизированы в том же изменении.
⚠️ ПРАВИЛО: partner-exposed и REGART integration proof считаются валидными только через pinned external adversarial harness; floating checkout и непомеченный внешний source запрещены.
⚠️ ПРАВИЛО: Threat Model живёт внутри исторического корневого документа, а не в отдельном висящем security-файле; materialized/planned/missing статусы обязаны оставаться честными.

---

## A) STANDARD: обязательный стандарт чек-листов

### A1) Обязательная структура каждого CHECKLIST_XX_*.md
Каждый чек-лист обязан содержать разделы строго в таком порядке:
1) Цель  
2) Границы  
3) Зависимости  
4) Шаги (строго линейно) — каждый шаг содержит: “Сделать” + “Проверка (pass/fail)”  
5) Документация (RU)  
6) Тестирование (unit/integration/e2e/chaos/load/soak)  
7) CI gate  
8) DoD  
9) Метаданные: “Последняя актуализация” + “Дата последней проверки” + “Триггер пересмотра”

### A2) Правила отметок
- [ ] — не сделано  
- [ ] — сделано только после проверки  
- Если пункт не выполнен: добавляется подпункт “причина → фикс → критерий готовности”.

### A3) Никакой двусмысленности
Запрещены: “опционально”, “если нужно”, “где применимо”, “по возможности”, “или/либо”, “утвердить”, “решение зафиксировать”.  
Разрешено только: “сделать X”, “проверить Y”, “pass/fail критерий”.

### A4) Обязательные артефакты закрытия этапа
- RU-документация обновлена (пути перечислены в чек-листе)
- тесты/проверки выполнены
- CI gate зелёный
- запись в MASTER таблице: дата + подпись + commit/PR

### A5) ОБЯЗАТЕЛЬНО: observability_gap.* при сбоях
Каждый чек-лист обязан содержать проверки, что при недоступности источника/канала/подсистемы генерируется соответствующее `observability_gap.*` событие.
Минимум для каждого компонента:
- “что сломалось” (what)
- “где сломалось” (where)
- “почему/класс ошибки” (why)
- evidence (минимум: ошибка/код/контекст/счётчики)
- actions (что сделать: ссылка на runbook / action execute)

### A6) ОБЯЗАТЕЛЬНО: chaos-тесты для критичных этапов хранения/доставки
Для этапов 11 (Storage), 12 (Ingest), 17 (Agent Spool), 18 (Agent Receivers) обязательны chaos-тесты:
- kill -9 процесса в критической точке
- потеря сети
- disk pressure/disk full
- corruption (SQLite/WAL/spool)

### A7) Пересмотр при изменении спецификаций
Любое изменение в источниках требований требует:
- обновить затронутые чек-листы
- обновить “Последняя актуализация”
- выполнить повторную проверку и заполнить “Дата последней проверки”.

### A8) Обязательный контроль release-blockers
- Для программы 28..38 обязательна проверка `docs/source/risk_register_v0_2.md`.
- Если активен release blocker из risk register, продвижение этапа запрещено.

### A9) Протокол прохождения чек-листов (обязательный, без исключений)
1) Начинать только с `CHECKLIST_00_MASTER_ART_REGART.md`.
2) Выбирать первый этап со статусом `[ ]`.
3) Открывать соответствующий чек-лист и идти строго сверху вниз.
4) Каждый пункт закрывается только после закрытия всех его подпунктов.
5) Подпункты закрываются по одному, сразу после фактического выполнения.
6) Родительский пункт нельзя отмечать `[x]`, пока в нём есть хотя бы один `[ ]` подпункт.
7) Если в подпункте указана проверка, она выполняется ровно в указанном виде; `[x]` только после PASS.
8) Если в подпункте указан артефакт, `[x]` ставится только после подтверждения существования артефакта.
9) Переход к следующему пункту разрешён только после полного закрытия текущего пункта.
10) Переход к следующему этапу разрешён только после полного закрытия текущего чек-листа.
11) После завершения этапа исполнитель делает короткий отчёт: “сделано/не сделано”.
12) Для продолжения работ всегда возвращаться в MASTER и брать следующий этап по порядку.

### A10) Финальный чекбокс MASTER = только Production GO
Финальный чекбокс MASTER имеет право быть отмечен `[x]` только в одном случае: проект реально готов к production release и может быть передан в прод без оговорки “candidate”, “почти готово”, “доделаем после релиза” или “готово по документам”.

Обязательные условия финального `[x]` в MASTER:
- все обязательные этапы программы закрыты реальными PASS-проверками и артефактами;
- нет активных release-blocker рисков в `docs/source/risk_register_v0_2.md`;
- все обязательные CI/docs/runtime/security/platform gates зелёные;
- существует реальное production `GO/NO-GO` решение со статусом `GO`, а не `staging GO`;
- сформированы release artifacts, release metadata и rollback plan;
- нет незакрытых критичных placeholder/stub/temporary implementation в обязательных контурах;
- состояние проекта соответствует критерию “можно выпускать в production сейчас”.

Запрещено ставить финальный `[x]` в MASTER, если:
- завершена только документация;
- завершена только текущая подпрограмма этапов;
- продукт находится в состоянии `release candidate`;
- существуют утверждённые обязательные continuation-этапы, которые включены в MASTER, но не завершены.

### A11) Сквозное внедрение утверждённых differentiators с ранних этапов
Утверждённые концепции из:
- `docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`
- `docs/foundation/revolutionary_hypotheses.md`
- `docs/foundation/frontier_tech_radar.md`
- `docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`
- `docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`
- `docs/portal/ART_VISUAL_LANGUAGE.md`

не имеют права “впервые появляться” только в этапах `39..45`.

Обязательное правило программы:
- ранние этапы `01..38` обязаны уже учитывать эти идеи как архитектурные ограничения, контракты, UX-законы, perf/security/privacy ограничения и тестовые требования там, где они влияют на соответствующую подсистему;
- этапы `39..45` являются не “первым появлением идеи”, а контуром её финализации, отдельного hardening, специальных gate’ов и production-grade проверки;
- если при прохождении этапа `01..38` новая approved-концепция влияет на его предметную область, чек-лист должен быть расширен до закрытия этапа;
- запрещено откладывать интеграцию approved-концепции “на потом”, если это создаёт риск позднего встраивания, архитектурного разрыва или production-регрессии.

Критерий готовности этого правила:
- для каждой approved-концепции существует ранний integration path в `01..38`;
- в `39..45` остаётся только специализированное доведение, а не первое проектное появление сущности.

### A12) Production-Adversarial Validation (обязательный закон всей программы)
Для всего проекта, а не только для отдельных CI или runtime проблем, действует правило:
- любое изменение считается завершённым только после доказанного эксплуатационного эффекта;
- доказанный эффект обязан быть подтверждён разносторонним дебаггингом, а не одним удачным симптомом.

Обязательный минимум для закрытия критичного изменения:
1. подтверждён основной ожидаемый эффект;
2. проверены альтернативные причины проблемы;
3. проверен negative-path или hostile scenario;
4. подтверждено, что дефект не был просто перенесён в другой слой;
5. добавлен regression guard.

Запрещено:
- считать grep/file-presence эквивалентом runtime proof;
- считать один зелёный check доказательством устранения проблемы;
- переходить к следующему шагу, если утверждённый текущий шаг не доведён до реального operational результата.

Источники детализации:
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/test_system_audit_v0_2.md`

### A13) Multi-layer Root-Cause Descent (обязательный закон всей программы)
Для всей программы действует правило: проект рассматривается как многоуровневая система, поэтому дефект на одном уровне не имеет права устраняться как изолированный симптом.

Обязательное исполнение:
1. если дефект найден на верхнем уровне, выполняется спуск на уровень ниже;
2. на нижнем уровне проводится полный аудит связанного основания;
3. если дефект найден ещё ниже, спуск продолжается до корня;
4. remediation-order строится от корневой причины вверх;
5. пункт чек-листа не закрывается, пока не доказано, что корень проблемы устранён и верхние уровни перепроверены.

Запрещено:
- чинить только внешнее проявление;
- считать зелёный верхний симптом доказательством исправления;
- переходить к следующему шагу без аудита более глубокого слоя, если есть основания считать его источником дефекта.

Источники детализации:
- `docs/testing/production_adversarial_validation_law.md`
- `docs/testing/full_line_by_line_audit_program_v0_2.md`

### A14) Authenticity / Copyright-Safe Baseline (обязательный закон всей программы)
Для всей программы действует правило юридической и артефактной аутентичности:
- в baseline проекта запрещено включать сущности, которые могут привести к претензиям правообладателей;
- по умолчанию запрещены сторонние audio assets, fonts, icons, logos, screenshots, datasets, demo-media и фрагменты контента с неясным происхождением;
- разрешены только project-owned, generated, synthetic или явно allowlisted материалы;
- user-supplied content не становится частью baseline проекта и не коммитится в репозиторий.

Обязательное исполнение:
1. все tracked binary/media/font/icon assets проверяются against machine-readable allowlist;
2. runtime и showcase слой не имеют права ссылаться на внешние CDN/brand/media assets;
3. packs, fixtures и evidence разделяются по происхождению и правовому основанию;
4. любой выявленный asset provenance gap блокирует закрытие затронутого этапа.

Источники детализации:
- `docs/governance/authenticity_copyright_policy.md`
- `formats/authenticity_assets_allowlist.yaml`
- `scripts/ci/check_authenticity_assets.sh`

### A15) Дерево решений remediation
После завершения полного построчного audit coverage дальнейшая работа строится только по такому дереву:
- корневые документы проекта;
- ствол:
  - полный аудит;
  - дефектовочная ведомость;
  - `MASTER`;
- крона:
  - stage checklist;
  - код / тесты / runtime / evidence.

Это означает:
- `MASTER` завершает ствол и является последней управляющей точкой перед кроной;
- remediation-order для `MASTER` задаётся предыдущим слоем ствола, то есть `docs/testing/defect_remediation_ladder_v0_2.md`;
- если номер следующего stage в таблице не совпадает с активным уровнем дефектовочной лестницы, приоритет имеет дефектовочная лестница;
- если хотя бы одна строка дефекта в `docs/testing/defect_remediation_control_matrix_v0_2.md` ссылается на stage, этот stage запрещён к повторному закрытию, пока строка дефекта остаётся `[ ]`;
- повторное закрытие reopened stages запрещено, пока дефектовочная лестница не разрешает переход на этот уровень.
- protective safeguards catalog (`docs/source/protective_safeguards_catalog_v0_2.md`) является обязательным входом ствола: stage closure запрещено, если новый защитный контур не попал в каталог, risk register, observability gap registry и defect control matrix.

### A16) Автоматическая синхронизация корневых документов
Корневые документы проекта заданы в `formats/root_decision_tree_dependencies.yaml`.

Обязательное правило:
1. изменение любого корневого документа требует синхронного обновления зависимых файлов в том же изменении;
2. зависимые файлы определяются machine-readable картой, а не “по памяти”;
3. CI-gate `scripts/ci/check_root_decision_tree_sync.sh` блокирует merge при рассинхроне;
4. cosmetic touch без реального обновления зависимого документа не считается допустимой синхронизацией.

Этот закон нужен, чтобы:
- `MASTER` не устаревал относительно канона;
- дефектовочная ведомость не расходилась с корнем дерева;
- архитектурные и интеграционные обзоры не жили отдельной жизнью.

### A17) Дерево документации как обзорный защитный слой
`docs/portal/DOCUMENTATION_TREE.md` является обзорным графическим артефактом, который строится
от единственного корня `README.md` и показывает:
- документные зависимости;
- суммарное число документов в дереве;
- суммарное число строк по дереву;
- число строк у каждого документа;
- каталоговые узлы и суммарные строки внутри них;
- документы, которые влияют на корневой `README.md`.

Этот артефакт не управляет `MASTER` напрямую, но обязателен как защитный механизм:
- он помогает быстро увидеть дрейф документации;
- он показывает, где изменение одного документа может потянуть корректировку других;
- он не позволяет скрыть корневое изменение внутри локальной правки одной страницы.

---

## B) MASTER: этапы проекта (строго по порядку)

> После завершения audit coverage порядок corrective execution определяется документом `docs/testing/defect_remediation_ladder_v0_2.md`.

> “Выполнено”: `YYYY-MM-DD, подпись/ник, commit/PR`

| № | Файл | Этап | Кратко | Выполнено |
|---:|---|---|---|---|
| [ ] 01 | CHECKLIST_01_GOVERNANCE_SRE.md | Governance/SRE | incident/postmortem/change mgmt + gap escalation + SLO | reopened 2026-03-07, full audit: governance/runbook/release/audit/tabletop contour weaker than hostile standard |
| [ ] 02 | CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md | Privacy baseline | PII surface + redaction_applied + attachments PII retention | reopened 2026-03-07, full audit: missing `config/privacy/redaction_rules.yaml` + retention drift |
| [ ] 03 | CHECKLIST_03_REGIONAL_PROFILES.md | Региональные профили | profile switch + airgapped packs update | reopened 2026-03-07, full audit: Stage03↔Stage02 retention/linkage drift not caught by gate |
| [ ] 04 | CHECKLIST_04 _Secure SDLC + Supply-chain.md | Secure SDLC | clean builds + branch policy + signed commits + sigstore/cosign | reopened 2026-03-06, audit: signing/allowlist placeholders remain |
| [ ] 05 | CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md | REGART UI/Debugger | wrapper → external source-of-truth `my_langgraph_agent/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` | 2026-03-05, neo-2022, PR#4 approved + stage05-wrapper-gate |
| [ ] 06 | CHECKLIST_06_REGART_ART_BRIDGE.md | REGART→Art bridge | wrapper → external source-of-truth `my_langgraph_agent/CHECKLIST_REGART_ART_INTEGRATION.md` | 2026-03-05, neo-2022, stage06 wrapper+ci gate |
| [ ] 07 | CHECKLIST_07_ART_REPO_CI_DOCS.md | Art repo WP0 | CI включает gitleaks + licenses + RU dev docs | 2026-03-05, neo-2022, stage07 ci+docs+gate |
| [ ] 08 | CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md | Contracts | schema registry + spec compliance + unknown-fields tests | 2026-03-05, neo-2022, PR#6 + ci:22716780559 |
| [ ] 09 | CHECKLIST_09_TELEMETRY_OTEL_OTLP.md | Telemetry | unknown attrs→payload.otel_attributes + severity tests + OTLP rate-limit | 2026-03-05, neo-2022, PR#8 + ci:22717440634 |
| [ ] 10 | CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md | Browser Level0 | CORS gap + gzip>1KB + TTL 7d→DLQ + worker+fallback | 2026-03-05, neo-2022, stage10 runtime+tests+docs-gate |
| [x] 11 | CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md | Core Storage | WAL corruption recovery + concurrency + VACUUM timer weekly | 2026-03-07, neo-2022, stage11 runtime+tests+docs-gate+vacuum proof |
| [ ] 12 | CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md | Core Ingest | invalid_details + overload 503 + ingest_dropped_total | 2026-03-05, neo-2022, stage12 runtime+tests+docs-gate |
| [ ] 13 | CHECKLIST_13_ART_CORE_PIPELINE_ENRICH_RULES.md | Pipeline | correlation→Incident + collision + template injection security | 2026-03-05, neo-2022, stage13 runtime+tests+docs-gate |
| [ ] 14 | CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md | Stream/Snapshot | Last-Event-ID too old→snapshot + 10k events + 1000 subs + gzip | 2026-03-05, neo-2022, stream-integration+stream-load-smoke+stage14-docs-gate (local recheck) |
| [ ] 15 | CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md | Actions/Audit/RBAC/PII | client_ip/user_agent + access_denied event + immutability | 2026-03-05, neo-2022, actions-audit-tests+stage15-docs-gate (local recheck) |
| [ ] 16 | CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md | Panel0 | embedded `/panel0/*` + `/` auto-fallback 5s + console_boot_failed backlog | 2026-03-06, neo-2022, panel0-e2e+stage16-docs-gate(docs+runtime)+panel0-linux-readiness |
| [ ] 17 | CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md | Agent Spool | block receivers on full + spool_corrupted recovery + concurrency + chaos | 2026-03-05, neo-2022, agent-spool-tests+agent-spool-chaos-smoke+stage17-docs-gate |
| [ ] 18 | CHECKLIST_18_ART_AGENT_RECEIVERS.md | Agent Receivers | per-receiver buffer policy+gap + SIGHUP tests + journald perms gap | 2026-03-05, neo-2022, agent-receivers-tests+stage18-docs-gate |
| [ ] 19 | CHECKLIST_19_PACKS_FRAMEWORK.md | Packs | manual updates only + cosign signature verify + dependencies | reopened 2026-03-06, audit: pack runtime layout still contains payload placeholder |
| [ ] 20 | CHECKLIST_20_PACK_REGART.md | Pack REGART | fixtures всех событий + correlation + receivers.toml examples | reopened 2026-03-06, audit: pack payload layout still placeholder-backed |
| [ ] 21 | CHECKLIST_21_SELF_OBSERVABILITY_ART.md | Self-obs | required internal incidents + grafana/ + alert tests | 2026-03-05, neo-2022, self-obs-tests+stage21-docs-gate |
| [ ] 22 | CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md | E2E/Chaos/Soak | 50% packet loss + memory profiling + power loss + nightly chaos | 2026-03-05, neo-2022, e2e-smoke+e2e-chaos+stage22-docs-gate |
| [ ] 23 | CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md | Ops/DR | cert-manager + systemd TLS reload SIGHUP + DB migration runbook + WAL backups | 2026-03-07, neo-2022, real backup/restore DR runtime proof on `CORE_DB_PATH` + ops-smoke/ops-docs-gate on PR; stage remains open for TLS hot-reload and `tls_config_invalid` backlog path |
| [ ] 24 | CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md | Release | downgrade with data + cosign sign images + RELEASE_CHECKLIST + manual releases | 2026-03-05, neo-2022, release-regression+release-signing-verify+stage24-docs-gate |
| [ ] 25 | CHECKLIST_25_COMPLIANCE_AUDIT_READY.md | Compliance | export scripts + immutable evidence + data destruction policy | 2026-03-05, neo-2022, compliance-export+stage25-docs-gate |
| [ ] 26 | CHECKLIST_26_RU_PROFILE.md | RU profile | PDn fields list + PII access audit + block cross-border export | reopened 2026-03-06, audit: air-gapped signing path still depends on placeholder key material |
| [ ] 27 | CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md | Audit/remediation | сводный аудит соответствия и закрытие найденных рисков | 2026-03-05, neo-2022, checklist27 remediation closed |
| [ ] 28 | CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md | Console foundation | monorepo apps+packages, workspace boundaries, console shell surfaces | 2026-03-06, neo-2022, stage28-docs-gate+stage28-lens-gate+stage28-audio-settings-e2e+workspace-boundary(-negative) PASS |
| [ ] 29 | CHECKLIST_29_EVENT_DNA_CORE_V2.md | Event DNA Core v2 | deterministic DNA core: formal model + property 1M + reference parity + `/api/v2/*` | 2026-03-06, neo-2022, stage29-dna-assurance-gate+stage29-dna-tests+stage29-dna-property-million+stage29-contract-fingerprint+stage29-nightly-replay-determinism+stage28-docs-gate PASS |
| [ ] 30 | CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md | Evidence/Claims/Dialogic | evidence blocks, claim lifecycle, dialog schemas, UI law checks | 2026-03-06, neo-2022, stage30-evidence-claims-tests+stage30-truth-modes-tests+console-test+stage30_dod_validation_artifact PASS |
| [ ] 31 | CHECKLIST_31_INVESTIGATIONS_AS_CODE.md | Investigations-as-Code | versioned InvestigationDoc, fork/replay/compare | 2026-03-06, neo-2022, stage31-investigation-doc-tests+stage31-investigation-library-tests+local-stores integration/e2e artifacts PASS |
| [ ] 32 | CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md | Audit+Merkle | crypto verify flow and proof attachment | 2026-03-06, neo-2022, stage32-audit-merkle-tests+stage32-audit-ux-anti-breakage+stage32 artifacts PASS |
| [ ] 33 | CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md | Secure Actions v2 | preflight/policy gates, no silent actions | 2026-03-06, neo-2022, stage33-secure-actions-tests+stage33-action-ux-anti-breakage+NRAC/simulation artifacts PASS |
| [ ] 34 | CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md | Perf/Load/Coverage | DNA perf budgets 10k/100k + overload 2x/3x + ratchet 5% + coverage ratchet | 2026-03-06, neo-2022, stage34-perf-load-tests+coverage-ratchet-gate+stage35-flow-perf-2d-gate+replay-regression+innovation-kpi-gate PASS |
| [ ] 35 | CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md | Spatial/3D readiness | spatial store contracts, picking/visibility invariants | reopened 2026-03-06, audit: spatial store still contains stubbed runtime path |
| [ ] 36 | CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md | SaaS readiness | tenant/control-data-plane architecture contracts | reopened 2026-03-06, ladder hold after stage35 audit reopening |
| [ ] 37 | CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md | Linux hardening | canary/rollback + OS matrix source-of-truth + certified/general profiles + Ubuntu-only natural gate | reopened 2026-03-06, audit: VM execute path placeholder + template debt register |
| [ ] 38 | CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md | Process ladder | CI-enforced stage order and status integrity | reopened 2026-03-06, ladder hold until stage35/stage37 are re-closed honestly |
| [ ] 39 | CHECKLIST_39_AI_ENGINEERING_GOVERNANCE.md | AI governance | enforceable AI engineering operating model, review split, lessons learned, truthfulness gate | |
| [ ] 40 | CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md | Showcase/visual language | brand/showcase layer, demo story, client-facing evidence narrative | |
| [ ] 41 | CHECKLIST_41_AST_UI_LAWS_AUTOMATION.md | UI-law automation | AST/static UI laws + self-healing test/doc automation | |
| [ ] 42 | CHECKLIST_42_EVIDENCE_INTELLIGENCE_AND_DRIFT.md | Evidence intelligence | Proof Completeness Score + DNA Drift Radar + Proof-Carrying AI Claims | |
| [ ] 43 | CHECKLIST_43_SAFE_ACTION_INTELLIGENCE.md | Action intelligence | Counterfactual simulator + enforceable NRAC + Wasm sandbox | |
| [ ] 44 | CHECKLIST_44_INCIDENT_CAPSULE_AND_TWIN.md | Capsule/Twin | reproducible incident capsule + deterministic incident twin | |
| [ ] 45 | CHECKLIST_45_FORENSIC_ENRICHMENT_AND_GRAPH.md | Forensic/Graph | eBPF evidence linking + graph-backed exploration + future-safe crypto path | |

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [ ] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия. Для MASTER это дополнительно означает реальный production `GO`, а не промежуточную готовность.
