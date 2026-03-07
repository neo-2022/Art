# Runbook: browser_surface_policy_degraded

## Symptoms
- В логе и snapshot/stream появляется `observability_gap.browser_surface_policy_degraded`.
- Проверки browser security headers/CSP/SRI/fallback policy дают отказ.
- Showcase или browser shell переводится в safe fallback presentation.

## Diagnosis
1. Проверить CSP и browser security headers фактического deployment.
2. Проверить, не ослаблен ли browser baseline ради showcase/demo режима.
3. Проверить integrity/provenance статических ассетов.
4. Проверить embedding policy и frame restrictions.
5. Сверить release evidence и runtime policy с source-of-truth документом.

## Mitigations
1. Вернуть production browser policy baseline.
2. Отключить небезопасный showcase/demo path.
3. Удалить небезопасные external assets или включить integrity control.
4. Восстановить safe fallback presentation.
5. Обновить release evidence и policy checks.

Краткие mitigations:
- восстановить безопасный baseline браузерной поверхности;
- исключить ослабляющие policy изменения;
- повторно зафиксировать защитные доказательства в release evidence.

## Verification
1. Повторить negative tests на policy degradation.
2. Подтвердить отсутствие unsafe relaxations (`unsafe-inline`, frame allow, external asset drift).
3. Подтвердить, что `observability_gap.browser_surface_policy_degraded` больше не генерируется в штатном режиме.
4. Подтвердить, что browser surface baseline снова соответствует release profile.

Краткая verification:
- проверить, что policy и заголовки восстановлены;
- проверить, что негативные сценарии снова блокируются;
- проверить, что деградационное событие больше не появляется без причины.
