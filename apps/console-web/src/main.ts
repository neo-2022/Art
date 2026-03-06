import { buildEvidenceHref } from "@art/evidence-linking";
import { DEFAULT_LOCALE, resolveLocale, translate, type Locale } from "@art/i18n";
import { createLocalStores } from "@art/local-stores";
import { assertEvidenceLink, assertTooltipKey } from "@art/ui-laws";
import { createWorkerRuntime } from "@art/worker-runtime";

export interface ConsoleSurface {
  id: string;
  route: string;
  titleKey: string;
}

export const CONSOLE_SURFACES: ConsoleSurface[] = [
  { id: "command-center", route: "/console/command-center", titleKey: "console.surface.command_center" },
  { id: "event-river", route: "/console/event-river", titleKey: "console.surface.event_river" },
  { id: "incident-room", route: "/console/incident-room", titleKey: "console.surface.incident_room" },
  { id: "scenario-view", route: "/console/scenario-view", titleKey: "console.surface.scenario_view" },
  { id: "time-field", route: "/console/time-field", titleKey: "console.surface.time_field" },
  { id: "audit-explorer", route: "/console/audit-explorer", titleKey: "console.surface.audit_explorer" },
  { id: "action-studio", route: "/console/action-studio", titleKey: "console.surface.action_studio" }
];

function renderAnalyticsPanel(locale: Locale, summary: ReturnType<ReturnType<typeof createLocalStores>["analyticsSummary"]>): string {
  const title = translate("console.analytics.title", locale);
  const chartsTitle = translate("console.analytics.charts", locale);
  const instructionsTitle = translate("console.analytics.instructions", locale);
  const totals = summary.totals;
  const timeline = summary.charts.timeline
    .map((point) => `<li>${new Date(point.minute_ts_ms).toISOString()}: total=${point.total_events}, gap=${point.gap_events}</li>`)
    .join("");
  const topKinds = summary.charts.top_kinds
    .map((item) => `<li>${item.key}: ${item.count} (${item.share_pct}%)</li>`)
    .join("");
  const instructions = summary.instructions
    .map((item) => `<li><strong>[${item.priority}] ${item.title}</strong> — ${item.description}</li>`)
    .join("");

  return `<section id="analytics-summary">
    <h2>${title}</h2>
    <p data-analytics-total-events="${totals.total_events}">events=${totals.total_events}, gaps=${totals.gap_events}, gap_rate=${totals.gap_rate_pct}%</p>
    <h3>${chartsTitle}</h3>
    <ul data-analytics-chart="timeline">${timeline}</ul>
    <ul data-analytics-chart="top-kinds">${topKinds}</ul>
    <h3>${instructionsTitle}</h3>
    <ul data-analytics-instructions>${instructions}</ul>
  </section>`;
}

function renderSurfaceNavigation(locale: Locale): string {
  return CONSOLE_SURFACES.map((surface) => {
    assertTooltipKey(surface.id, "console.tooltip.surface");
    const title = translate(surface.titleKey, locale);
    const tooltip = translate("console.tooltip.surface", locale);
    return `<a data-route="${surface.route}" title="${tooltip}">${title}</a>`;
  }).join("\n");
}

function renderSurfaceSections(locale: Locale): string {
  return CONSOLE_SURFACES.map((surface, index) => {
    const title = translate(surface.titleKey, locale);
    return `<section id="surface-${surface.id}" ${index === 0 ? "" : "hidden"}><h2>${title}</h2><p data-surface-id="${surface.id}">Route: ${surface.route}</p></section>`;
  }).join("\n");
}

export function renderConsoleShell(inputLocale?: string): string {
  const locale = resolveLocale(inputLocale || DEFAULT_LOCALE);
  const evidenceHref = buildEvidenceHref("sample-evidence");
  assertEvidenceLink(evidenceHref);

  const stores = createLocalStores();
  stores.cachePut({
    id: "sample-1",
    dna_id: "dna.sample",
    payload: { source: "console-shell", severity: "error", kind: "db.timeout" }
  });
  stores.recordTelemetry({
    ts_ms: Date.now() - 20_000,
    severity: "warn",
    kind: "cache.degraded",
    dna_id: "dna.sample"
  });
  stores.recordTelemetry({
    ts_ms: Date.now() - 10_000,
    severity: "error",
    kind: "observability_gap.stream_lag",
    is_gap: true
  });
  const analyticsSummary = stores.analyticsSummary(120, 5);
  const runtime = createWorkerRuntime();
  void runtime.runTask({ id: "boot-1", type: "console.boot", payload: { locale } });

  const title = translate("console.title", locale);
  const subtitle = translate("console.subtitle", locale);
  const langSwitchLabel = translate("console.locale.switch", locale);
  const evidenceTooltip = translate("console.tooltip.evidence", locale);

  return `<!doctype html>
<html lang="${locale}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${title}</title>
    <style>
      body { margin: 0; font-family: system-ui, sans-serif; background: #f8fafc; color: #0f172a; }
      header { padding: 20px; border-bottom: 1px solid #cbd5e1; background: #ffffff; }
      nav { display: grid; gap: 8px; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); padding: 20px; }
      nav a { border: 1px solid #cbd5e1; padding: 10px; border-radius: 8px; text-decoration: none; color: inherit; background: #fff; }
      main { padding: 20px; }
      .lang-switch button { margin-right: 8px; }
    </style>
  </head>
  <body>
    <header>
      <h1>${title}</h1>
      <p>${subtitle}</p>
      <div class="lang-switch">
        <span>${langSwitchLabel}:</span>
        <button type="button" title="${langSwitchLabel}" data-locale="en">EN</button>
        <button type="button" title="${langSwitchLabel}" data-locale="ru">RU</button>
      </div>
      <p><a href="${evidenceHref}" title="${evidenceTooltip}">One-click to evidence</a></p>
    </header>
    <nav>
      ${renderSurfaceNavigation(locale)}
    </nav>
    <main>
      ${renderSurfaceSections(locale)}
      ${renderAnalyticsPanel(locale, analyticsSummary)}
    </main>
  </body>
</html>`;
}
