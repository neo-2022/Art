function encodeId(value: string): string {
  return encodeURIComponent(String(value || "").trim());
}

export function buildEvidenceHref(evidenceId: string): string {
  return `/console/evidence/${encodeId(evidenceId)}`;
}

export function buildDnaHref(dnaId: string): string {
  return `/console/dna/${encodeId(dnaId)}`;
}

export function buildGapEvidenceHref(kind: string, evidenceId: string): string {
  const id = encodeId(evidenceId);
  const normalizedKind = encodeId(kind);
  return `/console/evidence/${id}?kind=${normalizedKind}`;
}
