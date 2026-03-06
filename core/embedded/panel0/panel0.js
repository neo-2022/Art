(function panel0Main() {
  const PANEL0_BUILD_ID = "__PANEL0_BUILD_ID__";
  const BACKLOG_KEY = "art.panel0.console_boot_failed.backlog.v1";
  const BACKLOG_MAX = 64;
  const BOOT_EVENT_KIND = "observability_gap.console_boot_failed";
  const LOCALE_KEY = "art.panel0.locale.v1";
  const DEFAULT_LOCALE = "en";
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
  const I18N = {
    en: {
      "panel0.title": "Art Panel0",
      "panel0.subtitle": "Embedded emergency panel for Core",
      "panel0.build_id_label": "build_id:",
      "panel0.profile_id_label": "effective_profile_id:",
      "panel0.language_label": "Language:",
      "panel0.switch_language": "Switch language",
      "panel0.core_down_title": "Core is unavailable",
      "panel0.reload": "Reload",
      "panel0.reload_tooltip": "Reload panel state",
      "panel0.events_title": "Events",
      "panel0.evidence_title": "Evidence payload",
      "panel0.evidence_link": "View evidence",
      "panel0.evidence_tooltip": "Open evidence payload for this event",
      "panel0.network_error": "network error",
    },
    ru: {
      "panel0.title": "Art Panel0",
      "panel0.subtitle": "Embedded аварийная панель Core",
      "panel0.build_id_label": "build_id:",
      "panel0.profile_id_label": "effective_profile_id:",
      "panel0.language_label": "Язык:",
      "panel0.switch_language": "Сменить язык",
      "panel0.core_down_title": "Core недоступен",
      "panel0.reload": "Перезагрузить",
      "panel0.reload_tooltip": "Перезагрузить состояние панели",
      "panel0.events_title": "События",
      "panel0.evidence_title": "Evidence payload",
      "panel0.evidence_link": "Открыть evidence",
      "panel0.evidence_tooltip": "Открыть payload доказательства для события",
      "panel0.network_error": "network error",
    },
  };

  const buildIdEl = document.getElementById("build-id");
  const profileIdEl = document.getElementById("profile-id");
  const coreDownEl = document.getElementById("core-down");
  const coreDownReasonEl = document.getElementById("core-down-reason");
  const eventsListEl = document.getElementById("events-list");
  const evidenceJsonEl = document.getElementById("evidence-json");
  const reloadBtnEl = document.getElementById("reload-btn");
  const langButtons = Array.from(document.querySelectorAll("[data-locale]"));

  let latestSnapshotEvents = [];
  let lastCoreDownReasonRaw = "network error";
  let currentLocale = resolveLocale(
    globalThis.localStorage?.getItem(LOCALE_KEY) ||
      document.documentElement.lang ||
      globalThis.navigator?.language
  );

  if (buildIdEl) {
    buildIdEl.textContent = PANEL0_BUILD_ID || "dev";
  }

  function resolveLocale(input) {
    const value = String(input || "").trim().toLowerCase();
    if (value.startsWith("ru")) {
      return "ru";
    }
    return DEFAULT_LOCALE;
  }

  function t(key) {
    const table = I18N[currentLocale] || I18N[DEFAULT_LOCALE];
    return table[key] || I18N[DEFAULT_LOCALE][key] || key;
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

  function applyLocale() {
    document.documentElement.lang = currentLocale;
    const nodes = Array.from(document.querySelectorAll("[data-i18n]"));
    for (const node of nodes) {
      const key = node.getAttribute("data-i18n");
      if (!key) {
        continue;
      }
      node.textContent = t(key);
    }
    const titleNodes = Array.from(document.querySelectorAll("[data-i18n-title]"));
    for (const node of titleNodes) {
      const key = node.getAttribute("data-i18n-title");
      if (!key) {
        continue;
      }
      node.setAttribute("title", t(key));
    }
    if (coreDownEl && !coreDownEl.classList.contains("hidden")) {
      coreDownReasonEl.textContent = formatCoreDownReason(lastCoreDownReasonRaw);
    }
  }

  function setLocale(locale) {
    currentLocale = resolveLocale(locale);
    try {
      globalThis.localStorage?.setItem(LOCALE_KEY, currentLocale);
    } catch {
      // ignore storage errors
    }
    applyLocale();
    renderEvents(latestSnapshotEvents);
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
      details,
      normalized: {
        what: redactIfSensitive(details.what || "none"),
        where: redactIfSensitive(details.where || "none"),
        why: redactIfSensitive(details.why || "none"),
        action_ref: redactIfSensitive(event.action_ref || details.action_ref || "none"),
        trace_id: redactIfSensitive(event.trace_id || details.trace_id || "none"),
      },
    };
  }

  function showEvidence(kind, details) {
    if (!evidenceJsonEl) {
      return;
    }
    evidenceJsonEl.textContent = JSON.stringify(
      {
        kind,
        details,
      },
      null,
      2
    );
    const anchor = document.getElementById("panel0-evidence");
    if (anchor) {
      anchor.scrollIntoView({ block: "start", behavior: "smooth" });
    }
  }

  function renderEvents(snapshotEvents) {
    if (!eventsListEl) {
      return;
    }
    eventsListEl.innerHTML = "";
    const items = Array.isArray(snapshotEvents) ? snapshotEvents.slice(-25).reverse() : [];
    latestSnapshotEvents = items;
    for (const stored of items) {
      const view = mapEventForView(stored);
      const li = document.createElement("li");
      if (view.isGap) {
        li.classList.add("gap");
      }

      const tags = document.createElement("div");
      const kindTag = document.createElement("span");
      kindTag.className = `tag ${view.isGap ? "gap" : ""}`;
      kindTag.textContent = `${view.isGap ? "⚠" : "•"} ${view.kind}`;
      const sevTag = document.createElement("span");
      sevTag.className = "tag";
      sevTag.textContent = view.severity;
      tags.appendChild(kindTag);
      tags.appendChild(sevTag);

      const msg = document.createElement("div");
      msg.textContent = view.message || "-";

      const detail = document.createElement("div");
      detail.className = "muted mono";
      const tooltip = `${view.normalized.what} | ${view.normalized.where} | ${view.normalized.why} | ${view.normalized.action_ref} | ${view.normalized.trace_id}`;
      detail.title = tooltip;
      detail.textContent = `what=${view.normalized.what}; where=${view.normalized.where}; why=${view.normalized.why}; action_ref=${view.normalized.action_ref}; trace_id=${view.normalized.trace_id}`;

      li.appendChild(tags);
      li.appendChild(msg);
      li.appendChild(detail);

      if (view.isGap) {
        const evidenceLink = document.createElement("a");
        evidenceLink.className = "evidence-link";
        evidenceLink.href = "#panel0-evidence";
        evidenceLink.textContent = t("panel0.evidence_link");
        evidenceLink.title = t("panel0.evidence_tooltip");
        evidenceLink.addEventListener("click", (event) => {
          event.preventDefault();
          showEvidence(view.kind, view.details);
        });
        li.appendChild(evidenceLink);
      }

      eventsListEl.appendChild(li);
    }
  }

  function formatCoreDownReason(reasonText) {
    const raw = String(reasonText || "").trim();
    if (!raw || raw.toLowerCase() === "network error") {
      return t("panel0.network_error");
    }
    return raw;
  }

  function showCoreDown(reasonText) {
    if (coreDownEl) {
      coreDownEl.classList.remove("hidden");
    }
    lastCoreDownReasonRaw = String(reasonText || "network error");
    if (coreDownReasonEl) {
      coreDownReasonEl.textContent = formatCoreDownReason(lastCoreDownReasonRaw);
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
        globalThis.location.assign("/panel0/");
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
      await navigator.serviceWorker.register("/panel0/panel0_sw.js", { scope: "/panel0/" });
    } catch {
      // keep panel running even if SW registration fails
    }
  }

  function registerLocaleSwitch() {
    for (const button of langButtons) {
      button.addEventListener("click", () => {
        const locale = button.getAttribute("data-locale") || DEFAULT_LOCALE;
        setLocale(locale);
      });
    }
  }

  async function boot() {
    applyLocale();
    registerLocaleSwitch();
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
