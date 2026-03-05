export type BackpressureError = {
  retry_after_ms: number | null;
};

export type IngestInvalidDetail = {
  index: number;
  reason: string;
};

export type IngestResponse = {
  accepted: number;
  invalid_details: IngestInvalidDetail[];
  ack: { upto_seq: number | null };
};
