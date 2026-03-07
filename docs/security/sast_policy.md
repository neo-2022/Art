# SAST policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/security_stage04.yml`

## Инструмент
- единый SAST инструмент: `semgrep`
- semgrep устанавливается в CI с pinned версией
- ruleset pinned и выполняется детерминированно в одном и том же CI path

## Scope
- SAST обязателен на каждом PR в `main`
- SAST обязателен на push в `main`
- локальная проверка не заменяет CI gate

## Fail policy
- findings уровня `error` блокируют merge
- отсутствие запуска `sast` job считается нарушением security baseline
- результаты сохраняются в artifact `semgrep-report.json`

## Enforcement
- blocking job name: `sast`
- workflow: `security-stage04`
- run command baseline: `semgrep scan --config auto --error --json --output semgrep-report.json`
