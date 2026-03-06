# Platform Support Matrix (Art / REGART)

## Source of truth
- `formats/platform_support.yaml`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`

## Зачем это нужно
Платформенная поддержка для Art и REGART должна быть предсказуемой для внедрения в регулируемых и enterprise-контурах. Практический вывод: различия между ОС не должны проникать в логику `core/agent/browser`, а должны жить только в упаковке, инсталляции, проверках и build-профилях. Такой подход позволяет масштабировать поддержку дистрибутивов без архитектурных разрывов.

## Уровни поддержки
- `Level A (certified)`: Astra Linux SE, RED OS.
- `Level B (native)`: ALT, ROSA, ОСнова, Ubuntu, Debian, AlmaLinux/Rocky, Fedora, openSUSE.
- `Level C (developer/universal)`: Arch, Calculate, MCC.

Полный перечень и методы установки определяются только в `formats/platform_support.yaml`.

## CI сейчас
- Натурные тесты исполняются только на Ubuntu.
- Для остальных дистрибутивов job-скелеты существуют и валидны, но отключены условием `ENABLE_NATURAL_MATRIX=false`.
- Это сознательный режим до подключения выделенных runner-ов.

## Release artifacts contract
- `artcore-<version>-linux-x86_64-static.tar.gz`
- `artagent-<version>-linux-x86_64-static.tar.gz`
- `SHA256SUMS`
- `sbom.spdx.json`
- Docker runtime skeletons: `docker/core.Dockerfile`, `docker/agent.Dockerfile` (`FROM scratch`, static binaries).

## Nat testing после финала
После включения `ENABLE_NATURAL_MATRIX=true` активируются натуральные install/smoke jobs:
- `debian-smoke`
- `fedora-smoke`
- `opensuse-smoke`
- `almalinux-rocky-smoke`
- `alt-smoke`
- `rosa-smoke`
- `astra-certified-smoke`
- `redos-certified-smoke`

## Evidence IDs
Обязательные артефакты текущего этапа:
- `EVIDENCE_PLATFORM_MATRIX`
- `EVIDENCE_CERTIFIED_BUILD`
- `EVIDENCE_DEB_PACKAGE_LAYOUT`
- `EVIDENCE_RPM_PACKAGE_LAYOUT`
- `EVIDENCE_SYSTEMD_UNITS`
- `EVIDENCE_DOCKER_REPRODUCIBLE`
- `EVIDENCE_SBOM`
- `EVIDENCE_REGART_INTEGRATION_UBUNTU_SMOKE`

Плейсхолдеры для будущих натурных прогонов:
- `EVIDENCE_NATURAL_TEST_<distro>`
