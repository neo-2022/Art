# Runbook: ui_proxy_unavailable

## symptoms
- индикатор UI Proxy в панели “Сервисы” помечен как OFF/задёрган, `/ui/art/stream` возвращает 502/502, `/ui/art/ingest` проседает с `Bad Gateway`.
- `observability_gap.ui_proxy_unavailable` появляется в Level0 (payload содержит endpoint/status/retry_count/backoff). Следим за 4 золотыми сигналами (latency/error/traffic/saturation) — рост latency или ошибки подчёркивают деградацию.

## checks
1. `systemctl status my_langgraph_ui_proxy.service` — убедиться, что service `Active: active (running)` и последнее событие неоднообразно.
2. `journalctl -u my_langgraph_ui_proxy.service -n 200 --no-pager` — поиск `listen`/`connect`/`TLS handshake` ошибок; фильтровать по `level=error`/`warning`.
3. `curl -f http://127.0.0.1:8090/ui/ui-proxy/status` — нужна JSON с `health.ok: true`. Зафиксируйте `base_url`, `health.reason`, `timestamp`.
4. Проверить конфигурацию (TLS/прокси/ports) в `/etc/my_langgraph/ui_proxy.toml` или `~/.config/my_langgraph/ui_proxy.config`; сравнить с последним успешным commit (git diff).

## mitigations
1. Попробовать `systemctl restart my_langgraph_ui_proxy.service` (best practice: graceful stop/start, ждать `Active: active` в течение 2 min). Использовать `sudo` только в безопасной среде.
2. При повторной ошибке проверить логи на `listen tcp :8090: bind: address already in use` (можно сменить port/убрать stray process с `ss -tulpn | grep 8090`).
3. При TLS-ошибках (expired cert, wrong cipher) вернуть предыдущие сертификаты/ключи, затем `systemctl restart`.
4. Если сервис требовался для нескольких окружений, временно перенаправить трафик через standby UI Proxy (например `nginx` upstream) пока не восстановится основной.

## rollback
1. Если недавний config change вызвал падение, `git checkout HEAD~1` нужный файл (в `config/` или `systemd/`), затем `systemctl daemon-reload && systemctl restart`.
2. Откатить пакеты/зависимости, которые были обновлены (например `pip`/`npm`), используя зафиксированную версию из `/home/art/Art/package-lock.json`.

## verification
1. `curl http://127.0.0.1:8090/ui/ui-proxy/status` возвращает `health.ok: true` и `observability_gap.ui_proxy_unavailable` перестаёт влёт в Level0.
2. UI показывает `UI Proxy: ON`, `/ui/art/stream` возвращает 200, `observability_gap.stream` показывает отсутствие gap.

## escalation
- если restart не помогает в течение 15 минут, передайте On-call engineer (devops@) с ссылкой на последние `journalctl` и `observability_gap` (trace_id, retry_count).
- если сервис не стартует (Exit code ≠ 0) — откройте incident ticket `obs-gap` и задокументируйте на Slack/Teams с tag `#art-ops`.
