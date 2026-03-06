# Platform VM Testing (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `tests/platform/vm/run_vm_smoke.sh`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Зачем нужен VM-контур
VM-контур позволяет показать готовность продукта не на хостовой ОС разработчика, а на изолированных Linux-окружениях из платформенной матрицы. Это закрывает риск "работает только на моём хосте" и ускоряет переход к натуральной matrix-проверке.

## Что уже заложено
- Единый VM-harness: `tests/platform/vm/run_vm_smoke.sh`.
- VM-профили по каждому дистрибутиву матрицы: `tests/platform/vm/profiles/<distro>.env`.
- Единый evidence-контур:
  - `EVIDENCE_VM_MATRIX_READINESS`
  - `EVIDENCE_VM_TEST_<distro>`
- CI-gate для валидности VM-скелетов: `scripts/ci/check_platform_vm_skeletons.sh`.

## Режим CI сейчас
- Текущий режим: `ENABLE_NATURAL_MATRIX=false`.
- Это означает, что VM-скелеты валидируются в CI, но тяжёлые натуральные VM-прогоны не исполняются на каждом push.
- После подключения выделенных runner-ов включается `ENABLE_NATURAL_MATRIX=true` и VM smoke прогоны активируются без изменения бизнес-логики `core/agent/browser`.
- В текущем production scope VM track считается validate-only и не используется как основание для декларации runtime-совместимости вне Ubuntu host + container/K8s execute evidence.

## Как запускать локально (Linux host)
### 1) Validate mode (без поднятия VM)
```bash
DISTRO=ubuntu MODE=validate tests/platform/vm/run_vm_smoke.sh
```

### 2) Execute mode (с VM)
Требования: установлен `vagrant` + provider `libvirt`.

```bash
DISTRO=debian MODE=execute PROVIDER=vagrant-libvirt tests/platform/vm/run_vm_smoke.sh
```

Опционально сохранить VM после прогона:
```bash
DISTRO=fedora MODE=execute KEEP_VM=true tests/platform/vm/run_vm_smoke.sh
```

## Поддержка разных Linux версий
Для каждого дистрибутива профиль настраивается в `tests/platform/vm/profiles/<distro>.env`:
- `VM_IMAGE_HINT` — образ/box для конкретной версии Linux;
- `VM_VCPU`, `VM_MEMORY_MB`, `VM_DISK_GB` — ресурсы VM.

Таким образом можно прогонять разные версии Linux без изменения кода продукта.

## Ограничения и правило безопасности
- Платформенные различия допускаются только в install/packaging/test слоях.
- Логика `core/agent/browser` не ветвится по дистрибутивам.
- Для enterprise-дистрибутивов (Astra/RED/и др.) разрешён BYOI-подход (custom image).
