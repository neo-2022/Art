# Panel0 Service Worker cache

Service Worker включён только для scope `/panel0`.

Кэш:
- имя: `panel0-cache-<build_id>`
- precache: `index.html`, `panel0.js`, `panel0.css`, `favicon`

Update strategy:
- в install вызывается `skipWaiting`
- после reload используются новые ассеты

Offline:
- первый online заход прогревает cache
- последующий reload offline отдаётся из cache

