# Panel0 Service Worker cache

Service Worker включён только для scope `/panel0`.
Регистрация допустима только в secure context (`https`/локальный trusted env).

Кэш:
- имя: `panel0-cache-<build_id>`
- precache: `index.html`, `panel0.js`, `panel0.css`, `favicon`

Update strategy:
- в install вызывается `skipWaiting`
- после reload используются новые ассеты

Offline:
- первый online заход прогревает cache
- последующий reload offline отдаётся из cache
- если cache-miss при offline, SW возвращает ответ `503` c заголовком `x-art-offline: 1`

Негативные сценарии:
- cache write failure (quota/put error) не ломает online response;
- insecure context отключает регистрацию SW (`shouldRegisterServiceWorker(..., false) = false`).
