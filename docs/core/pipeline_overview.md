# Pipeline overview

Порядок стадий:
1. parse
2. validate
3. fingerprint
4. rules
5. enrich
6. correlation
7. incident upsert
8. publish snapshot/stream

При unhandled exception стадии генерируется `observability_gap.pipeline_stage_failed`.
