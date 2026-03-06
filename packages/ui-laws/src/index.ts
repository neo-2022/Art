export interface ClaimLike {
  claim_id: string;
  statement: string;
  proof_set: string[];
  evidence_refs?: string[];
}

export function assertClaimHasEvidence(claim: ClaimLike): void {
  if (!Array.isArray(claim.proof_set) || claim.proof_set.length === 0) {
    throw new Error(`ui_law_violation: claim ${claim.claim_id} missing proof_set`);
  }
  if (!Array.isArray(claim.evidence_refs) || claim.evidence_refs.length === 0) {
    throw new Error(`ui_law_violation: claim ${claim.claim_id} missing evidence_refs`);
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
