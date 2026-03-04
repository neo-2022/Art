# Stage 03 test matrix

Тесты автоматизированы и включены в CI.

- profile switch строго по процедуре stop->stop->apply->start->guard->start
- airgapped update без подписи отклоняется
- airgapped update при несовместимости отклоняется
- profile violation генерирует `observability_gap.profile_violation`
- пути тестов: `tests/stage03/*`
- запуск в CI: job `stage03-docs-gate` + integration stage03
