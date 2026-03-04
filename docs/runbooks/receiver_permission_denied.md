# Runbook: receiver_permission_denied

## symptoms
- `observability_gap.receiver_permission_denied`
- file_tail/journald не может читать источник

## checks
- права пользователя агента
- ACL/SELinux/AppArmor ограничения

## mitigations
- выдать минимально необходимые права
- перезапустить receiver после обновления прав

## verification
- ошибки permission denied исчезли
- новые события поступают
