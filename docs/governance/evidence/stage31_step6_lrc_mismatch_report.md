# Stage31 LRC Mismatch Report

runbook_id: rb-sample
invalid_steps: safe-action

| step_id | status | missing_evidence_refs | suggested_evidence_patch |
|---|---|---|---|
| collect-evidence | valid | - | keep current evidence set |
| safe-action | invalid | ev-2 | attach `ev-2` from latest snapshot before executing action |
