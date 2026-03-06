# Repo Protection Evidence (`main`)

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `.github/CODEOWNERS`
- `docs/governance/change_policy.md`

## Проверка

- Дата проверки: `2026-03-07`
- Проверяющий: `neo-2022`
- Branch: `main`
- API источник: `GET /repos/neo-2022/Art/branches/main`
- Screenshot-proof: `docs/governance/evidence/branch_protection_main.png`
- Raw API evidence: `docs/governance/evidence/branch_protection_main.json`
- Rendered report: `docs/governance/evidence/branch_protection_main_report.html`
- PR/commit включения baseline protection: `#20` / `1676a8a4c09be5067950aa45141e60c4aa315b2e`

## Что подтверждено

- `main` имеет `protected=true`
- включены required status checks:
  - `sdlc-gate`
  - `sast`
  - `sca`
  - `license`
  - `secrets`
- enforcement level для status checks: `everyone`
- branch protection действует на основной production branch

## Ограничения доказательства

GitHub API в доступном токен-контуре не отдал отдельный расширенный branch-protection endpoint и не вернул явное поле reviews/force-push через rulesets API.  
Поэтому текущее evidence состоит из:

- branch metadata из GitHub API;
- реального screenshot-proof с отображением проверенных параметров;
- операционного требования `change_policy.md`, которое запрещает обход protection path.

Если GitHub access scope будет расширен, доказательство должно быть усилено до прямого API-снимка полных review/force-push правил.
