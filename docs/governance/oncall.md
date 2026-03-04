# On-call процесс

## Расписание
- Primary: weekly rotation (пн 09:00 MSK -> пн 09:00 MSK)
- Secondary: backup rotation с тем же окном

## Канал оповещений
- Основной канал: incident chat + звонок при SEV0/SEV1
- Pager channel: phone/push

## Handover
1. Передача открытых инцидентов
2. Передача активных follow-ups
3. Проверка runbook ссылок

## Эскалация
- SEV0: немедленно Owner + Security
- SEV1: до 15 минут Owner
- SEV2/SEV3: в рабочее окно по SLA
