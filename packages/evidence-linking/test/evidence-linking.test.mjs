import test from "node:test";
import assert from "node:assert/strict";
import { buildDnaHref, buildEvidenceHref, buildGapEvidenceHref } from "../dist/index.js";

test("evidence-linking: builds canonical links", () => {
  assert.equal(buildEvidenceHref("ev-1"), "/console/evidence/ev-1");
  assert.equal(buildDnaHref("dna/1"), "/console/dna/dna%2F1");
  assert.equal(
    buildGapEvidenceHref("observability_gap.console_boot_failed", "ev 1"),
    "/console/evidence/ev%201?kind=observability_gap.console_boot_failed"
  );
});
