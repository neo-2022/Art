# Repo Protection Evidence (`main`)

## Source of truth
- `docs/source/checklists/CHECKLIST_01_GOVERNANCE_SRE.md`
- `.github/CODEOWNERS`
- `docs/governance/change_policy.md`

## Проверка

- Дата проверки: `2026-03-07`
- Проверяющий: `neo-2022`
- Branch: `main`
- Аккаунт GitHub API: `neo-2022`
- API источник baseline metadata: `GET /repos/neo-2022/Art/branches/main`
- API источник полного protection contract: `GET /repos/neo-2022/Art/branches/main/protection`
- Screenshot-proof: `docs/governance/evidence/branch_protection_main.png`
- Raw branch metadata: `docs/governance/evidence/branch_protection_main.json`
- Raw full protection contract: `docs/governance/evidence/branch_protection_main_full.json`
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
- `required_status_checks.strict=true`
- `required_pull_request_reviews.required_approving_review_count=1`
- `required_pull_request_reviews.require_code_owner_reviews=true`
- `enforce_admins.enabled=true`
- `allow_force_pushes.enabled=false`
- `allow_deletions.enabled=false`
- `required_signatures.enabled=true`
- branch protection действует на основной production branch

## Дополнительное операционное подтверждение

- `PR #20` смёржен только после `APPROVED` review и зелёных required checks.
- `PR #21` находится в том же protection path: review + checks идут через GitHub merge gate, а не прямым коммитом в `main`.
- `change_policy.md` дополнительно фиксирует запрет обхода protection path на уровне governance.

## Ограничения доказательства

- `git push --dry-run` не используется как надёжный proof branch protection, потому что dry-run не является авторитетным серверным доказательством enforcement.
- авторитетным evidence для этого пункта считаются:
  - owner-level GitHub API снимок полного protection contract;
  - branch metadata;
  - screenshot-proof;
  - PR evidence с review/check gate.
