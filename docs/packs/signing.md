# Signing и verify для packs

## Требование
- Каждый pack подписывается через `cosign`.
- На установке verify обязателен.

## Install fail условия
- отсутствует подпись;
- подпись невалидна;
- issuer/identity не соответствует политике.

В каждом fail случае pack не активируется и формируется `observability_gap.pack_install_failed`.
