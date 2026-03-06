# Runbook: observability_gap.innovation_experiment_regression

Событие: `observability_gap.innovation_experiment_regression`
Компонент: `console/innovation`
Критичность по умолчанию: `SEV1`

## Symptoms
- KPI/ SLO для экспериментальных треков (`RTP`, `LRC`, `NRAC`) вышли за policy threshold.
- Канареечный rollout показывает деградацию относительно baseline.
- Gate-отчёт фиксирует `actual` хуже `baseline` по критичным метрикам.

## Diagnosis
1. Убедиться, что событие содержит полный `evidence_min`:
   - `experiment`, `metric`, `baseline`, `actual`, `threshold`, `trace_id`.
2. Проверить текущие значения feature flags:
   - `rtp_enabled`, `lrc_enabled`, `nrac_enabled`.
3. Сравнить canary и stable профили:
   - есть ли расхождение только на canary или в обоих контурах.
4. Подтвердить воспроизводимость регрессии:
   - повторить KPI suite на том же build/profile.

## Resolution
1. Немедленно выключить проблемный экспериментальный флаг (`auto-disable` или ручное отключение).
2. Остановить расширение rollout и вернуть canary к stable build.
3. Зафиксировать инцидент и создать remediation-задачу с root cause.
4. Повторно прогнать KPI suite:
   - PASS только при возврате в policy bounds.
5. Разрешить повторный rollout только после:
   - исправления,
   - повторного PASS KPI regression gate,
   - обновления артефактов в risk register/checklist.
