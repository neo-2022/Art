import test from "node:test";
import assert from "node:assert/strict";
import {
  assertClaimHasEvidence,
  assertEvidenceLink,
  assertTooltipKey
} from "../dist/index.js";

test("ui-laws: claim requires evidence refs", () => {
  assert.throws(
    () => assertClaimHasEvidence({ claim_id: "c1", statement: "x", proof_set: ["p1"] }),
    /missing evidence_refs/
  );

  assert.doesNotThrow(() =>
    assertClaimHasEvidence({
      claim_id: "c2",
      statement: "x",
      proof_set: ["p1"],
      evidence_refs: ["ev1"]
    })
  );
});

test("ui-laws: tooltip key is mandatory", () => {
  assert.throws(() => assertTooltipKey("", "console.tooltip.surface"), /tooltip key required/);
  assert.doesNotThrow(() => assertTooltipKey("surface.command_center", "console.tooltip.surface"));
});

test("ui-laws: evidence link format", () => {
  assert.throws(() => assertEvidenceLink("/bad/path"), /invalid evidence link/);
  assert.doesNotThrow(() => assertEvidenceLink("/console/evidence/evidence-1"));
});
