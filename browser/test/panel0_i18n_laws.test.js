import test from "node:test";
import assert from "node:assert/strict";

import {
  panel0Config,
  panel0EvidenceHref,
  panel0LocaleConfig,
  panel0Message,
} from "../src/index.js";

test("panel0-i18n: EN default + RU switch", () => {
  assert.equal(panel0LocaleConfig.defaultLocale, "en");
  assert.equal(panel0Config.defaultLocale, "en");
  assert.equal(panel0Message("panel0.core_down", "en"), "Core is unavailable");
  assert.equal(panel0Message("panel0.core_down", "ru"), "Core недоступен");
});

test("panel0-i18n: one-click-to-evidence href is stable", () => {
  assert.equal(
    panel0EvidenceHref("ev-1"),
    "/panel0/?evidence_id=ev-1#panel0-evidence"
  );
  assert.equal(
    panel0EvidenceHref("ev 2"),
    "/panel0/?evidence_id=ev%202#panel0-evidence"
  );
});
