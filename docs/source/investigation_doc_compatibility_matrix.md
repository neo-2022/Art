# InvestigationDoc Compatibility Matrix (v0.2)

Последняя актуализация: 2026-03-06

## Source of truth
- `docs/contracts/v2/schemas/investigation_doc_v1.json`
- `docs/source/investigations_as_code.md`
- `docs/source/checklists/CHECKLIST_31_INVESTIGATIONS_AS_CODE.md`

## Matrix
| Producer format | Consumer parser | Expected result | Blocker |
|---|---|---|---|
| v1 (`version=v1`) | v0.2 parser/serializer | PASS, replay/fork/compare remain deterministic | none |
| v1 + extra fields | v0.2 parser/serializer | PASS, additional fields tolerated in runtime document path | none |
| malformed (missing required arrays) | v0.2 parser/serializer | FAIL with deterministic parser error | release-blocker |

## Migration rules
1. Breaking change in InvestigationDoc contract requires `doc_version` bump and explicit migration note.
2. Any parser change requires backward compatibility test in `packages/local-stores/test/local-stores.test.mjs`.
3. Stage31 cannot be closed without PASS logs for parser/serializer and replay compatibility path.
