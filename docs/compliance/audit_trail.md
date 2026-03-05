# Audit trail

- Запуск: `scripts/export_audit_pack.sh --from ... --to ... --out_dir ...`
- Источник данных экспорта: runtime API Core (`/api/v1/incidents`, `/api/v1/audit`)
- Контроль целостности: `checksums.txt`
- Проверка файлов: incidents/audit json+csv + meta.json
