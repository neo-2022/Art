const GAP_PREFIX = "observability_gap.";
const REDACT_PATTERNS = [
  /authorization/i,
  /cookie/i,
  /token/i,
  /secret/i,
  /password/i,
  /set-cookie/i,
];

export const panel0LocaleConfig = {
  defaultLocale: "en",
  supportedLocales: ["en", "ru"],
  storageKey: "art.panel0.locale.v1",
};

const PANEL0_MESSAGES = {
  en: {
    "panel0.core_down": "Core is unavailable",
    "panel0.evidence_link": "View evidence",
  },
  ru: {
    "panel0.core_down": "Core недоступен",
    "panel0.evidence_link": "Открыть evidence",
  },
};

export function panel0Message(key, locale = panel0LocaleConfig.defaultLocale) {
  const normalized = String(locale || "").toLowerCase().startsWith("ru") ? "ru" : "en";
  return (
    PANEL0_MESSAGES[normalized]?.[key] ??
    PANEL0_MESSAGES[panel0LocaleConfig.defaultLocale][key] ??
    key
  );
}

export function panel0EvidenceHref(evidenceId) {
  return `/panel0/?evidence_id=${encodeURIComponent(String(evidenceId || ""))}#panel0-evidence`;
}

export function sanitizeTooltipValue(value) {
  if (value == null) {
    return "none";
  }
  const text = String(value);
  if (REDACT_PATTERNS.some((re) => re.test(text))) {
    return "***redacted***";
  }
  return text;
}

export function gapStyleForEvent(event) {
  const kind = event?.kind ?? event?.event?.kind ?? "unknown";
  if (!kind.startsWith(GAP_PREFIX)) {
    return null;
  }
  const details = event?.details ?? event?.event?.details ?? {};
  return {
    icon: "⚠",
    color: "amber",
    tooltip: {
      kind,
      what: sanitizeTooltipValue(details.what ?? "none"),
      where: sanitizeTooltipValue(details.where ?? "none"),
      why: sanitizeTooltipValue(details.why ?? "none"),
      action_ref: sanitizeTooltipValue(details?.actions?.action_ref ?? "none"),
      trace_id: sanitizeTooltipValue(details.trace_id ?? "none"),
    },
  };
}

function unavailableByStatus(resp) {
  if (!resp) return false;
  if (resp.networkError) return true;
  return Number(resp.status) === 503;
}

export function evaluateCoreAvailability({ health, snapshot }) {
  if (unavailableByStatus(health)) {
    return {
      coreDown: true,
      reason: health?.networkError ? "network error" : `HTTP ${health?.status ?? "503"}`,
    };
  }
  if (unavailableByStatus(snapshot)) {
    return {
      coreDown: true,
      reason: snapshot?.networkError ? "network error" : `HTTP ${snapshot?.status ?? "503"}`,
    };
  }
  return { coreDown: false, reason: "" };
}

export function panel0Diagnostics(snapshotPayload, buildId) {
  return {
    build_id: buildId || "dev",
    effective_profile_id: String(snapshotPayload?.effective_profile_id || "unknown"),
  };
}

export const panel0Config = {
  buildIdEnv: "PANEL0_BUILD_ID",
  defaultLocale: panel0LocaleConfig.defaultLocale,
};
