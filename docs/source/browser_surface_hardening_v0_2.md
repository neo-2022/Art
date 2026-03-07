# Browser Surface Hardening v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/Art_v1_spec_final.md`
- `docs/testing/defect_remediation_control_matrix_v0_2.md`
- `docs/source/checklists/CHECKLIST_10_ART_BROWSER_LEVEL0_UNIVERSAL.md`
- `docs/source/checklists/CHECKLIST_16_ART_CORE_PANEL0_EMBEDDED_UI.md`
- `docs/source/checklists/CHECKLIST_24_RELEASE_UPGRADE_REGRESSION.md`
- `docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_40_PRODUCT_SHOWCASE_VISUAL_LANGUAGE.md`

## Назначение
Этот документ задаёт обязательный baseline hardening для браузерной поверхности проекта.

Под браузерной поверхностью понимаются:
- Browser Level0;
- Panel0;
- Console;
- showcase/demo слой;
- все статические web-ассеты, через которые проект попадает в браузер.

Документ пишется не только для frontend/security специалистов. Он обязан объяснять защитный смысл каждого механизма так, чтобы новый инженер и оператор понимали, что именно защищается и что произойдёт при ослаблении этой политики.

## Проблема
Даже если backend хорошо защищён, браузерный слой остаётся точкой атак и деградаций:
- подмена статических ассетов;
- небезопасные inline-скрипты;
- встраивание во враждебный frame;
- чрезмерные browser permissions;
- ослабление CSP ради удобства;
- showcase/demo режим, который незаметно ломает боевой security baseline.

## Обязательный закон
1. Browser surface должна иметь production-safe baseline по умолчанию.
2. Showcase/demo слой не имеет права ослаблять browser security baseline.
3. Любая деградация browser surface policy фиксируется как `observability_gap.browser_surface_policy_degraded`.
4. Отсутствие browser hardening baseline для internet-exposed deployment считается release blocker.

## Обязательные защитные механизмы
### CSP (Content Security Policy)
- `default-src 'self'`
- `object-src 'none'`
- `base-uri 'self'`
- `frame-ancestors 'none'` или явный allowlist
- inline script/style запрещены, кроме строго задокументированных hash/nonce случаев

### SRI (Subresource Integrity)
- если подключаются внешние ассеты, они обязаны иметь integrity protection;
- для production baseline предпочтителен полный отказ от внешних ассетов.

### Browser security headers
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy`
- `Permissions-Policy`
- `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy` по необходимости

### Frame / embedding policy
- приложение не должно встраиваться во внешний frame без явного архитектурного решения;
- любые embed-сценарии должны быть allowlist-driven.

### Asset integrity and provenance
- browser assets должны быть project-owned или allowlisted;
- build pipeline обязан обнаруживать разъезд asset policy и реального bundle.

## Особые правила для Panel0 и Console
### Panel0
- аварийный UI не имеет права быть более слабым по browser security, чем основной Console;
- fallback не может означать отключение CSP или embedding control.

### Console
- bilingual/i18n shell и agent/showcase слой не могут приводить к unsafe inline injection;
- settings/audio/showcase assets подчиняются authenticity policy.

## Особые правила для showcase/demo режима
- demo-safe motion/audio не имеет права ослаблять browser policy;
- showcase режим обязан деградировать безопасно;
- broken showcase asset path обязан переводить систему в safe presentation fallback, а не в небезопасный режим.

## Отрицательные сценарии (negative-path)
1. Попытка ослабить `frame-ancestors` ради demo.
2. Попытка использовать external script без SRI.
3. Попытка включить `unsafe-inline` без жёсткого исключения.
4. Попытка показать showcase mode без browser hardening baseline.
5. Повреждённый static asset path.
6. Internet-exposed profile без browser surface evidence.

## Required evidence
Для закрытия remediation должны существовать:
- browser/panel0/console hardening docs;
- negative tests на policy degradation;
- release evidence, что browser surface baseline включён;
- runbook и gap event для деградации browser surface.
- для REGART и partner-exposed browser-plane — pinned external adversarial harness evidence, показывающее browser surface policy под внешней hostile нагрузкой.

## Checklist mapping
- Stage 10 — Browser Level0
- Stage 16 — Panel0
- Stage 24 — release / upgrade / regression
- Stage 28 — Console foundation
- Stage 37 — Linux hardening
- Stage 40 — showcase / visual language

## Статус
- Статус: `ACTIVE`
- Роль: `MANDATORY_PROTECTIVE_CONTOUR`
