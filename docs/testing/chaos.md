# Chaos report

## Network chaos Agent↔Core
- packet loss: 50%
- duration: 10 минут
- команда: `tc qdisc add dev lo root netem loss 50%`
- восстановление: `tc qdisc del dev lo root`

## Результат
- backlog во время chaos растет (spool/outbox)
- после восстановления backlog -> 0
- `ack.upto_seq` монотонен
- режим: `never_drop_unacked`, потерь нет
- pass/fail: pass

## Power loss recovery
- kill: `kill -9 <core_pid>`
- restart: `systemctl restart art-core.service`
- подтвержденные `seq <= ack.upto_seq` сохранены
- неподтвержденные переотправлены агентом
- dedup_key дубликатов не дал
- pass/fail: pass
