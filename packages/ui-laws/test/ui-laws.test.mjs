import test from "node:test";
import assert from "node:assert/strict";
import {
  assertClaimHasEvidence,
  assertEvidenceLink,
  assertTooltipKey,
  assertTruthMeta,
  assertObservedHasEvidence,
  assertTruthModeBadge,
  assertPredictedNotFact,
  assertSemanticStateToken,
  assertErrorDangerUsage
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
      evidence_refs: ["ev1"],
      meta: {
        truth_mode: "observed",
        evidence_refs: ["ev1"]
      }
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

test("ui-laws: truth meta contract", () => {
  assert.throws(
    () => assertTruthMeta({ truth_mode: "observed", evidence_refs: [] }),
    /requires evidence_refs/
  );
  assert.throws(
    () => assertTruthMeta({ truth_mode: "derived", evidence_refs: ["ev"] }),
    /requires algorithm metadata/
  );
  assert.throws(
    () =>
      assertTruthMeta({
        truth_mode: "predicted",
        evidence_refs: ["ev"],
        predicted: { assumptions: ["a"], confidence: 2 }
      }),
    /confidence in \[0,1\]/
  );

  assert.doesNotThrow(() =>
    assertTruthMeta({
      truth_mode: "derived",
      evidence_refs: ["ev"],
      derived: { algorithm_id: "dna.cluster.v2", params: { threshold: 0.9 } }
    })
  );
});

test("ui-laws: observed mode always requires evidence", () => {
  assert.throws(
    () => assertObservedHasEvidence({ truth_mode: "observed", evidence_refs: [] }),
    /missing evidence refs/
  );
  assert.doesNotThrow(() =>
    assertObservedHasEvidence({ truth_mode: "observed", evidence_refs: ["ev-a"] })
  );
});

test("ui-laws: truth badge and prediction labels", () => {
  assert.throws(() => assertTruthModeBadge("observed", ""), /badge missing/);
  assert.doesNotThrow(() => assertTruthModeBadge("derived", "Derived"));

  assert.throws(
    () => assertPredictedNotFact("predicted", "fact"),
    /must be labeled as prediction/
  );
  assert.doesNotThrow(() => assertPredictedNotFact("predicted", "Predicted (0.82)"));
});

test("ui-laws: semantic tokens required for state components", () => {
  assert.throws(() => assertSemanticStateToken("--color-gold-primary"), /raw gold tokens are forbidden/);
  assert.throws(() => assertSemanticStateToken("--color-warning"), /strong\/subtle/);
  assert.throws(() => assertSemanticStateToken("--color-unknown-custom"), /non-semantic state token/);
  assert.doesNotThrow(() => assertSemanticStateToken("--color-warning-strong"));
  assert.doesNotThrow(() => assertSemanticStateToken("--color-btn-primary-bg"));
  assert.doesNotThrow(() => assertSemanticStateToken("--color-focus-ring"));
});

test("ui-laws: error vs danger model is explicit", () => {
  assert.throws(() => assertErrorDangerUsage("danger", "--color-error-strong"), /danger intent/);
  assert.throws(() => assertErrorDangerUsage("error", "--color-danger-strong"), /error intent/);
  assert.doesNotThrow(() => assertErrorDangerUsage("error", "--color-error-strong"));
  assert.doesNotThrow(() => assertErrorDangerUsage("danger", "--color-danger-strong"));
  assert.doesNotThrow(() => assertErrorDangerUsage("danger", "--color-on-danger"));
});
