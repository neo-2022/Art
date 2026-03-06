A) Полный запрет опциональности:
# CHECKLIST 00 — MASTER (Art v1 + REGART) + STANDARD (единые правила)
Файл: CHECKLIST_00_MASTER_ART_REGART.md  
Последняя актуализация: 2026-03-06  
Дата последней проверки: 2026-03-06 (усиление программы v0.2: stages 28..38 + ladder enforcement)  
Триггер пересмотра: любые изменения в Art_v1_spec_final.md / FOUNDATION_CONSTITUTION_V0_2.md / REGART↔Art описание / CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md / CHECKLIST_06_REGART_ART_BRIDGE.md / внешние источники в my_langgraph_agent
Отчёт аудита: docs/source/checklists/CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md

Источники требований:
- Art: `docs/source/Art_v1_spec_final.md`
- REGART ↔ Art: `docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`
- REGART UI/Debugger wrapper (в Art): `docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`
- REGART Bridge wrapper (в Art): `docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`
- REGART UI/Debugger source-of-truth (внешний репозиторий): `my_langgraph_agent/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`  
  GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md`
- REGART Bridge source-of-truth (внешний репозиторий): `my_langgraph_agent/CHECKLIST_REGART_ART_INTEGRATION.md`  
  GitHub: `https://github.com/neo-2022/my_langgraph_agent/blob/main/CHECKLIST_REGART_ART_INTEGRATION.md`
- Risk register v0.2: `docs/source/risk_register_v0_2.md`

⚠️ ПРАВИЛО: переход к следующему этапу возможен только после полного закрытия предыдущего.  
⚠️ ПРАВИЛО: запрещено удалять пункты из чек-листов без согласования с владельцем проекта.  
⚠️ ПРАВИЛО: отметка [x] ставится ТОЛЬКО после реальной проверки (команда/тест/сценарий) и фиксации результата (дата+commit/PR).  
⚠️ ПРАВИЛО: запрещены “временные решения” в репозитории — только финальные реализации (временное — только локально и сразу удалить).  
⚠️ ПРАВИЛО: полный запрет опциональности — запрещены формулировки “опционально/где применимо/если нужно/решение зафиксировано/либо A либо B”.
⚠️ ПРАВИЛО: запрещено создавать и хранить копии чек-листов (`*.bak`, `*_copy*`, `*_old*` и аналоги). Разрешён только один актуальный файл каждого чек-листа.
⚠️ ПРАВИЛО: всегда держать в контексте файл `/home/art/my_langgraph_agent/AGENTS.md`; для Codex он считается системным промтом проекта.

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
- [x] — сделано только после проверки  
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

---

## B) MASTER: этапы проекта (строго по порядку)

> “Выполнено”: `YYYY-MM-DD, подпись/ник, commit/PR`

| № | Файл | Этап | Кратко | Выполнено |
|---:|---|---|---|---|
| [x] 01 | CHECKLIST_01_GOVERNANCE_SRE.md | Governance/SRE | incident/postmortem/change mgmt + gap escalation + SLO | 2026-03-05, neo-2022, stage01 docs |
| [x] 02 | CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md | Privacy baseline | PII surface + redaction_applied + attachments PII retention | 2026-03-05, neo-2022, stage02 docs |
| [x] 03 | CHECKLIST_03_REGIONAL_PROFILES.md | Региональные профили | profile switch + airgapped packs update | 2026-03-05, neo-2022, stage03 runtime+tests |
| [x] 04 | CHECKLIST_04 _Secure SDLC + Supply-chain.md | Secure SDLC | clean builds + branch policy + signed commits + sigstore/cosign | 2026-03-05, neo-2022, stage04 runs:22705479817+22705930171 |
| [x] 05 | CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md | REGART UI/Debugger | wrapper → external source-of-truth `my_langgraph_agent/CHECKLIST_UI_GRAPH_RUN_DEBUGGER.md` | 2026-03-05, neo-2022, PR#4 approved + stage05-wrapper-gate |
| [x] 06 | CHECKLIST_06_REGART_ART_BRIDGE.md | REGART→Art bridge | wrapper → external source-of-truth `my_langgraph_agent/CHECKLIST_REGART_ART_INTEGRATION.md` | 2026-03-05, neo-2022, stage06 wrapper+ci gate |
| [x] 07 | CHECKLIST_07_ART_REPO_CI_DOCS.md | Art repo WP0 | CI включает gitleaks + licenses + RU dev docs | 2026-03-05, neo-2022, stage07 ci+docs+gate |
| [x] 08 | CHECKLIST_08_ART_CONTRACTS_OPENAPI_CODEGEN.md | Contracts | schema registry + spec compliance + unknown-fields tests | 2026-03-05, neo-2022, PR#6 + ci:22716780559 |
| [x] 09 | CHECKLIST_09_TELEMETRY_OTEL_OTLP.md | Telemetry | unknown attrs→payload.otel_attributes + severity tests + OTLP rate-limit | 2026-03-05, neo-2022, PR#8 + ci:22717440634 |
| [x] 10 | CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md | Browser Level0 | CORS gap + gzip>1KB + TTL 7d→DLQ + worker+fallback | 2026-03-05, neo-2022, stage10 runtime+tests+docs-gate |
| [x] 11 | CHECKLIST_11_ART_CORE_STORAGE_SQLITE.md | Core Storage | WAL corruption recovery + concurrency + VACUUM timer weekly | 2026-03-05, neo-2022, stage11 runtime+tests+docs-gate |
| [x] 12 | CHECKLIST_12_ART_CORE_INGEST_ACK_SEQ.md | Core Ingest | invalid_details + overload 503 + ingest_dropped_total | 2026-03-05, neo-2022, stage12 runtime+tests+docs-gate |
| [x] 13 | CHECKLIST_13_ART_CORE_PIPELINE_ENRICH_RULES.md | Pipeline | correlation→Incident + collision + template injection security | 2026-03-05, neo-2022, stage13 runtime+tests+docs-gate |
| [x] 14 | CHECKLIST_14_ART_CORE_STREAM_SNAPSHOT_SSE.md | Stream/Snapshot | Last-Event-ID too old→snapshot + 10k events + 1000 subs + gzip | 2026-03-05, neo-2022, stream-integration+stream-load-smoke+stage14-docs-gate (local recheck) |
| [x] 15 | CHECKLIST_15_ART_CORE_ACTIONS_AUDIT_RBAC_PII.md | Actions/Audit/RBAC/PII | client_ip/user_agent + access_denied event + immutability | 2026-03-05, neo-2022, actions-audit-tests+stage15-docs-gate (local recheck) |
| [x] 16 | CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md | Panel0 | embedded `/panel0/*` + `/` auto-fallback 5s + console_boot_failed backlog | 2026-03-06, neo-2022, panel0-e2e+stage16-docs-gate(docs+runtime)+panel0-linux-readiness |
| [x] 17 | CHECKLIST_17_ART_AGENT_SPOOL_OUTBOX.md | Agent Spool | block receivers on full + spool_corrupted recovery + concurrency + chaos | 2026-03-05, neo-2022, agent-spool-tests+agent-spool-chaos-smoke+stage17-docs-gate |
| [x] 18 | CHECKLIST_18_ART_AGENT_RECEIVERS.md | Agent Receivers | per-receiver buffer policy+gap + SIGHUP tests + journald perms gap | 2026-03-05, neo-2022, agent-receivers-tests+stage18-docs-gate |
| [x] 19 | CHECKLIST_19_PACKS_FRAMEWORK.md | Packs | manual updates only + cosign signature verify + dependencies | 2026-03-05, neo-2022, packs-tests+stage19-docs-gate |
| [x] 20 | CHECKLIST_20_PACK_REGART.md | Pack REGART | fixtures всех событий + correlation + receivers.toml examples | 2026-03-05, neo-2022, pack-regart-tests+stage20-docs-gate |
| [x] 21 | CHECKLIST_21_SELF_OBSERVABILITY_ART.md | Self-obs | required internal incidents + grafana/ + alert tests | 2026-03-05, neo-2022, self-obs-tests+stage21-docs-gate |
| [x] 22 | CHECKLIST_22_E2E_STRESS_CHAOS_SOAK_PERF.md | E2E/Chaos/Soak | 50% packet loss + memory profiling + power loss + nightly chaos | 2026-03-05, neo-2022, e2e-smoke+e2e-chaos+stage22-docs-gate |
| [x] 23 | CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md | Ops/DR | cert-manager + systemd TLS reload SIGHUP + DB migration runbook + WAL backups | 2026-03-05, neo-2022, ops-smoke+ops-docs-gate |
| [x] 24 | CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md | Release | downgrade with data + cosign sign images + RELEASE_CHECKLIST + manual releases | 2026-03-05, neo-2022, release-regression+release-signing-verify+stage24-docs-gate |
| [x] 25 | CHECKLIST_25_COMPLIANCE_AUDIT_READY.md | Compliance | export scripts + immutable evidence + data destruction policy | 2026-03-05, neo-2022, compliance-export+stage25-docs-gate |
| [x] 26 | CHECKLIST_26_RU_PROFILE.md | RU profile | PDn fields list + PII access audit + block cross-border export | 2026-03-05, neo-2022, ru-profile-tests+stage26-docs-gate |
| [x] 27 | CHECKLIST_27_AUDIT_REMEDIATION_PLAN.md | Audit/remediation | сводный аудит соответствия и закрытие найденных рисков | 2026-03-05, neo-2022, checklist27 remediation closed |
| [x] 28 | CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md | Console foundation | monorepo apps+packages, workspace boundaries, console shell surfaces | 2026-03-06, neo-2022, stage28-docs-gate+stage28-lens-gate+stage28-audio-settings-e2e+workspace-boundary(-negative) PASS |
| [x] 29 | CHECKLIST_29_EVENT_DNA_CORE_V2.md | Event DNA Core v2 | deterministic DNA core: formal model + property 1M + reference parity + `/api/v2/*` | 2026-03-06, neo-2022, stage29-dna-assurance-gate+stage29-dna-tests+stage29-dna-property-million+stage29-contract-fingerprint+stage29-nightly-replay-determinism+stage28-docs-gate PASS |
| [x] 30 | CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md | Evidence/Claims/Dialogic | evidence blocks, claim lifecycle, dialog schemas, UI law checks | 2026-03-06, neo-2022, stage30-evidence-claims-tests+stage30-truth-modes-tests+console-test+stage30_dod_validation_artifact PASS |
| [x] 31 | CHECKLIST_31_INVESTIGATIONS_AS_CODE.md | Investigations-as-Code | versioned InvestigationDoc, fork/replay/compare | 2026-03-06, neo-2022, stage31-investigation-doc-tests+stage31-investigation-library-tests+local-stores integration/e2e artifacts PASS |
| [ ] 32 | CHECKLIST_32_AUDIT_MERKLE_VERIFY_UI.md | Audit+Merkle | crypto verify flow and proof attachment | -- |
| [ ] 33 | CHECKLIST_33_SECURE_ACTIONS_PROTOCOL_V2.md | Secure Actions v2 | preflight/policy gates, no silent actions | -- |
| [ ] 34 | CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md | Perf/Load/Coverage | DNA perf budgets 10k/100k + overload 2x/3x + ratchet 5% + coverage ratchet | -- |
| [ ] 35 | CHECKLIST_35_SPATIAL_STORE_3D_READINESS.md | Spatial/3D readiness | spatial store contracts, picking/visibility invariants | -- |
| [ ] 36 | CHECKLIST_36_SAAS_READINESS_ARCHITECTURE.md | SaaS readiness | tenant/control-data-plane architecture contracts | -- |
| [ ] 37 | CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md | Linux hardening | canary/rollback + OS matrix source-of-truth + certified/general profiles + Ubuntu-only natural gate | -- |
| [ ] 38 | CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md | Process ladder | CI-enforced stage order and status integrity | -- |

## Финальный блокирующий чекбокс (единое жёсткое правило)
- [x] Этап/лист закрывается только после фактического прохождения всех пунктов этого листа: каждый пункт имеет PASS-проверку и подтверждённый артефакт (тест/лог/команда/файл/CI), и только после этого ставится финальная отметка закрытия.
