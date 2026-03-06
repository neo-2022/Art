# Шаблон Решения Go/No-Go

## Source of truth
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `docs/source/checklists/CHECKLIST_23_OPS_DEPLOY_RUNBOOKS_DR.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`
- `docs/release/release_process.md`
- `docs/ops/console_linux_prod_readiness.md`
- `docs/ops/platform-runtime-compatibility-matrix.md`

## Назначение
Шаблон фиксирует единое решение перед rollout: релиз допускается только после явного `GO`, подтверждённого обязательными gates, артефактами и rollback-планом.

## Когда Использовать
- production rollout;
- canary expansion;
- major upgrade / migration;
- rollout после security/performance remediation;
- восстановление после incident-driven freeze.

## Жёсткие Правила
1. Решение `GO` запрещено, если есть хотя бы один красный required check.
2. Решение `GO` запрещено, если есть открытый release-blocker в risk register или checklist gates.
3. Решение `GO` запрещено, если dual-write mismatch rate после grace window больше `0`.
4. Решение `GO` запрещено, если отсутствует rollback plan с проверяемой точкой возврата.
5. Решение `GO` запрещено, если evidence artifacts не приложены или не трассируются к MASTER/checklists.

## Шаблон

```md
# GO/NO-GO DECISION SHEET

## 1. Общая информация
- Release ID:
- Commit / Tag:
- Дата / время UTC:
- Окно релиза:
- Окружение: `prod` | `staging`
- Стратегия: `canary` | `phased` | `full`
- Инициатор:
- Release Manager:
- Incident Commander:
- Канал коммуникации:

## 2. Обязательные gates (PASS / FAIL)
- [ ] Все required GitHub checks = PASS
- [ ] Все обязательные checklist gates = PASS
- [ ] Linux readiness suite = PASS
- [ ] Platform/runtime compatibility gate = PASS
- [ ] Security gates (`sast`, `sca`, `secrets`, `gitleaks`) = PASS
- [ ] Docs/source-of-truth gates = PASS
- [ ] Evidence ledger и delivery artifacts обновлены
- [ ] Rollback plan проверен
- [ ] Alerting / observability gates включены

## 3. Критические метрики перед релизом
- Error budget:
- p95 latency:
- Ingest / Stream health:
- Snapshot consistency:
- Dual-write mismatch rate after grace window:
- Canary divergence incidents:
- Outbox / backlog status:
- Последний smoke/e2e прогон:

## 4. Блокеры и риски
- Открытые blockers:
- Допустимые риски с owner:
- Условие немедленного STOP rollout:
- Требуется ли manual watch window:

## 5. План выката
- Шаг 1:
- Критерий PASS шага 1:
- Шаг 2:
- Критерий PASS шага 2:
- Шаг 3:
- Критерий PASS шага 3:
- Observation timeout на каждом шаге:

## 6. План отката
- Rollback tag / commit:
- Команда / workflow отката:
- RTO:
- Проверки после отката:
- Кто выполняет rollback:

## 7. Evidence
- CI run URL:
- Release artifacts:
- SBOM / checksums:
- Runtime logs:
- Screenshots / reports:
- Evidence IDs:

## 8. Решение
- Decision: `GO` | `NO-GO`
- Обоснование:
- Дополнительные условия:
- Следующая контрольная точка:

## 9. Подписи
- Release Manager:
- Tech Lead:
- SRE / Operations:
- Security:
- Product Owner (если требуется):
```

## Минимальный Порядок Заполнения
1. Сначала фиксируются commit/tag и CI run.
2. Затем отмечаются только реально пройденные gates.
3. Затем заносятся метрики и blockers.
4. Только после этого принимается решение `GO` или `NO-GO`.
5. Заполненный sheet прикладывается к release evidence / change record.

## Что Считается PASS
- обязательные проверки зелёные;
- все ссылки на evidence открываются и соответствуют текущему release candidate;
- rollback можно выполнить без ручной импровизации;
- решение подписано ответственными ролями.

## Что Считается NO-GO
- хотя бы один required gate в `pending` или `fail`;
- есть расхождение между runtime state и documented state;
- отсутствует часть release artifacts;
- нет подтверждения по Linux prod readiness или platform compatibility.
