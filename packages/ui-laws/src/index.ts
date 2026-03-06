export type TruthMode = "observed" | "derived" | "predicted";

export interface TruthMeta {
  truth_mode: TruthMode;
  evidence_refs?: string[];
  derived?: {
    algorithm_id: string;
    params: Record<string, unknown>;
  };
  predicted?: {
    assumptions: string[];
    confidence: number;
    dataset_ref?: string;
    data_window?: string;
  };
}

export interface ClaimLike {
  claim_id: string;
  statement: string;
  proof_set: string[];
  evidence_refs?: string[];
  meta?: TruthMeta;
}

export function assertTruthMeta(meta: TruthMeta): void {
  if (!meta || !meta.truth_mode) {
    throw new Error("ui_law_violation: truth_mode is required");
  }

  if (meta.truth_mode === "observed") {
    if (!Array.isArray(meta.evidence_refs) || meta.evidence_refs.length === 0) {
      throw new Error("ui_law_violation: observed truth_mode requires evidence_refs");
    }
    return;
  }

  if (meta.truth_mode === "derived") {
    if (!meta.derived || !meta.derived.algorithm_id) {
      throw new Error("ui_law_violation: derived truth_mode requires algorithm metadata");
    }
    return;
  }

  if (meta.truth_mode === "predicted") {
    if (!meta.predicted || !Array.isArray(meta.predicted.assumptions)) {
      throw new Error("ui_law_violation: predicted truth_mode requires assumptions");
    }
    const confidence = meta.predicted.confidence;
    if (typeof confidence !== "number" || confidence < 0 || confidence > 1) {
      throw new Error("ui_law_violation: predicted truth_mode requires confidence in [0,1]");
    }
    return;
  }

  throw new Error(`ui_law_violation: unknown truth_mode '${String(meta.truth_mode)}'`);
}

export function assertObservedHasEvidence(meta: TruthMeta): void {
  if (meta.truth_mode === "observed") {
    if (!Array.isArray(meta.evidence_refs) || meta.evidence_refs.length === 0) {
      throw new Error("ui_law_violation: observed item missing evidence refs");
    }
  }
}

export function assertTruthModeBadge(mode: TruthMode, badgeLabel: string): void {
  if (!badgeLabel || badgeLabel.trim().length === 0) {
    throw new Error(`ui_law_violation: truth mode badge missing for ${mode}`);
  }
}

export function assertPredictedNotFact(mode: TruthMode, displayLabel: string): void {
  if (mode !== "predicted") {
    return;
  }
  const normalized = displayLabel.trim().toLowerCase();
  if (!normalized.includes("predicted") && !normalized.includes("прогноз")) {
    throw new Error("ui_law_violation: predicted mode must be labeled as prediction");
  }
}

export function assertClaimHasEvidence(claim: ClaimLike): void {
  if (!Array.isArray(claim.proof_set) || claim.proof_set.length === 0) {
    throw new Error(`ui_law_violation: claim ${claim.claim_id} missing proof_set`);
  }
  if (!Array.isArray(claim.evidence_refs) || claim.evidence_refs.length === 0) {
    throw new Error(`ui_law_violation: claim ${claim.claim_id} missing evidence_refs`);
  }
  if (claim.meta) {
    assertTruthMeta(claim.meta);
    assertObservedHasEvidence(claim.meta);
  }
}

export function assertTooltipKey(componentId: string, tooltipKey: string): void {
  if (!componentId || !tooltipKey) {
    throw new Error("ui_law_violation: tooltip key required");
  }
}

export function assertEvidenceLink(link?: string): void {
  if (!link || !link.startsWith("/console/evidence/")) {
    throw new Error("ui_law_violation: invalid evidence link");
  }
}

const SEMANTIC_STATE_TOKEN_PREFIXES = [
  "--color-success-",
  "--color-error-",
  "--color-danger-",
  "--color-warning-",
  "--color-info-",
  "--color-on-",
  "--color-row-",
  "--color-btn-",
  "--color-link"
];

const SEMANTIC_STATE_TOKEN_EXACT = ["--color-focus-ring"];

export function assertSemanticStateToken(tokenName: string): void {
  const token = String(tokenName || "").trim();
  if (!token.startsWith("--color-")) {
    throw new Error("ui_law_violation: token must start with --color-");
  }
  if (token.startsWith("--color-gold-")) {
    throw new Error("ui_law_violation: raw gold tokens are forbidden for state components");
  }
  if (token === "--color-warning") {
    throw new Error("ui_law_violation: warning token must be strong/subtle");
  }
  if (SEMANTIC_STATE_TOKEN_EXACT.includes(token)) {
    return;
  }
  if (SEMANTIC_STATE_TOKEN_PREFIXES.some((prefix) => token.startsWith(prefix))) {
    return;
  }
  throw new Error(`ui_law_violation: non-semantic state token '${token}'`);
}

export function assertErrorDangerUsage(intent: "error" | "danger", tokenName: string): void {
  const token = String(tokenName || "").trim();
  if (intent === "error" && !token.startsWith("--color-error-")) {
    throw new Error("ui_law_violation: error intent must use error tokens");
  }
  if (intent === "danger" && !token.startsWith("--color-danger-") && !token.startsWith("--color-on-danger")) {
    throw new Error("ui_law_violation: danger intent must use danger tokens");
  }
}
