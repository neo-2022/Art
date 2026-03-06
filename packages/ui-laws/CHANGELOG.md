# @art/ui-laws Changelog

## Source of truth
- `docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`

## law_version 1.0.0
- Baseline invariant set fixed for stage30:
  - claim requires `evidence_refs`
  - observed truth mode requires evidence
  - truth meta contract checks
  - tooltip key invariant
  - evidence-link format invariant

## Migration rules (mandatory)
1. Any breaking change in invariants requires `law_version` MAJOR bump.
2. Backward-compatible rule expansion requires `law_version` MINOR bump.
3. Non-behavioral fixes require `law_version` PATCH bump.
4. Consumer packages must pin compatible `law_version` range before upgrade.
5. Any `law_version` change must include test updates and CI green for `@art/ui-laws`.
