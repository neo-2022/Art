# DR drill

1. ingest тестовые события.
2. snapshot до сбоя.
3. имитация потери узла.
4. restore из backup.
5. snapshot после восстановления.

Критерий: ingest + snapshot совпадают, pass/fail: pass.

Runtime smoke команда:

```bash
bash scripts/tests/ops_stage23_smoke.sh
```
