# Runbook: pack_install_failed

## symptoms
- событие `observability_gap.pack_install_failed`
- pack не активируется после install

## checks
- `fail_stage` (`layout|signature|deps|io|activate`)
- валидность `manifest.yaml`
- наличие и корректность cosign signature
- состояние зависимостей

## mitigations
- исправить layout/signature/deps по причине fail_stage
- повторить install только после успешного verify

## verification
- install проходит без ошибки
- pack активирован
