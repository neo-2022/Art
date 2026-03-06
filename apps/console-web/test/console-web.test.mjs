import test from "node:test";
import assert from "node:assert/strict";
import { CONSOLE_SURFACES, renderConsoleShell } from "../dist/main.js";

test("console-web: has 7 foundation surfaces", () => {
  assert.equal(CONSOLE_SURFACES.length, 7);
  assert.ok(CONSOLE_SURFACES.some((surface) => surface.id === "command-center"));
  assert.ok(CONSOLE_SURFACES.some((surface) => surface.id === "action-studio"));
});

test("console-web: default locale en and ru switch render", () => {
  const en = renderConsoleShell("en");
  assert.ok(en.includes('lang="en"'));
  assert.ok(en.includes("Incident OS foundation shell"));

  const ru = renderConsoleShell("ru");
  assert.ok(ru.includes('lang="ru"'));
  assert.ok(ru.includes("Базовая оболочка Incident OS"));
});

test("console-web: one-click-to-evidence and tooltip invariants rendered", () => {
  const html = renderConsoleShell("en");
  assert.ok(html.includes("/console/evidence/sample-evidence"));
  assert.ok(html.includes("title=\"Open evidence source\""));
  assert.ok(html.includes("title=\"Open surface\""));
});

test("console-web: analytics memory renders chart-ready data and instructions", () => {
  const html = renderConsoleShell("en");
  assert.ok(html.includes("Analytics Memory"));
  assert.ok(html.includes("data-analytics-chart=\"timeline\""));
  assert.ok(html.includes("data-analytics-instructions"));
});

test("console-web: design controls include reset and guardrails", () => {
  const html = renderConsoleShell("en");
  assert.ok(html.includes("data-settings-search"));
  assert.ok(html.includes("data-profile-select"));
  assert.ok(html.includes("data-profile-save"));
  assert.ok(html.includes("data-profile-apply"));
  assert.ok(html.includes("data-profile-export"));
  assert.ok(html.includes("data-profile-import-file"));
  assert.ok(html.includes("data-profile-status"));
  assert.ok(html.includes("data-design-control=\"palettePreset\""));
  assert.ok(html.includes("data-design-control=\"globalOpacity\""));
  assert.ok(html.includes("data-design-control=\"globalBrightness\""));
  assert.ok(html.includes("data-design-control=\"textOpacity\""));
  assert.ok(html.includes("data-design-control=\"panelOpacity\""));
  assert.ok(html.includes("data-design-control=\"lineOpacity\""));
  assert.ok(html.includes("data-design-control=\"audioEnabled\""));
  assert.ok(html.includes("data-audio-preview=\"ui_click\""));
  assert.ok(html.includes("data-audio-upload=\"alert_error\""));
  assert.ok(html.includes("data-audio-clear=\"action_success\""));
  assert.ok(html.includes("data-design-reset"));
  assert.ok(html.includes("Contrast guardrail"));
  assert.ok(html.includes("generated procedurally"));
});

test("console-web: semantic interaction tokens are present", () => {
  const html = renderConsoleShell("en");
  assert.ok(html.includes("--color-link"));
  assert.ok(html.includes("--color-link-hover"));
  assert.ok(html.includes("--color-btn-primary-bg"));
  assert.ok(html.includes("--color-btn-primary-bg-hover"));
  assert.ok(html.includes("--color-btn-secondary-border"));
  assert.ok(html.includes("--color-focus-ring"));
});
