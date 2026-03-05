export function panel0CacheName(buildId) {
  return `panel0-cache-${buildId}`;
}

export const PANEL0_PRECACHE = [
  "/panel0/index.html",
  "/panel0/panel0.js",
  "/panel0/panel0.css",
  "/panel0/favicon.ico",
];

export function shouldRegisterServiceWorker(pathname) {
  return String(pathname || "").startsWith("/panel0");
}

export function createServiceWorkerScript(buildId) {
  const cacheName = panel0CacheName(buildId);
  const precache = JSON.stringify(PANEL0_PRECACHE);
  return `const CACHE_NAME = "${cacheName}";
const PRECACHE = ${precache};
self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE)));
  self.skipWaiting();
});
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key.startsWith("panel0-cache-") && key !== CACHE_NAME).map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});
self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  event.respondWith(
    fetch(request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        return response;
      })
      .catch(() => caches.match(request))
  );
});
`;
}

