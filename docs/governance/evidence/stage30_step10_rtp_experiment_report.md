# Stage30 Step10 RTP Experiment Report

Date: 2026-03-06
Checklist: `CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md` step 10

## Command
`corepack pnpm --filter @art/ui-laws run test`

## Result
PASS (`ui-laws: RTP tournament verdict and trace payload`)

## Sample tournament trace
```json
{
  "claim_id": "claim-rtp-1",
  "verdict": "contested",
  "contested_count": 1,
  "results": [
    {
      "refuter_id": "r1",
      "status": "pass",
      "reason": "baseline stable",
      "evidence_refs": ["ev-a"]
    },
    {
      "refuter_id": "r2",
      "status": "contested",
      "reason": "counter-signal",
      "evidence_refs": ["ev-b"]
    }
  ]
}
```

## Notes
- RTP verdict policy: any `contested` refuter result makes claim verdict `contested`.
- Refuter result without `evidence_refs` is rejected as UI-law violation.
