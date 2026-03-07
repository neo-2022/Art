# Privacy test matrix

## Source of truth
- `docs/source/checklists/CHECKLIST_02_PRIVACY_BASELINE_GLOBAL.md`
- `docs/privacy/redaction_policy.md`
- `docs/privacy/attachments_security.md`
- `docs/privacy/dsr_process.md`

## Unit

- redaction rules:
  - secrets redacted/dropped deterministically
  - PII redacted deterministically
  - `privacy.redaction_applied` generated when data changed

## Integration

- secrets do not reach logs
- secrets do not reach API responses
- secrets do not reach audit pre-write
- attachments:
  - MIME allowlist enforced
  - magic bytes validated
  - `max size` enforced
  - `sanitize filename` enforced
  - active content / XSS blocked
- DSR:
  - export path produces artifact
  - delete path produces artifact/report

## Критерий актуальности

Документ считается актуальным только если:
- определены unit tests для redaction;
- определены integration tests для log/response/audit leakage prevention;
- определены integration tests для attachments;
- определены integration tests для DSR export/delete.
