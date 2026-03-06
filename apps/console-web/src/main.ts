import { buildEvidenceHref } from "@art/evidence-linking";
import { DEFAULT_LOCALE, resolveLocale, translate, type Locale } from "@art/i18n";
import { createLocalStores } from "@art/local-stores";
import { assertEvidenceLink, assertTooltipKey, evaluateRtpTournament } from "@art/ui-laws";
import { createWorkerRuntime } from "@art/worker-runtime";

export interface ConsoleSurface {
  id: string;
  route: string;
  titleKey: string;
}

type PalettePreset = "operational-dark-gold" | "high-contrast" | "light-ops";

interface DesignSettings {
  palettePreset: PalettePreset;
  fontFamily: string;
  fontScale: number;
  lineHeight: number;
  borderRadius: number;
  borderWidth: number;
  globalOpacity: number;
  globalBrightness: number;
  panelOpacity: number;
  textOpacity: number;
  lineOpacity: number;
  bgColor: string;
  textColor: string;
  borderColor: string;
  accentColor: string;
  settingsSearch: string;
  audioEnabled: boolean;
  audioMasterVolume: number;
  audioUiVolume: number;
  audioAlertVolume: number;
  audioMusicVolume: number;
  audioSpatialMode: "off" | "subtle" | "immersive";
  audioBassBoost: number;
  audioTrebleBoost: number;
  audioReverb: number;
  audioCustomByEffect: Record<string, string>;
}

const DESIGN_SETTINGS_STORAGE_KEY = "art.console.design.v0_2";
const SETTINGS_PROFILES_STORAGE_KEY = "art.console.settings.profiles.v0_2";
const SETTINGS_POLICY_LOCKS_STORAGE_KEY = "art.console.settings.policy_locks.v0_2";

const DESIGN_DEFAULTS: DesignSettings = {
  palettePreset: "operational-dark-gold",
  fontFamily: "IBM Plex Sans",
  fontScale: 100,
  lineHeight: 1.45,
  borderRadius: 10,
  borderWidth: 1,
  globalOpacity: 100,
  globalBrightness: 100,
  panelOpacity: 96,
  textOpacity: 100,
  lineOpacity: 78,
  bgColor: "#0A0C0E",
  textColor: "#E8E6E3",
  borderColor: "#4A5058",
  accentColor: "#C6A45C",
  settingsSearch: "",
  audioEnabled: true,
  audioMasterVolume: 75,
  audioUiVolume: 60,
  audioAlertVolume: 78,
  audioMusicVolume: 45,
  audioSpatialMode: "subtle",
  audioBassBoost: 4,
  audioTrebleBoost: 2,
  audioReverb: 12,
  audioCustomByEffect: {}
};

const PALETTE_PRESETS: Record<PalettePreset, Record<string, string>> = {
  "operational-dark-gold": {
    "--color-bg-primary": "#0A0C0E",
    "--color-bg-secondary": "#14181C",
    "--color-bg-tertiary": "#1E2328",
    "--color-surface-elevated": "#1F262C",
    "--color-text-primary": "#E8E6E3",
    "--color-text-secondary": "#9A9A9A",
    "--color-border-subtle": "#2C3138",
    "--color-border-strong": "#4A5058",
    "--color-gold-primary": "#C6A45C",
    "--color-gold-light": "#D8B878",
    "--color-gold-dark": "#B49450",
    "--color-link": "#D8B878",
    "--color-link-hover": "#C6A45C"
  },
  "high-contrast": {
    "--color-bg-primary": "#030303",
    "--color-bg-secondary": "#101010",
    "--color-bg-tertiary": "#171717",
    "--color-surface-elevated": "#1D1D1D",
    "--color-text-primary": "#F8F8F8",
    "--color-text-secondary": "#D0D0D0",
    "--color-border-subtle": "#5A5A5A",
    "--color-border-strong": "#8A8A8A",
    "--color-gold-primary": "#E6C87A",
    "--color-gold-light": "#F2DA9B",
    "--color-gold-dark": "#C5A35D",
    "--color-link": "#F2DA9B",
    "--color-link-hover": "#E6C87A"
  },
  "light-ops": {
    "--color-bg-primary": "#EEF2F6",
    "--color-bg-secondary": "#FFFFFF",
    "--color-bg-tertiary": "#E7ECF1",
    "--color-surface-elevated": "#FFFFFF",
    "--color-text-primary": "#14202B",
    "--color-text-secondary": "#3C4A57",
    "--color-border-subtle": "#CBD4DD",
    "--color-border-strong": "#9FAEBD",
    "--color-gold-primary": "#A98230",
    "--color-gold-light": "#C59D4B",
    "--color-gold-dark": "#8E6D2A",
    "--color-link": "#8E6D2A",
    "--color-link-hover": "#A98230"
  }
};

export const CONSOLE_SURFACES: ConsoleSurface[] = [
  { id: "command-center", route: "/console/command-center", titleKey: "console.surface.command_center" },
  { id: "event-river", route: "/console/event-river", titleKey: "console.surface.event_river" },
  { id: "incident-room", route: "/console/incident-room", titleKey: "console.surface.incident_room" },
  { id: "scenario-view", route: "/console/scenario-view", titleKey: "console.surface.scenario_view" },
  { id: "time-field", route: "/console/time-field", titleKey: "console.surface.time_field" },
  { id: "audit-explorer", route: "/console/audit-explorer", titleKey: "console.surface.audit_explorer" },
  { id: "action-studio", route: "/console/action-studio", titleKey: "console.surface.action_studio" }
];

function renderAnalyticsPanel(
  locale: Locale,
  summary: ReturnType<ReturnType<typeof createLocalStores>["analyticsSummary"]>
): string {
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
    .map((item) => `<li><strong>[${item.priority}] ${item.title}</strong> - ${item.description}</li>`)
    .join("");

  return `<section id="analytics-summary" class="console-card">
    <h2>${title}</h2>
    <p data-analytics-total-events="${totals.total_events}">events=${totals.total_events}, gaps=${totals.gap_events}, gap_rate=${totals.gap_rate_pct}%</p>
    <h3>${chartsTitle}</h3>
    <ul data-analytics-chart="timeline">${timeline}</ul>
    <ul data-analytics-chart="top-kinds">${topKinds}</ul>
    <h3>${instructionsTitle}</h3>
    <ul data-analytics-instructions>${instructions}</ul>
  </section>`;
}

function renderInvestigationLibraryPanel(
  locale: Locale,
  stores: ReturnType<typeof createLocalStores>
): string {
  const labels = locale === "ru"
    ? {
        title: "Investigation Library",
        subtitle: "Базовый цикл: import -> list -> verify -> replay",
        verify: "Проверка",
        replay: "Повтор",
        export: "Экспорт"
      }
    : {
        title: "Investigation Library",
        subtitle: "Baseline cycle: import -> list -> verify -> replay",
        verify: "Verify",
        replay: "Replay",
        export: "Export"
      };

  stores.importInvestigationDoc({
    doc_id: "inv-shell-1",
    version: "v1",
    claims: [{ claim_id: "claim-shell-1", statement: "Shell baseline claim", evidence_refs: ["ev-shell-1"] }],
    decisions: [{ decision_id: "dec-shell-1", text: "Inspect evidence" }],
    actions: [{ action_id: "act-shell-1", kind: "noop" }],
    results: [{ result_id: "res-shell-1", action_id: "act-shell-1" }],
    evidence_refs: ["ev-shell-1"],
    audit_refs: ["aud-shell-1"]
  });
  const items = stores.listInvestigationDocs();
  const first = items[0];
  const verification = first ? stores.verifyInvestigationDoc(first.doc_id) : { ok: false };
  const replay = first ? stores.replayInvestigationDoc(first.doc_id) : { ok: false, steps: [] as string[] };

  return `<section id="investigation-library" class="console-card" data-investigation-library="baseline">
    <h2>${labels.title}</h2>
    <p>${labels.subtitle}</p>
    <p data-investigation-list-count="${items.length}">list=${items.length}</p>
    <p data-investigation-verify="${String(verification.ok)}">${labels.verify}: ${String(verification.ok)}</p>
    <p data-investigation-replay="${String(replay.ok)}">${labels.replay}: ${String(replay.ok)}</p>
    <div class="audio-effect-actions">
      <button class="btn-secondary" type="button" data-investigation-import>${locale === "ru" ? "Импорт" : "Import"}</button>
      <button class="btn-secondary" type="button" data-investigation-export>${labels.export}</button>
      <button class="btn-secondary" type="button" data-investigation-verify-btn>${labels.verify}</button>
      <button class="btn-secondary" type="button" data-investigation-replay-btn>${labels.replay}</button>
      <button class="btn-secondary" type="button" data-audit-verify-trigger="investigation-library">${locale === "ru" ? "Проверить audit chain" : "Verify audit chain"}</button>
    </div>
  </section>`;
}

function renderAuditVerifyPanel(locale: Locale, evidenceHref: string): string {
  const title = translate("console.audit.verify.title", locale);
  const subtitle = translate("console.audit.verify.subtitle", locale);
  const chainLabel = translate("console.audit.verify.chain", locale);
  const statusVerified = translate("console.audit.verify.status.verified", locale);
  const proofChain = [
    "leaf:aud-shell-1",
    "parent:entry_hash",
    "parent:prev_hash",
    "root:sha256-chain-v1"
  ];
  return `<section id="audit-verify-panel" class="console-card" data-audit-verify-panel="true">
    <h2>${title}</h2>
    <p>${subtitle}</p>
    <p data-audit-verify-status="${statusVerified}">status=${statusVerified}</p>
    <p data-audit-verify-source="bootstrap">source=bootstrap</p>
    <h3>${chainLabel}</h3>
    <ol data-audit-proof-chain>
      ${proofChain.map((step) => `<li data-audit-chain-step="${step}">${step}</li>`).join("")}
    </ol>
    <a class="btn-primary" data-audit-lineage-link href="${evidenceHref}">${locale === "ru" ? "К Evidence lineage" : "Open evidence lineage"}</a>
  </section>`;
}

function renderSurfaceNavigation(locale: Locale): string {
  return CONSOLE_SURFACES.map((surface) => {
    assertTooltipKey(surface.id, "console.tooltip.surface");
    const title = translate(surface.titleKey, locale);
    const tooltip = translate("console.tooltip.surface", locale);
    return `<a class="surface-link" data-route="${surface.route}" title="${tooltip}">${title}</a>`;
  }).join("\n");
}

function renderSurfaceSections(locale: Locale): string {
  return CONSOLE_SURFACES.map((surface, index) => {
    const title = translate(surface.titleKey, locale);
    let extras = "";
    if (surface.id === "incident-room") {
      extras = `<button class="btn-secondary" type="button" data-audit-verify-trigger="incident-room">${locale === "ru" ? "Проверить audit chain" : "Verify audit chain"}</button>`;
    }
    if (surface.id === "scenario-view") {
      extras = `<button class="btn-secondary" type="button" data-audit-verify-trigger="flow-mode">${locale === "ru" ? "Flow: Проверить audit chain" : "Flow: Verify audit chain"}</button>`;
    }
    return `<section class="console-card" id="surface-${surface.id}" ${index === 0 ? "" : "hidden"}>
      <h2>${title}</h2>
      <p data-surface-id="${surface.id}">Route: ${surface.route}</p>
      ${extras}
    </section>`;
  }).join("\n");
}

function renderDesignControls(locale: Locale): string {
  const tooltip = translate("console.tooltip.design", locale);
  const paletteLabel = translate("console.design.palette", locale);
  const paletteOperational = translate("console.design.palette.operational_dark_gold", locale);
  const paletteContrast = translate("console.design.palette.high_contrast", locale);
  const paletteLight = translate("console.design.palette.light_ops", locale);
  const effects: Array<{ key: string; labelKey: string; tags: string }> = [
    { key: "ui_click", labelKey: "console.audio.effect.ui_click", tags: "click button action interface" },
    { key: "ui_hover", labelKey: "console.audio.effect.ui_hover", tags: "hover pointer navigation" },
    { key: "surface_open", labelKey: "console.audio.effect.surface_open", tags: "open route surface navigation" },
    { key: "alert_warning", labelKey: "console.audio.effect.alert_warning", tags: "warning alert event" },
    { key: "alert_error", labelKey: "console.audio.effect.alert_error", tags: "error critical incident" },
    { key: "gap_event", labelKey: "console.audio.effect.gap_event", tags: "gap observability incident" },
    { key: "action_success", labelKey: "console.audio.effect.action_success", tags: "success action completed" }
  ];
  const effectRows = effects
    .map(
      (effect) => `<div class="setting-item audio-effect-row" data-setting-item data-setting-tags="${effect.tags}">
      <div class="audio-effect-meta">
        <strong>${translate(effect.labelKey, locale)}</strong>
        <small data-audio-custom-status="${effect.key}">${translate("console.audio.effect.default_active", locale)}</small>
      </div>
      <div class="audio-effect-actions">
        <button class="btn-secondary" type="button" data-audio-preview="${effect.key}">${translate("console.audio.preview", locale)}</button>
        <label class="btn-secondary file-button" title="${tooltip}">
          ${translate("console.audio.replace", locale)}
          <input data-audio-upload="${effect.key}" type="file" accept="audio/*" hidden>
        </label>
        <button class="btn-secondary" type="button" data-audio-clear="${effect.key}">${translate("console.audio.clear", locale)}</button>
      </div>
    </div>`
    )
    .join("");

  return `<aside class="console-card design-panel settings-panel" id="design-controls">
    <h2>${translate("console.design.title", locale)}</h2>
    <p>${translate("console.design.subtitle", locale)}</p>
    <p class="design-guardrail" data-design-status>${translate("console.design.guardrail.ok", locale)}</p>

    <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="search settings design audio accessibility">
      ${translate("console.settings.search", locale)}
      <input data-settings-search type="search" placeholder="${translate("console.settings.search.placeholder", locale)}">
    </label>

    <section class="settings-group" data-settings-group="profiles">
      <h3>${translate("console.settings.group.profiles", locale)}</h3>
      <p class="settings-note">${translate("console.settings.profiles.subtitle", locale)}</p>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="profile preset save apply">
        ${translate("console.settings.profiles.current", locale)}
        <select data-profile-select></select>
      </label>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="profile name save">
        ${translate("console.settings.profiles.name", locale)}
        <input data-profile-name type="text" maxlength="48" placeholder="${translate("console.settings.profiles.name.placeholder", locale)}">
      </label>
      <div class="audio-effect-actions" data-setting-item data-setting-tags="profile save apply delete export import">
        <button class="btn-secondary" type="button" data-profile-save>${translate("console.settings.profiles.save", locale)}</button>
        <button class="btn-secondary" type="button" data-profile-apply>${translate("console.settings.profiles.apply", locale)}</button>
        <button class="btn-secondary" type="button" data-profile-delete>${translate("console.settings.profiles.delete", locale)}</button>
        <button class="btn-secondary" type="button" data-profile-export>${translate("console.settings.profiles.export", locale)}</button>
        <label class="btn-secondary file-button">
          ${translate("console.settings.profiles.import", locale)}
          <input data-profile-import-file type="file" accept="application/json" hidden>
        </label>
      </div>
      <p class="settings-note" data-profile-status>${translate("console.settings.profiles.ready", locale)}</p>
    </section>

    <section class="settings-group" data-settings-group="visual">
      <h3>${translate("console.settings.group.visual", locale)}</h3>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="palette theme color preset">
        ${paletteLabel}
        <select data-design-control="palettePreset">
          <option value="operational-dark-gold">${paletteOperational}</option>
          <option value="high-contrast">${paletteContrast}</option>
          <option value="light-ops">${paletteLight}</option>
        </select>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="font typography family">
        ${translate("console.design.font_family", locale)}
        <select data-design-control="fontFamily">
          <option value="IBM Plex Sans">IBM Plex Sans</option>
          <option value="Manrope">Manrope</option>
          <option value="JetBrains Mono">JetBrains Mono</option>
        </select>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="font scale size">
        ${translate("console.design.font_scale", locale)}
        <input data-design-control="fontScale" type="range" min="85" max="130" step="1">
        <output data-design-output-for="fontScale"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="line height typography">
        ${translate("console.design.line_height", locale)}
        <input data-design-control="lineHeight" type="range" min="1.15" max="1.9" step="0.05">
        <output data-design-output-for="lineHeight"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="border radius corners">
        ${translate("console.design.border_radius", locale)}
        <input data-design-control="borderRadius" type="range" min="0" max="20" step="1">
        <output data-design-output-for="borderRadius"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="border width lines">
        ${translate("console.design.border_width", locale)}
        <input data-design-control="borderWidth" type="range" min="0" max="4" step="1">
        <output data-design-output-for="borderWidth"></output>
      </label>
    </section>

    <section class="settings-group" data-settings-group="opacity">
      <h3>${translate("console.settings.group.opacity", locale)}</h3>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="global opacity transparency">
        ${translate("console.design.global_opacity", locale)}
        <input data-design-control="globalOpacity" type="range" min="70" max="100" step="1">
        <output data-design-output-for="globalOpacity"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="brightness light theme">
        ${translate("console.design.global_brightness", locale)}
        <input data-design-control="globalBrightness" type="range" min="80" max="120" step="1">
        <output data-design-output-for="globalBrightness"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="panel opacity cards">
        ${translate("console.design.panel_opacity", locale)}
        <input data-design-control="panelOpacity" type="range" min="70" max="100" step="1">
        <output data-design-output-for="panelOpacity"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="text opacity contrast">
        ${translate("console.design.text_opacity", locale)}
        <input data-design-control="textOpacity" type="range" min="75" max="100" step="1">
        <output data-design-output-for="textOpacity"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="line opacity borders graphs">
        ${translate("console.design.line_opacity", locale)}
        <input data-design-control="lineOpacity" type="range" min="40" max="100" step="1">
        <output data-design-output-for="lineOpacity"></output>
      </label>
    </section>

    <section class="settings-group" data-settings-group="colors">
      <h3>${translate("console.settings.group.colors", locale)}</h3>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="color background">
        ${translate("console.design.color_bg", locale)}
        <input data-design-control="bgColor" type="color">
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="color text">
        ${translate("console.design.color_text", locale)}
        <input data-design-control="textColor" type="color">
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="color border lines">
        ${translate("console.design.color_border", locale)}
        <input data-design-control="borderColor" type="color">
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="color accent highlight gold">
        ${translate("console.design.color_accent", locale)}
        <input data-design-control="accentColor" type="color">
      </label>
    </section>

    <section class="settings-group" data-settings-group="audio">
      <h3>${translate("console.settings.group.audio", locale)}</h3>
      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio sound enable">
        ${translate("console.audio.enabled", locale)}
        <input data-design-control="audioEnabled" type="checkbox">
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio master volume">
        ${translate("console.audio.master_volume", locale)}
        <input data-design-control="audioMasterVolume" type="range" min="0" max="100" step="1">
        <output data-design-output-for="audioMasterVolume"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio ui volume click hover">
        ${translate("console.audio.ui_volume", locale)}
        <input data-design-control="audioUiVolume" type="range" min="0" max="100" step="1">
        <output data-design-output-for="audioUiVolume"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio alert warning error">
        ${translate("console.audio.alert_volume", locale)}
        <input data-design-control="audioAlertVolume" type="range" min="0" max="100" step="1">
        <output data-design-output-for="audioAlertVolume"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio melody music ambient">
        ${translate("console.audio.music_volume", locale)}
        <input data-design-control="audioMusicVolume" type="range" min="0" max="100" step="1">
        <output data-design-output-for="audioMusicVolume"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio stereo immersive spatial">
        ${translate("console.audio.spatial_mode", locale)}
        <select data-design-control="audioSpatialMode">
          <option value="off">${translate("console.audio.spatial_mode.off", locale)}</option>
          <option value="subtle">${translate("console.audio.spatial_mode.subtle", locale)}</option>
          <option value="immersive">${translate("console.audio.spatial_mode.immersive", locale)}</option>
        </select>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio bass eq low">
        ${translate("console.audio.bass_boost", locale)}
        <input data-design-control="audioBassBoost" type="range" min="-12" max="12" step="1">
        <output data-design-output-for="audioBassBoost"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio treble eq high">
        ${translate("console.audio.treble_boost", locale)}
        <input data-design-control="audioTrebleBoost" type="range" min="-12" max="12" step="1">
        <output data-design-output-for="audioTrebleBoost"></output>
      </label>

      <label class="setting-item" title="${tooltip}" data-setting-item data-setting-tags="audio reverb space room">
        ${translate("console.audio.reverb", locale)}
        <input data-design-control="audioReverb" type="range" min="0" max="60" step="1">
        <output data-design-output-for="audioReverb"></output>
      </label>

      <p class="settings-note">${translate("console.audio.replace.note", locale)}</p>
      <p class="settings-note">${translate("console.audio.legal.note", locale)}</p>
      ${effectRows}
    </section>

    <div class="settings-actions">
      <button class="btn-secondary" type="button" data-design-reset>${translate("console.design.reset", locale)}</button>
    </div>
  </aside>`;
}

function renderTokenCss(): string {
  return `:root {
    /* =========================
       Base Surfaces
       ========================= */
    --color-bg-primary: #0A0C0E;
    --color-bg-secondary: #14181C;
    --color-bg-tertiary: #1E2328;
    --color-surface-elevated: #1F262C;
    --color-overlay-scrim: rgba(0,0,0,0.6);
    --shadow-elevated: 0 8px 20px rgba(0,0,0,0.5);

    /* =========================
       Typography
       ========================= */
    --color-text-primary: #E8E6E3;
    --color-text-secondary: #9A9A9A;
    --color-text-disabled: #5A5A5A;

    /* =========================
       Borders
       ========================= */
    --color-border-subtle: #2C3138;
    --color-border-strong: #4A5058;

    /* =========================
       Brand Gold (raw)
       ========================= */
    --color-gold-primary: #C6A45C;
    --color-gold-light: #D8B878;
    --color-gold-dark: #B49450;
    --color-gold-dim: #665C3A;
    --color-gold-glow: rgba(198,164,92,0.6);

    /* =========================
       States (semantic)
       ========================= */
    --color-success-strong: #5B8C5A;
    --color-success-subtle: rgba(91,140,90,0.15);
    --color-error-strong: #B55A5A;
    --color-error-subtle: rgba(181,90,90,0.15);
    --color-danger-strong: #8E2A2A;
    --color-danger-subtle: rgba(142,42,42,0.2);
    --color-warning-strong: #D97C2B;
    --color-warning-subtle: rgba(217,124,43,0.15);
    --color-info-strong: #5A8CB5;
    --color-info-subtle: rgba(90,140,181,0.15);

    /* =========================
       "On" Colors
       ========================= */
    --color-on-gold: #0A0C0E;
    --color-on-success: #0A0C0E;
    --color-on-warning: #0A0C0E;
    --color-on-info: #0A0C0E;
    --color-on-danger: #E8E6E3;

    /* =========================
       Focus / Dense Lists
       ========================= */
    --color-focus-ring: #D8B878;
    --color-row-hover: rgba(198,164,92,0.08);
    --color-row-selected: rgba(198,164,92,0.14);
    --color-row-active-border: #D8B878;

    /* =========================
       Charts
       ========================= */
    --color-series-1: #5A7C8C;
    --color-series-2: #6A8C7A;
    --color-series-3: #8C7A6A;
    --color-series-4: #7A6A8C;
    --color-series-5: #8C6A7A;
    --color-series-6: #6A8C8C;

    /* =========================
       Interactions (semantic)
       ========================= */
    --color-link: #D8B878;
    --color-link-hover: #C6A45C;
    --color-btn-primary-bg: #C6A45C;
    --color-btn-primary-bg-hover: #D8B878;
    --color-btn-primary-text: #0A0C0E;
    --color-btn-secondary-bg: transparent;
    --color-btn-secondary-border: #4A5058;
    --color-btn-secondary-text: #E8E6E3;

    /* =========================
       3D-specific
       ========================= */
    --color-3d-bg-start: #030405;
    --color-3d-bg-end: #0A0C0E;
    --color-3d-node: rgba(198,164,92,0.7);
    --color-3d-edge: rgba(198,164,92,0.3);
    --color-3d-cloud: rgba(102,92,58,0.15);

    /* User controlled knobs (guardrailed) */
    --ui-font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
    --ui-font-scale: 1;
    --ui-line-height: 1.45;
    --ui-border-radius: 10px;
    --ui-border-width: 1px;
    --ui-global-opacity: 1;
    --ui-global-brightness: 1;
    --ui-panel-opacity: 0.96;
    --ui-text-opacity: 1;
    --ui-line-opacity: 0.78;
  }

  * { box-sizing: border-box; }

  body {
    margin: 0;
    font-family: var(--ui-font-family);
    font-size: calc(16px * var(--ui-font-scale));
    line-height: var(--ui-line-height);
    color: var(--color-text-primary);
    background:
      radial-gradient(circle at 0% 0%, rgba(198,164,92,0.14), transparent 42%),
      radial-gradient(circle at 100% 100%, rgba(90,140,181,0.12), transparent 36%),
      linear-gradient(160deg, var(--color-bg-primary), var(--color-bg-tertiary));
    filter: brightness(var(--ui-global-brightness));
    opacity: var(--ui-global-opacity);
    min-height: 100vh;
  }

  a { color: var(--color-link); }
  a:hover { color: var(--color-link-hover); }
  a:focus-visible, button:focus-visible, select:focus-visible, input:focus-visible {
    outline: 2px solid var(--color-focus-ring);
    outline-offset: 2px;
  }

  .console-shell {
    display: grid;
    gap: 16px;
    padding: 18px;
    grid-template-columns: 1.3fr 1fr;
  }

  .console-header {
    grid-column: 1 / -1;
    background: color-mix(in srgb, var(--color-surface-elevated) 85%, transparent);
    border: var(--ui-border-width) solid var(--color-border-strong);
    border-radius: var(--ui-border-radius);
    box-shadow: var(--shadow-elevated);
    opacity: var(--ui-panel-opacity);
    padding: 16px;
  }

  .console-card {
    background: color-mix(in srgb, var(--color-bg-secondary) 86%, transparent);
    border: var(--ui-border-width) solid var(--color-border-subtle);
    border-radius: var(--ui-border-radius);
    box-shadow: var(--shadow-elevated);
    opacity: var(--ui-panel-opacity);
    padding: 14px;
  }

  .lang-switch { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
  .lang-switch button { min-width: 52px; }

  .btn-primary, .btn-secondary, button {
    border-radius: calc(var(--ui-border-radius) - 2px);
    border: var(--ui-border-width) solid var(--color-btn-secondary-border);
    padding: 8px 12px;
    cursor: pointer;
  }

  .btn-primary {
    background: var(--color-btn-primary-bg);
    color: var(--color-btn-primary-text);
    border-color: var(--color-gold-dark);
    text-decoration: none;
    display: inline-flex;
    align-items: center;
  }

  .btn-primary:hover { background: var(--color-btn-primary-bg-hover); color: var(--color-btn-primary-text); }
  .btn-secondary, button {
    background: var(--color-btn-secondary-bg);
    color: var(--color-btn-secondary-text);
  }

  .main-grid { display: grid; gap: 16px; grid-template-columns: 1fr; }
  .surface-nav { display: grid; gap: 8px; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); }
  .surface-link {
    display: block;
    border: var(--ui-border-width) solid var(--color-border-subtle);
    border-radius: calc(var(--ui-border-radius) - 2px);
    background: color-mix(in srgb, var(--color-bg-tertiary) 88%, transparent);
    color: var(--color-text-primary);
    text-decoration: none;
    padding: 10px 12px;
    opacity: var(--ui-text-opacity);
  }
  .surface-link:hover {
    background: var(--color-row-hover);
    border-color: var(--color-row-active-border);
  }

  .design-panel {
    position: sticky;
    top: 12px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    max-height: calc(100vh - 30px);
    overflow: auto;
  }

  .settings-group {
    display: grid;
    gap: 8px;
    border: var(--ui-border-width) solid var(--color-border-subtle);
    border-radius: calc(var(--ui-border-radius) - 1px);
    padding: 10px;
    background: color-mix(in srgb, var(--color-bg-tertiary) 90%, transparent);
  }

  .settings-group h3 {
    margin: 0;
    font-size: 0.96em;
    color: var(--color-gold-light);
  }

  .setting-item {
    display: grid;
    gap: 6px;
    opacity: var(--ui-text-opacity);
    color: var(--color-text-primary);
  }

  .design-panel output { color: var(--color-text-secondary); opacity: var(--ui-text-opacity); }
  .design-panel input[type="range"] { accent-color: var(--color-gold-primary); opacity: var(--ui-line-opacity); }
  .settings-note { margin: 0; color: var(--color-text-secondary); font-size: 0.9em; }
  .policy-lock-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    margin-left: 6px;
    padding: 1px 6px;
    border-radius: 999px;
    border: 1px solid var(--color-warning-strong);
    background: var(--color-warning-subtle);
    color: var(--color-warning-strong);
    font-size: 0.72em;
    text-transform: uppercase;
    letter-spacing: 0.03em;
  }

  .audio-effect-row {
    grid-template-columns: 1fr;
    gap: 8px;
    border: var(--ui-border-width) solid var(--color-border-subtle);
    border-radius: calc(var(--ui-border-radius) - 3px);
    padding: 8px;
    background: color-mix(in srgb, var(--color-bg-secondary) 80%, transparent);
  }

  .audio-effect-meta small { color: var(--color-text-secondary); }
  .audio-effect-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }
  .file-button { display: inline-flex; align-items: center; justify-content: center; }

  .settings-actions {
    display: flex;
    justify-content: flex-end;
  }

  .settings-panel [hidden] { display: none !important; }

  .design-guardrail {
    margin: 0;
    border-left: 4px solid var(--color-success-strong);
    background: var(--color-success-subtle);
    border-radius: 8px;
    padding: 8px 10px;
  }

  .design-guardrail.is-warning {
    border-left-color: var(--color-warning-strong);
    background: var(--color-warning-subtle);
  }

  #analytics-summary ul { opacity: var(--ui-text-opacity); }
  #analytics-summary li::marker { color: var(--color-gold-primary); opacity: var(--ui-line-opacity); }

  @media (max-width: 1060px) {
    .console-shell { grid-template-columns: 1fr; }
    .design-panel { position: static; max-height: none; }
  }`;
}

function renderDesignScript(locale: Locale): string {
  const contrastWarning = translate("console.design.guardrail.contrast_warning", locale);
  const guardrailOk = translate("console.design.guardrail.ok", locale);
  const customLoaded = translate("console.audio.effect.custom_loaded", locale);
  const defaultActive = translate("console.audio.effect.default_active", locale);
  const audioUnavailable = translate("console.audio.unavailable", locale);
  return `<script>
(function () {
  const STORAGE_KEY = ${JSON.stringify(DESIGN_SETTINGS_STORAGE_KEY)};
  const defaults = ${JSON.stringify(DESIGN_DEFAULTS)};
  const presets = ${JSON.stringify(PALETTE_PRESETS)};
  const fonts = ["IBM Plex Sans", "Manrope", "JetBrains Mono"];
  const guardrailWarningText = ${JSON.stringify(contrastWarning)};
  const guardrailOkText = ${JSON.stringify(guardrailOk)};
  const customLoadedText = ${JSON.stringify(customLoaded)};
  const defaultActiveText = ${JSON.stringify(defaultActive)};
  const audioUnavailableText = ${JSON.stringify(audioUnavailable)};
  const profileReadyText = ${JSON.stringify(translate("console.settings.profiles.ready", locale))};
  const profileSavedText = ${JSON.stringify(translate("console.settings.profiles.saved", locale))};
  const profileAppliedText = ${JSON.stringify(translate("console.settings.profiles.applied", locale))};
  const profileDeletedText = ${JSON.stringify(translate("console.settings.profiles.deleted", locale))};
  const profileImportedText = ${JSON.stringify(translate("console.settings.profiles.imported", locale))};
  const profileExportedText = ${JSON.stringify(translate("console.settings.profiles.exported", locale))};
  const profileLimitText = ${JSON.stringify(translate("console.settings.profiles.limit", locale))};
  const lockBadgeText = ${JSON.stringify(translate("console.settings.policy.locked", locale))};
  const lockHintText = ${JSON.stringify(translate("console.settings.policy.locked_hint", locale))};
  const verifyStatusVerifiedText = ${JSON.stringify(translate("console.audit.verify.status.verified", locale))};
  const verifyStatusFailedText = ${JSON.stringify(translate("console.audit.verify.status.failed", locale))};
  const verifyStatusUnavailableText = ${JSON.stringify(translate("console.audit.verify.status.unavailable", locale))};
  const AUDIO_EFFECTS = ["ui_click", "ui_hover", "surface_open", "alert_warning", "alert_error", "gap_event", "action_success"];
  const PROFILE_LIMIT = 24;
  const PROFILE_STORAGE_KEY = ${JSON.stringify(SETTINGS_PROFILES_STORAGE_KEY)};
  const POLICY_LOCKS_STORAGE_KEY = ${JSON.stringify(SETTINGS_POLICY_LOCKS_STORAGE_KEY)};
  let audioState = null;

  function clamp(value, min, max) {
    const number = Number(value);
    if (Number.isNaN(number)) return min;
    return Math.min(max, Math.max(min, number));
  }

  function normalizeHex(value, fallback) {
    const normalized = String(value || "").trim().toUpperCase();
    if (/^#[0-9A-F]{6}$/.test(normalized)) return normalized;
    if (/^#[0-9A-F]{3}$/.test(normalized)) {
      return "#" + normalized.slice(1).split("").map((ch) => ch + ch).join("");
    }
    return fallback;
  }

  function hexToRgb(hex) {
    const value = normalizeHex(hex, "#000000");
    const parsed = value.slice(1);
    return {
      r: parseInt(parsed.slice(0, 2), 16),
      g: parseInt(parsed.slice(2, 4), 16),
      b: parseInt(parsed.slice(4, 6), 16)
    };
  }

  function relativeLuminance(hex) {
    const rgb = hexToRgb(hex);
    const convert = (channel) => {
      const c = channel / 255;
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * convert(rgb.r) + 0.7152 * convert(rgb.g) + 0.0722 * convert(rgb.b);
  }

  function contrastRatio(background, foreground) {
    const l1 = relativeLuminance(background);
    const l2 = relativeLuminance(foreground);
    const max = Math.max(l1, l2);
    const min = Math.min(l1, l2);
    return (max + 0.05) / (min + 0.05);
  }

  function sanitize(input) {
    const source = input || {};
    const palettePreset = presets[source.palettePreset] ? source.palettePreset : defaults.palettePreset;
    const fontFamily = fonts.includes(source.fontFamily) ? source.fontFamily : defaults.fontFamily;
    const spatialMode = source.audioSpatialMode === "immersive" || source.audioSpatialMode === "subtle" ? source.audioSpatialMode : "off";
    const customByEffect = (source.audioCustomByEffect && typeof source.audioCustomByEffect === "object") ? source.audioCustomByEffect : {};
    const normalizedCustom = {};
    AUDIO_EFFECTS.forEach((key) => {
      const value = customByEffect[key];
      if (typeof value === "string" && value.startsWith("data:audio/")) {
        normalizedCustom[key] = value;
      }
    });

    return {
      palettePreset: palettePreset,
      fontFamily: fontFamily,
      fontScale: clamp(source.fontScale, 85, 130),
      lineHeight: clamp(source.lineHeight, 1.15, 1.9),
      borderRadius: clamp(source.borderRadius, 0, 20),
      borderWidth: clamp(source.borderWidth, 0, 4),
      globalOpacity: clamp(source.globalOpacity, 70, 100),
      globalBrightness: clamp(source.globalBrightness, 80, 120),
      panelOpacity: clamp(source.panelOpacity, 70, 100),
      textOpacity: clamp(source.textOpacity, 75, 100),
      lineOpacity: clamp(source.lineOpacity, 40, 100),
      bgColor: normalizeHex(source.bgColor, defaults.bgColor),
      textColor: normalizeHex(source.textColor, defaults.textColor),
      borderColor: normalizeHex(source.borderColor, defaults.borderColor),
      accentColor: normalizeHex(source.accentColor, defaults.accentColor),
      settingsSearch: String(source.settingsSearch || "").slice(0, 120),
      audioEnabled: Boolean(source.audioEnabled),
      audioMasterVolume: clamp(source.audioMasterVolume, 0, 100),
      audioUiVolume: clamp(source.audioUiVolume, 0, 100),
      audioAlertVolume: clamp(source.audioAlertVolume, 0, 100),
      audioMusicVolume: clamp(source.audioMusicVolume, 0, 100),
      audioSpatialMode: spatialMode,
      audioBassBoost: clamp(source.audioBassBoost, -12, 12),
      audioTrebleBoost: clamp(source.audioTrebleBoost, -12, 12),
      audioReverb: clamp(source.audioReverb, 0, 60),
      audioCustomByEffect: normalizedCustom
    };
  }

  function readStoredSettings() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return sanitize(defaults);
      return sanitize(JSON.parse(raw));
    } catch (_error) {
      return sanitize(defaults);
    }
  }

  function saveSettings(settings) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
    } catch (_error) {
      /* ignore */
    }
  }

  function readProfiles() {
    try {
      const raw = localStorage.getItem(PROFILE_STORAGE_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) return [];
      return parsed
        .filter((item) => item && typeof item.name === "string" && item.name.trim().length > 0)
        .map((item) => ({
          name: item.name.trim().slice(0, 48),
          updated_at: typeof item.updated_at === "string" ? item.updated_at : new Date().toISOString(),
          settings: sanitize(item.settings || {})
        }));
    } catch (_error) {
      return [];
    }
  }

  function writeProfiles(profiles) {
    try {
      localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(profiles));
    } catch (_error) {
      /* ignore */
    }
  }

  function readPolicyLocks() {
    try {
      const raw = localStorage.getItem(POLICY_LOCKS_STORAGE_KEY);
      if (!raw) return {};
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== "object") return {};
      const result = {};
      Object.keys(parsed).forEach((key) => {
        if (parsed[key]) {
          result[key] = true;
        }
      });
      return result;
    } catch (_error) {
      return {};
    }
  }

  function applyPalette(settings, root) {
    const preset = presets[settings.palettePreset] || presets[defaults.palettePreset];
    Object.entries(preset).forEach(([token, value]) => root.style.setProperty(token, value));
    root.style.setProperty("--color-bg-primary", settings.bgColor);
    root.style.setProperty("--color-text-primary", settings.textColor);
    root.style.setProperty("--color-border-strong", settings.borderColor);
    root.style.setProperty("--color-gold-primary", settings.accentColor);
    root.style.setProperty("--color-link-hover", settings.accentColor);
    root.style.setProperty("--color-btn-primary-bg", settings.accentColor);
    root.style.setProperty("--color-btn-primary-bg-hover", settings.accentColor);
  }

  function applyKnobs(settings, root) {
    root.style.setProperty("--ui-font-family", '"' + settings.fontFamily + '", "Segoe UI", sans-serif');
    root.style.setProperty("--ui-font-scale", String(settings.fontScale / 100));
    root.style.setProperty("--ui-line-height", String(settings.lineHeight));
    root.style.setProperty("--ui-border-radius", String(settings.borderRadius) + "px");
    root.style.setProperty("--ui-border-width", String(settings.borderWidth) + "px");
    root.style.setProperty("--ui-global-opacity", String(settings.globalOpacity / 100));
    root.style.setProperty("--ui-global-brightness", String(settings.globalBrightness / 100));
    root.style.setProperty("--ui-panel-opacity", String(settings.panelOpacity / 100));
    root.style.setProperty("--ui-text-opacity", String(settings.textOpacity / 100));
    root.style.setProperty("--ui-line-opacity", String(settings.lineOpacity / 100));
  }

  function ensureAudioGraph() {
    if (audioState) {
      return audioState;
    }
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) {
      return null;
    }
    const context = new Ctx();
    const masterGain = context.createGain();
    const lowShelf = context.createBiquadFilter();
    lowShelf.type = "lowshelf";
    lowShelf.frequency.value = 220;
    const highShelf = context.createBiquadFilter();
    highShelf.type = "highshelf";
    highShelf.frequency.value = 3200;
    const delay = context.createDelay();
    delay.delayTime.value = 0.08;
    const reverbGain = context.createGain();
    reverbGain.gain.value = 0;

    lowShelf.connect(highShelf);
    highShelf.connect(masterGain);
    highShelf.connect(delay);
    delay.connect(reverbGain);
    reverbGain.connect(masterGain);
    masterGain.connect(context.destination);

    audioState = { context: context, lowShelf: lowShelf, highShelf: highShelf, delay: delay, reverbGain: reverbGain, masterGain: masterGain };
    return audioState;
  }

  function updateAudioSettings(settings) {
    const graph = ensureAudioGraph();
    if (!graph) {
      return;
    }
    graph.masterGain.gain.value = settings.audioEnabled ? (settings.audioMasterVolume / 100) : 0;
    graph.lowShelf.gain.value = settings.audioBassBoost;
    graph.highShelf.gain.value = settings.audioTrebleBoost;
    graph.reverbGain.gain.value = settings.audioReverb / 100;
  }

  function effectEnvelope(effectKey) {
    if (effectKey === "ui_hover") return { frequencies: [550], duration: 0.04, gain: 0.08, kind: "sine", pan: -0.2 };
    if (effectKey === "surface_open") return { frequencies: [620, 760], duration: 0.14, gain: 0.16, kind: "triangle", pan: 0.15 };
    if (effectKey === "alert_warning") return { frequencies: [370, 330], duration: 0.24, gain: 0.25, kind: "sawtooth", pan: 0 };
    if (effectKey === "alert_error") return { frequencies: [220, 175], duration: 0.32, gain: 0.34, kind: "square", pan: 0 };
    if (effectKey === "gap_event") return { frequencies: [300, 360, 300], duration: 0.26, gain: 0.3, kind: "sawtooth", pan: -0.15 };
    if (effectKey === "action_success") return { frequencies: [660, 784, 988], duration: 0.24, gain: 0.24, kind: "triangle", pan: 0.2 };
    return { frequencies: [620], duration: 0.06, gain: 0.12, kind: "sine", pan: 0 };
  }

  function effectCategoryVolume(settings, effectKey) {
    if (effectKey.startsWith("alert_") || effectKey === "gap_event") return settings.audioAlertVolume / 100;
    if (effectKey.includes("music")) return settings.audioMusicVolume / 100;
    return settings.audioUiVolume / 100;
  }

  function playSynth(effectKey, settings) {
    const graph = ensureAudioGraph();
    if (!graph) return;
    if (!settings.audioEnabled || settings.audioMasterVolume <= 0) return;
    const context = graph.context;
    if (context.state === "suspended") {
      context.resume().catch(() => {});
    }
    const cfg = effectEnvelope(effectKey);
    const oscillator = context.createOscillator();
    oscillator.type = cfg.kind;
    oscillator.frequency.value = cfg.frequencies[0];
    const gain = context.createGain();
    const now = context.currentTime;
    const targetGain = cfg.gain * effectCategoryVolume(settings, effectKey);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(Math.max(targetGain, 0.0001), now + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + cfg.duration);
    if (cfg.frequencies.length > 1) {
      const step = cfg.duration / cfg.frequencies.length;
      cfg.frequencies.forEach((freq, index) => {
        oscillator.frequency.setValueAtTime(freq, now + index * step);
      });
    }

    const panner = context.createStereoPanner();
    let pan = cfg.pan;
    if (settings.audioSpatialMode === "immersive") {
      pan = Math.max(-1, Math.min(1, pan * 2));
    } else if (settings.audioSpatialMode === "off") {
      pan = 0;
    }
    panner.pan.value = pan;
    oscillator.connect(gain);
    gain.connect(panner);
    panner.connect(graph.lowShelf);
    oscillator.start(now);
    oscillator.stop(now + cfg.duration + 0.01);
  }

  function playCustom(customDataUrl, effectKey, settings) {
    if (!settings.audioEnabled || settings.audioMasterVolume <= 0) return;
    try {
      const audio = new Audio(customDataUrl);
      audio.volume = Math.min(1, (settings.audioMasterVolume / 100) * effectCategoryVolume(settings, effectKey));
      audio.playbackRate = settings.audioSpatialMode === "immersive" ? 1.02 : 1;
      void audio.play();
    } catch (_error) {
      playSynth(effectKey, settings);
    }
  }

  function playEffect(effectKey, settings) {
    const custom = settings.audioCustomByEffect && settings.audioCustomByEffect[effectKey];
    if (custom) {
      playCustom(custom, effectKey, settings);
      return;
    }
    playSynth(effectKey, settings);
  }

  function updateGuardrail(settings, root) {
    const status = document.querySelector("[data-design-status]");
    if (!status) return;
    const ratio = contrastRatio(settings.bgColor, settings.textColor);
    if (ratio < 4.5) {
      const fallbackText = (presets[settings.palettePreset] || presets[defaults.palettePreset])["--color-text-primary"] || defaults.textColor;
      root.style.setProperty("--color-text-primary", fallbackText);
      status.textContent = guardrailWarningText + " (" + ratio.toFixed(2) + ")";
      status.classList.add("is-warning");
      return;
    }
    status.textContent = guardrailOkText + " (" + ratio.toFixed(2) + ")";
    status.classList.remove("is-warning");
  }

  function writeOutputs(settings) {
    Object.entries(settings).forEach(([key, value]) => {
      const output = document.querySelector('[data-design-output-for="' + key + '"]');
      if (!output) return;
      output.textContent = String(value);
    });
    AUDIO_EFFECTS.forEach((key) => {
      const status = document.querySelector('[data-audio-custom-status="' + key + '"]');
      if (!status) return;
      status.textContent = settings.audioCustomByEffect[key] ? customLoadedText : defaultActiveText;
    });
  }

  function setControls(settings) {
    const controls = document.querySelectorAll("[data-design-control]");
    controls.forEach((element) => {
      const key = element.getAttribute("data-design-control");
      if (!key || !(key in settings)) return;
      if (element.type === "checkbox") {
        element.checked = Boolean(settings[key]);
      } else {
        element.value = String(settings[key]);
      }
    });
    const search = document.querySelector("[data-settings-search]");
    if (search) {
      search.value = settings.settingsSearch || "";
    }
    writeOutputs(settings);
  }

  function setProfileStatus(message) {
    const status = document.querySelector("[data-profile-status]");
    if (!status) return;
    status.textContent = message;
  }

  function refreshProfileSelect(profiles) {
    const select = document.querySelector("[data-profile-select]");
    if (!select) return;
    const currentValue = select.value;
    select.innerHTML = "";
    profiles.forEach((profile) => {
      const option = document.createElement("option");
      option.value = profile.name;
      option.textContent = profile.name + " (" + profile.updated_at.slice(0, 10) + ")";
      select.appendChild(option);
    });
    if (profiles.length === 0) {
      const option = document.createElement("option");
      option.value = "";
      option.textContent = "-";
      select.appendChild(option);
    }
    if ([...select.options].some((opt) => opt.value === currentValue)) {
      select.value = currentValue;
    }
  }

  function applyPolicyLocks(locks) {
    const controls = document.querySelectorAll("[data-design-control]");
    controls.forEach((element) => {
      const key = element.getAttribute("data-design-control");
      const isLocked = Boolean(key && locks[key]);
      element.disabled = isLocked;
      const host = element.closest(".setting-item");
      if (!host) return;
      let badge = host.querySelector(".policy-lock-badge");
      if (isLocked && !badge) {
        badge = document.createElement("span");
        badge.className = "policy-lock-badge";
        badge.textContent = lockBadgeText;
        host.querySelector("label, span, strong")?.appendChild?.(badge);
        if (!host.querySelector(".policy-lock-badge")) {
          host.appendChild(badge);
        }
      }
      if (isLocked) {
        host.setAttribute("title", lockHintText);
      } else {
        if (badge) badge.remove();
        host.removeAttribute("title");
      }
    });
  }

  function applySettingsSearch(settings) {
    const query = String(settings.settingsSearch || "").trim().toLowerCase();
    const items = document.querySelectorAll("[data-setting-item]");
    const groups = document.querySelectorAll("[data-settings-group]");
    items.forEach((item) => {
      if (!query) {
        item.hidden = false;
        return;
      }
      const tags = String(item.getAttribute("data-setting-tags") || "").toLowerCase();
      const text = String(item.textContent || "").toLowerCase();
      item.hidden = !(tags.includes(query) || text.includes(query));
    });
    groups.forEach((group) => {
      const visibleChildren = group.querySelectorAll("[data-setting-item]:not([hidden])").length;
      group.hidden = visibleChildren === 0;
    });
  }

  function apply(settings) {
    const root = document.documentElement;
    applyPalette(settings, root);
    applyKnobs(settings, root);
    updateGuardrail(settings, root);
    updateAudioSettings(settings);
    applySettingsSearch(settings);
    writeOutputs(settings);
    saveSettings(settings);
  }

  let profiles = readProfiles();
  const policyLocks = readPolicyLocks();
  let activeSettings = readStoredSettings();
  setControls(activeSettings);
  refreshProfileSelect(profiles);
  applyPolicyLocks(policyLocks);
  setProfileStatus(profileReadyText);
  apply(activeSettings);

  document.addEventListener("input", function (event) {
    const target = event.target;
    if (!target) return;
    if (target.matches("[data-settings-search]")) {
      activeSettings = sanitize(Object.assign({}, activeSettings, { settingsSearch: target.value }));
      apply(activeSettings);
      return;
    }
    if (!target.matches("[data-design-control]")) return;
    const key = target.getAttribute("data-design-control");
    if (!key) return;
    const value = target.type === "checkbox" ? target.checked : target.value;
    activeSettings = sanitize(Object.assign({}, activeSettings, { [key]: value }));
    apply(activeSettings);
  });

  document.addEventListener("click", function (event) {
    const target = event.target;
    if (!target) return;
    const verifySource = target.getAttribute && target.getAttribute("data-audit-verify-trigger");
    if (verifySource) {
      const panel = document.querySelector("[data-audit-verify-panel]");
      const statusNode = document.querySelector("[data-audit-verify-status]");
      const sourceNode = document.querySelector("[data-audit-verify-source]");
      if (panel) {
        panel.scrollIntoView({ behavior: "auto", block: "start" });
      }
      if (statusNode) {
        statusNode.setAttribute("data-audit-verify-status", verifyStatusVerifiedText);
        statusNode.textContent = "status=" + verifyStatusVerifiedText;
      }
      if (sourceNode) {
        sourceNode.setAttribute("data-audit-verify-source", verifySource);
        sourceNode.textContent = "source=" + verifySource;
      }
      playEffect("action_success", activeSettings);
      return;
    }
    const previewKey = target.getAttribute && target.getAttribute("data-audio-preview");
    if (previewKey) {
      playEffect(previewKey, activeSettings);
      return;
    }
    const clearKey = target.getAttribute && target.getAttribute("data-audio-clear");
    if (clearKey) {
      const nextCustom = Object.assign({}, activeSettings.audioCustomByEffect);
      delete nextCustom[clearKey];
      activeSettings = sanitize(Object.assign({}, activeSettings, { audioCustomByEffect: nextCustom }));
      apply(activeSettings);
      return;
    }

    if (target.matches("button, a.surface-link")) {
      playEffect("ui_click", activeSettings);
    }
  });

  document.addEventListener("mouseover", function (event) {
    const target = event.target;
    if (!target || !target.matches || !target.matches(".surface-link")) return;
    playEffect("ui_hover", activeSettings);
  });

  document.addEventListener("change", function (event) {
    const target = event.target;
    if (!target || !target.matches || !target.matches("[data-audio-upload]")) return;
    const effectKey = target.getAttribute("data-audio-upload");
    const file = target.files && target.files[0];
    if (!effectKey || !file) return;
    if (!file.type.startsWith("audio/")) {
      const status = document.querySelector('[data-audio-custom-status="' + effectKey + '"]');
      if (status) {
        status.textContent = audioUnavailableText;
      }
      return;
    }
    const reader = new FileReader();
    reader.onload = function () {
      const dataUrl = typeof reader.result === "string" ? reader.result : "";
      if (!dataUrl.startsWith("data:audio/")) {
        return;
      }
      const nextCustom = Object.assign({}, activeSettings.audioCustomByEffect, { [effectKey]: dataUrl });
      activeSettings = sanitize(Object.assign({}, activeSettings, { audioCustomByEffect: nextCustom }));
      apply(activeSettings);
      playEffect(effectKey, activeSettings);
    };
    reader.readAsDataURL(file);
  });

  const resetButton = document.querySelector("[data-design-reset]");
  if (resetButton) {
    resetButton.addEventListener("click", function () {
      activeSettings = sanitize(defaults);
      setControls(activeSettings);
      apply(activeSettings);
      setProfileStatus(profileReadyText);
    });
  }

  const profileSave = document.querySelector("[data-profile-save]");
  if (profileSave) {
    profileSave.addEventListener("click", function () {
      const nameInput = document.querySelector("[data-profile-name]");
      const profileName = String(nameInput?.value || "").trim();
      if (!profileName) {
        setProfileStatus(profileReadyText);
        return;
      }
      const now = new Date().toISOString();
      const idx = profiles.findIndex((profile) => profile.name === profileName);
      if (idx >= 0) {
        profiles[idx] = { name: profileName, updated_at: now, settings: sanitize(activeSettings) };
      } else {
        if (profiles.length >= PROFILE_LIMIT) {
          setProfileStatus(profileLimitText);
          return;
        }
        profiles.push({ name: profileName, updated_at: now, settings: sanitize(activeSettings) });
      }
      writeProfiles(profiles);
      refreshProfileSelect(profiles);
      const select = document.querySelector("[data-profile-select]");
      if (select) select.value = profileName;
      setProfileStatus(profileSavedText + ": " + profileName);
    });
  }

  const profileApply = document.querySelector("[data-profile-apply]");
  if (profileApply) {
    profileApply.addEventListener("click", function () {
      const select = document.querySelector("[data-profile-select]");
      const profileName = String(select?.value || "").trim();
      const selected = profiles.find((profile) => profile.name === profileName);
      if (!selected) {
        setProfileStatus(profileReadyText);
        return;
      }
      activeSettings = sanitize(selected.settings);
      setControls(activeSettings);
      apply(activeSettings);
      setProfileStatus(profileAppliedText + ": " + profileName);
    });
  }

  const profileDelete = document.querySelector("[data-profile-delete]");
  if (profileDelete) {
    profileDelete.addEventListener("click", function () {
      const select = document.querySelector("[data-profile-select]");
      const profileName = String(select?.value || "").trim();
      if (!profileName) {
        setProfileStatus(profileReadyText);
        return;
      }
      profiles = profiles.filter((profile) => profile.name !== profileName);
      writeProfiles(profiles);
      refreshProfileSelect(profiles);
      setProfileStatus(profileDeletedText + ": " + profileName);
    });
  }

  const profileExport = document.querySelector("[data-profile-export]");
  if (profileExport) {
    profileExport.addEventListener("click", function () {
      const select = document.querySelector("[data-profile-select]");
      const profileName = String(select?.value || "").trim();
      const selected = profiles.find((profile) => profile.name === profileName);
      if (!selected) {
        setProfileStatus(profileReadyText);
        return;
      }
      const blob = new Blob([JSON.stringify(selected, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "art-settings-profile-" + profileName.replace(/[^a-z0-9_-]+/gi, "_") + ".json";
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
      setProfileStatus(profileExportedText + ": " + profileName);
    });
  }

  const profileImport = document.querySelector("[data-profile-import-file]");
  if (profileImport) {
    profileImport.addEventListener("change", function () {
      const file = profileImport.files && profileImport.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = function () {
        try {
          const parsed = JSON.parse(String(reader.result || "{}"));
          const name = String(parsed.name || "").trim().slice(0, 48);
          if (!name) {
            setProfileStatus(profileReadyText);
            return;
          }
          const now = new Date().toISOString();
          const payload = { name: name, updated_at: now, settings: sanitize(parsed.settings || parsed) };
          const idx = profiles.findIndex((profile) => profile.name === name);
          if (idx >= 0) {
            profiles[idx] = payload;
          } else {
            if (profiles.length >= PROFILE_LIMIT) {
              setProfileStatus(profileLimitText);
              return;
            }
            profiles.push(payload);
          }
          writeProfiles(profiles);
          refreshProfileSelect(profiles);
          const select = document.querySelector("[data-profile-select]");
          if (select) select.value = name;
          setProfileStatus(profileImportedText + ": " + name);
        } catch (_error) {
          setProfileStatus(profileReadyText);
        }
      };
      reader.readAsText(file);
    });
  }
})();
</script>`;
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
  const rtpVerdict = evaluateRtpTournament(
    {
      claim_id: "claim-console-shell",
      statement: "Sample claim",
      proof_set: ["ev-a"],
      evidence_refs: ["ev-a"],
      meta: {
        truth_mode: "observed",
        evidence_refs: ["ev-a"]
      }
    },
    [
      { refuter_id: "r1", status: "pass", reason: "baseline stable", evidence_refs: ["ev-a"] },
      { refuter_id: "r2", status: "contested", reason: "counter signal", evidence_refs: ["ev-b"] }
    ]
  );
  const promotionBlocked = rtpVerdict.verdict === "contested" ? "true" : "false";

  const title = translate("console.title", locale);
  const subtitle = translate("console.subtitle", locale);
  const langSwitchLabel = translate("console.locale.switch", locale);
  const evidenceTooltip = translate("console.tooltip.evidence", locale);
  const auditEvidenceHref = buildEvidenceHref("audit-proof-chain");

  return `<!doctype html>
<html lang="${locale}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${title}</title>
    <style>${renderTokenCss()}</style>
  </head>
  <body>
    <div class="console-shell">
      <header class="console-header">
        <h1>${title}</h1>
        <p>${subtitle}</p>
        <div class="lang-switch">
          <span>${langSwitchLabel}:</span>
          <button class="btn-secondary" type="button" title="${langSwitchLabel}" data-locale="en">EN</button>
          <button class="btn-secondary" type="button" title="${langSwitchLabel}" data-locale="ru">RU</button>
          <a class="btn-primary" href="${evidenceHref}" title="${evidenceTooltip}">One-click to evidence</a>
        </div>
        <p data-rtp-verdict="${rtpVerdict.verdict}">
          RTP verdict: ${rtpVerdict.verdict} (${rtpVerdict.contested_count} contested)
        </p>
        <p data-rtp-promotion-guard="${promotionBlocked}">
          contested claim promotion blocked: ${promotionBlocked}
        </p>
      </header>

      <main class="main-grid">
        <section class="console-card">
          <h2>${translate("console.surface.command_center", locale)}</h2>
          <nav class="surface-nav">
            ${renderSurfaceNavigation(locale)}
          </nav>
        </section>
        ${renderSurfaceSections(locale)}
        ${renderAnalyticsPanel(locale, analyticsSummary)}
        ${renderInvestigationLibraryPanel(locale, stores)}
        ${renderAuditVerifyPanel(locale, auditEvidenceHref)}
      </main>

      ${renderDesignControls(locale)}
    </div>
    ${renderDesignScript(locale)}
  </body>
</html>`;
}
