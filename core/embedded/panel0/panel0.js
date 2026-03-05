(function panel0Main() {
  const PANEL0_BUILD_ID = "__PANEL0_BUILD_ID__";
  const PANEL0_CACHE_NAME = `panel0-cache-${PANEL0_BUILD_ID}`;
  const BACKLOG_KEY = "art.panel0.console_boot_failed.backlog.v1";
  const BACKLOG_MAX = 64;
  const BOOT_EVENT_KIND = "observability_gap.console_boot_failed";
  const BOOT_EVIDENCE_KEYS = [
    "reason_type",
    "url",
    "http_status",
    "error_text",
    "timeout_ms",
    "build_id",
    "effective_profile_id",
    "trace_id",
  ];

  const buildIdEl = document.getElementById("build-id");
  const profileIdEl = document.getElementById("profile-id");
  const coreDownEl = document.getElementById("core-down");
  const coreDownReasonEl = document.getElementById("core-down-reason");
  const eventsListEl = document.getElementById("events-list");
  const reloadBtnEl = document.getElementById("reload-btn");

  if (buildIdEl) {
    buildIdEl.textContent = PANEL0_BUILD_ID || "dev";
  }

  function randomTraceId() {
    if (globalThis.crypto && typeof globalThis.crypto.randomUUID === "function") {
      return globalThis.crypto.randomUUID();
    }
    return `trace-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`;
  }

  function redactIfSensitive(value) {
    const text = String(value == null ? "none" : value);
    if (/authorization|cookie|token|secret|password|set-cookie/i.test(text)) {
      return "***redacted***";
    }
    return text;
  }

  function normalizeBootEvidence(raw) {
    const result = {
      reason_type: "network_error",
      url: "/console",
      http_status: null,
      error_text: "",
      timeout_ms: null,
      build_id: PANEL0_BUILD_ID || "dev",
      effective_profile_id: "unknown",
      trace_id: randomTraceId(),
    };
    const source = raw && typeof raw === "object" ? raw : {};
    for (const key of BOOT_EVIDENCE_KEYS) {
      if (Object.prototype.hasOwnProperty.call(source, key)) {
        result[key] = source[key];
      }
    }
    if (typeof result.http_status !== "number" || Number.isNaN(result.http_status)) {
      result.http_status = null;
    }
    if (typeof result.timeout_ms !== "number" || Number.isNaN(result.timeout_ms)) {
      result.timeout_ms = null;
    }
    result.reason_type = String(result.reason_type || "network_error");
    result.url = String(result.url || "/console");
    result.error_text = String(result.error_text || "");
    result.build_id = String(result.build_id || PANEL0_BUILD_ID || "dev");
    result.effective_profile_id = String(result.effective_profile_id || "unknown");
    result.trace_id = String(result.trace_id || randomTraceId());
    return result;
  }

  function loadBacklog() {
    try {
      const raw = globalThis.localStorage?.getItem(BACKLOG_KEY);
      if (!raw) {
        return [];
      }
      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed
        .filter((item) => item && typeof item === "object" && item.kind === BOOT_EVENT_KIND)
        .map((event) => ({
          ...event,
          details: normalizeBootEvidence(event.details),
        }));
    } catch {
      return [];
    }
  }

  function saveBacklog(events) {
    const normalized = events
      .filter((item) => item && typeof item === "object")
      .slice(-BACKLOG_MAX)
      .map((event) => ({
        ...event,
        details: normalizeBootEvidence(event.details),
      }));
    try {
      globalThis.localStorage?.setItem(BACKLOG_KEY, JSON.stringify(normalized));
    } catch {
      // ignore localStorage failures
    }
  }

  async function postIngest(events) {
    const response = await fetch("/api/v1/ingest", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ events }),
      cache: "no-store",
    });
    if (!response.ok) {
      throw new Error(`ingest_status_${response.status}`);
    }
    return response.json();
  }

  async function flushBacklog() {
    const backlog = loadBacklog();
    if (!backlog.length) {
      return;
    }
    try {
      await postIngest(backlog);
      saveBacklog([]);
    } catch {
      saveBacklog(backlog);
    }
  }

  function mapEventForView(stored) {
    const event = stored && stored.event && typeof stored.event === "object" ? stored.event : {};
    const kind = String(event.kind || "unknown");
    const details = event.details && typeof event.details === "object" ? event.details : {};
    const isGap = kind.startsWith("observability_gap.");
    return {
      kind,
      isGap,
      severity: String(event.severity || "info"),
      message: String(event.msg || event.message || ""),
      details: {
        what: redactIfSensitive(details.what || "none"),
        where: redactIfSensitive(details.where || "none"),
        why: redactIfSensitive(details.why || "none"),
        action_ref: redactIfSensitive(event.action_ref || details.action_ref || "none"),
        trace_id: redactIfSensitive(event.trace_id || details.trace_id || "none"),
      },
    };
  }

  function renderEvents(snapshotEvents) {
    if (!eventsListEl) {
      return;
    }
    eventsListEl.innerHTML = "";
    const items = Array.isArray(snapshotEvents) ? snapshotEvents.slice(-25).reverse() : [];
    for (const stored of items) {
      const view = mapEventForView(stored);
      const li = document.createElement("li");
      if (view.isGap) {
        li.classList.add("gap");
      }
      const kindTag = `<span class="tag ${view.isGap ? "gap" : ""}">${view.isGap ? "⚠" : "•"} ${view.kind}</span>`;
      const sevTag = `<span class="tag">${view.severity}</span>`;
      const msg = `<div>${view.message || "-"}</div>`;
      const tooltip = `${view.details.what} | ${view.details.where} | ${view.details.why} | ${view.details.action_ref} | ${view.details.trace_id}`;
      li.innerHTML = `
        <div>${kindTag}${sevTag}</div>
        ${msg}
        <div class="muted mono" title="${tooltip}">what=${view.details.what}; where=${view.details.where}; why=${view.details.why}; action_ref=${view.details.action_ref}; trace_id=${view.details.trace_id}</div>
      `;
      eventsListEl.appendChild(li);
    }
  }

  function showCoreDown(reasonText) {
    if (coreDownEl) {
      coreDownEl.classList.remove("hidden");
    }
    if (coreDownReasonEl) {
      coreDownReasonEl.textContent = reasonText || "network error";
    }
  }

  function hideCoreDown() {
    if (coreDownEl) {
      coreDownEl.classList.add("hidden");
    }
  }

  async function fetchJson(url) {
    try {
      const response = await fetch(url, { cache: "no-store" });
      const text = await response.text();
      let payload = null;
      try {
        payload = text ? JSON.parse(text) : null;
      } catch {
        payload = null;
      }
      return { ok: response.ok, status: response.status, payload };
    } catch {
      return { ok: false, status: 0, payload: null };
    }
  }

  async function refreshPanel() {
    const health = await fetchJson("/health");
    const snapshot = await fetchJson("/api/v1/snapshot");
    const coreDown =
      !health.ok ||
      health.status === 503 ||
      !snapshot.ok ||
      snapshot.status === 503;
    if (coreDown) {
      const reason = !health.ok
        ? health.status
          ? `HTTP ${health.status}`
          : "network error"
        : !snapshot.ok
          ? snapshot.status
            ? `HTTP ${snapshot.status}`
            : "network error"
          : "network error";
      showCoreDown(reason);
      return;
    }

    hideCoreDown();
    const profileId = snapshot.payload && snapshot.payload.effective_profile_id
      ? String(snapshot.payload.effective_profile_id)
      : "unknown";
    if (profileIdEl) {
      profileIdEl.textContent = profileId;
    }

    const events = snapshot.payload && Array.isArray(snapshot.payload.events)
      ? snapshot.payload.events
      : [];
    renderEvents(events);

    const backlog = loadBacklog();
    if (backlog.length) {
      const enriched = backlog.map((event) => ({
        ...event,
        details: {
          ...normalizeBootEvidence(event.details),
          effective_profile_id: profileId,
        },
      }));
      saveBacklog(enriched);
      await flushBacklog();
    }
  }

  function registerHotkey() {
    addEventListener("keydown", (event) => {
      if (event.ctrlKey && event.shiftKey && String(event.key || "").toLowerCase() === "p") {
        event.preventDefault();
        globalThis.location.assign("/panel0");
      }
    });
  }

  function shouldRegisterServiceWorker() {
    const secure = Boolean(globalThis.isSecureContext);
    const path = String(globalThis.location?.pathname || "");
    return secure && path.startsWith("/panel0");
  }

  async function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) {
      return;
    }
    if (!shouldRegisterServiceWorker()) {
      return;
    }
    try {
      await navigator.serviceWorker.register("/panel0/panel0_sw.js", { scope: "/panel0" });
    } catch {
      // keep panel running even if SW registration fails
    }
  }

  async function boot() {
    await registerServiceWorker();
    await flushBacklog();
    await refreshPanel();
    setInterval(() => {
      void refreshPanel();
    }, 5000);
  }

  if (reloadBtnEl) {
    reloadBtnEl.addEventListener("click", () => {
      globalThis.location.reload();
    });
  }
  registerHotkey();
  void boot();
})();
