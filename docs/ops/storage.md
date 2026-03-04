# Storage chaos

Сценарии:
- kill -9 во время ingest
- disk full
- WAL corruption

Критерии pass/fail:
- recovery успешен
- ingest возвращается в норму
- события `observability_gap.*` фиксируются
