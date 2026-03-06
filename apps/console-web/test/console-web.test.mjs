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
