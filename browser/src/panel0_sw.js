export function panel0CacheName(buildId) {
  return `panel0-cache-${buildId}`;
}

export const PANEL0_PRECACHE = [
  "/panel0/index.html",
  "/panel0/panel0.js",
  "/panel0/panel0.css",
  "/panel0/favicon.ico",
];

export function shouldRegisterServiceWorker(pathname, isSecureContext = true) {
  return Boolean(isSecureContext) && String(pathname || "").startsWith("/panel0");
}

function isPanel0AssetRequest(request) {
  const rawUrl = String(request?.url || "");
  if (rawUrl.startsWith("/panel0/")) {
    return true;
  }
  if (!rawUrl) {
    return false;
  }
  try {
    return new URL(rawUrl).pathname.startsWith("/panel0/");
  } catch {
    return false;
  }
}

export async function resolvePanel0Fetch({
  request,
  fetchFn,
  cacheMatchFn,
  cachePutFn,
}) {
  if (request?.method !== "GET" || !isPanel0AssetRequest(request)) {
    return fetchFn(request);
  }
  try {
    const response = await fetchFn(request);
    if (typeof cachePutFn === "function") {
      try {
        await cachePutFn(request, response);
      } catch {
        // ignore cache write errors, network response must still be returned
      }
    }
    return response;
  } catch {
    if (typeof cacheMatchFn === "function") {
      const cached = await cacheMatchFn(request);
      if (cached) {
        return cached;
      }
    }
    return {
      status: 503,
      headers: { "x-art-offline": "1" },
      body: "offline",
    };
  }
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
  const url = new URL(request.url);
  if (!url.pathname.startsWith("/panel0/")) return;
  event.respondWith(
    fetch(request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        return response;
      })
      .catch(async () => {
        const cached = await caches.match(request);
        if (cached) return cached;
        return new Response("offline", {
          status: 503,
          headers: {
            "content-type": "text/plain; charset=utf-8",
            "x-art-offline": "1",
          },
        });
      })
  );
});
`;
}
