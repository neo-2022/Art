#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BackpressureError {
    pub retry_after_ms: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestInvalidDetail {
    pub index: usize,
    pub reason: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestAck {
    pub upto_seq: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IngestResponse {
    pub accepted: u64,
    pub invalid_details: Vec<IngestInvalidDetail>,
    pub ack: IngestAck,
}
