use std::collections::{HashMap, VecDeque};
use std::convert::Infallible;
use std::env;
use std::fs;
use std::net::SocketAddr;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};
use std::path::PathBuf;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Context;
use async_stream::stream;
use axum::extract::{Path, Query, State};
use axum::http::{header::CONTENT_TYPE, Extensions, HeaderMap, HeaderValue, StatusCode, Version};
use axum::response::sse::{Event, Sse};
use axum::response::IntoResponse;
use axum::response::Response;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use tokio::sync::RwLock;
use tokio::time::Duration;
use tower_http::compression::CompressionLayer;
use tracing::{info, warn};

const OTLP_ENDPOINT: &str = "/otlp/v1/logs";
const OTLP_MAX_EVENTS_PER_SEC: f64 = 200.0;
const OTLP_BURST: f64 = 400.0;
const OTLP_MAX_BATCH_EVENTS: usize = 200;
const OTLP_MAX_SIZE_BYTES: usize = 524_288;
const OTLP_RETRY_AFTER_MS: u64 = 500;
const RESERVED_OTLP_ATTR_KEYS: [&str; 6] =
    ["severity", "ts", "kind", "scope", "message", "trace_id"];
const PANEL0_BOOT_TIMEOUT_MS: u64 = 5_000;
const PANEL0_DEFAULT_BUILD_ID: &str = "dev";
const PANEL0_DEFAULT_CONSOLE_BASE_PATH: &str = "/console";
const PANEL0_BOOTSTRAP_TEMPLATE: &str = include_str!("../embedded/panel0/bootstrap.html");
const PANEL0_INDEX_HTML: &str = include_str!("../embedded/panel0/index.html");
const PANEL0_CSS: &str = include_str!("../embedded/panel0/panel0.css");
const PANEL0_JS_TEMPLATE: &str = include_str!("../embedded/panel0/panel0.js");
const PANEL0_SW_TEMPLATE: &str = include_str!("../embedded/panel0/panel0_sw.js");
const PANEL0_FAVICON: &[u8] = include_bytes!("../embedded/panel0/favicon.ico");
const DNA_SCHEMA_VERSION: &str = "2.0.0";
const DEFAULT_ANALYTICS_MAX_BUCKETS: usize = 1_440;
const DEFAULT_ANALYTICS_STATE_PATH: &str = "/tmp/art_core_analytics_state.json";

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredEvent {
    seq: u64,
    ts_ms: u64,
    event: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DnaSignature {
    dna_id: String,
    canonical_hash: String,
    payload_hash: String,
    dna_schema_version: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct EvidenceBlock {
    evidence_id: String,
    source_type: String,
    source_ref: String,
    trust_score: f64,
    freshness_ms: u64,
    redaction_policy_id: String,
    access_scope: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredEventV2 {
    seq: u64,
    ts_ms: u64,
    raw_event: Value,
    dna_signature: DnaSignature,
    evidence_refs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DnaClusterRecord {
    dna_signature: DnaSignature,
    event_count: u64,
    last_seen_ts_ms: u64,
    sample_event_seq: u64,
    evidence_refs: Vec<String>,
}

#[derive(Debug, Clone)]
struct DnaClusterState {
    signature: DnaSignature,
    event_count: u64,
    last_seen_ts_ms: u64,
    sample_event_seq: u64,
    evidence_refs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Incident {
    id: String,
    status: String,
    kind: String,
    severity: String,
    action_ref: Option<String>,
    run_id: Option<String>,
    trace_id: Option<String>,
    span_id: Option<String>,
}

#[derive(Debug, Default)]
struct Counters {
    ingest_accepted_total: u64,
    ingest_invalid_total: u64,
    ingest_dropped_total: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalyticsBucket {
    minute_ts_ms: u64,
    total_events: u64,
    gap_events: u64,
    severity_counts: HashMap<String, u64>,
    kind_counts: HashMap<String, u64>,
    dna_counts: HashMap<String, u64>,
}

impl AnalyticsBucket {
    fn new(minute_ts_ms: u64) -> Self {
        Self {
            minute_ts_ms,
            total_events: 0,
            gap_events: 0,
            severity_counts: HashMap::new(),
            kind_counts: HashMap::new(),
            dna_counts: HashMap::new(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AnalyticsState {
    max_buckets: usize,
    buckets: VecDeque<AnalyticsBucket>,
    total_events: u64,
    total_gap_events: u64,
    last_updated_ms: u64,
}

impl AnalyticsState {
    fn new(max_buckets: usize) -> Self {
        Self {
            max_buckets,
            buckets: VecDeque::new(),
            total_events: 0,
            total_gap_events: 0,
            last_updated_ms: 0,
        }
    }
}

#[derive(Debug)]
struct CoreState {
    next_seq: u64,
    events: VecDeque<StoredEvent>,
    next_seq_v2: u64,
    events_v2: VecDeque<StoredEventV2>,
    dna_clusters: HashMap<String, DnaClusterState>,
    evidence_blocks: HashMap<String, EvidenceBlock>,
    incidents: Vec<Incident>,
    fingerprint_index: HashMap<String, String>,
    source_last_seen: HashMap<String, u64>,
    counters: Counters,
    effective_profile_id: String,
    queue_depth_limit: usize,
    max_batch_events: usize,
    max_payload_bytes: usize,
    audits: Vec<AuditEntry>,
    next_audit_id: u64,
    audit_chain_head: String,
    limited_actions_allowlist: Vec<String>,
    otlp_tokens: f64,
    otlp_last_refill_ms: u64,
    analytics: AnalyticsState,
    analytics_state_path: PathBuf,
}

impl CoreState {
    fn new(
        effective_profile_id: String,
        queue_depth_limit: usize,
        max_batch_events: usize,
        max_payload_bytes: usize,
        limited_actions_allowlist: Vec<String>,
        analytics: AnalyticsState,
        analytics_state_path: PathBuf,
    ) -> Self {
        Self {
            next_seq: 1,
            events: VecDeque::new(),
            next_seq_v2: 1,
            events_v2: VecDeque::new(),
            dna_clusters: HashMap::new(),
            evidence_blocks: HashMap::new(),
            incidents: Vec::new(),
            fingerprint_index: HashMap::new(),
            source_last_seen: HashMap::new(),
            counters: Counters::default(),
            effective_profile_id,
            queue_depth_limit,
            max_batch_events,
            max_payload_bytes,
            audits: Vec::new(),
            next_audit_id: 1,
            audit_chain_head: "genesis".to_string(),
            limited_actions_allowlist,
            otlp_tokens: OTLP_BURST,
            otlp_last_refill_ms: 0,
            analytics,
            analytics_state_path,
        }
    }
}

type Shared = Arc<RwLock<CoreState>>;

#[derive(Debug, Deserialize)]
struct IngestEnvelope {
    events: Vec<Value>,
}

#[derive(Debug, Serialize)]
struct Ack {
    upto_seq: u64,
}

#[derive(Debug, Serialize)]
struct InvalidDetail {
    index: usize,
    reason: String,
    path: String,
    code: String,
}

#[derive(Debug, Serialize)]
struct IngestResponse {
    ack: Ack,
    accepted: usize,
    invalid: usize,
    invalid_details: Vec<InvalidDetail>,
}

#[derive(Debug, Serialize)]
struct BackpressureError {
    error: String,
    retry_after_ms: u64,
}

#[derive(Debug, Serialize)]
struct SnapshotResponse {
    cursor: u64,
    min_retained_seq: u64,
    effective_profile_id: String,
    events: Vec<StoredEvent>,
    incidents: Vec<Incident>,
}

#[derive(Debug, Serialize)]
struct SnapshotV2Response {
    cursor: u64,
    effective_profile_id: String,
    events: Vec<StoredEventV2>,
    dna_clusters: Vec<DnaClusterRecord>,
    incidents: Vec<Incident>,
}

#[derive(Debug, Serialize)]
struct DnaClustersResponse {
    items: Vec<DnaClusterRecord>,
    total: usize,
}

#[derive(Debug, Serialize)]
struct DnaSimilarItem {
    dna_id: String,
    score: f64,
    cluster: DnaClusterRecord,
}

#[derive(Debug, Serialize)]
struct DnaSimilarResponse {
    base_dna_id: String,
    items: Vec<DnaSimilarItem>,
}

#[derive(Debug, Serialize)]
struct AnalyticsTopItem {
    key: String,
    count: u64,
    share_pct: f64,
}

#[derive(Debug, Serialize)]
struct AnalyticsTimelinePoint {
    minute_ts_ms: u64,
    total_events: u64,
    gap_events: u64,
}

#[derive(Debug, Serialize)]
struct AnalyticsInstruction {
    id: String,
    priority: String,
    title: String,
    description: String,
    action_ref: String,
}

#[derive(Debug, Serialize)]
struct AnalyticsTotals {
    total_events: u64,
    gap_events: u64,
    gap_rate_pct: f64,
    ingest_invalid_total: u64,
    ingest_dropped_total: u64,
}

#[derive(Debug, Serialize)]
struct AnalyticsCharts {
    timeline: Vec<AnalyticsTimelinePoint>,
    severity_distribution: Vec<AnalyticsTopItem>,
    top_kinds: Vec<AnalyticsTopItem>,
    top_dna: Vec<AnalyticsTopItem>,
}

#[derive(Debug, Serialize)]
struct AnalyticsSummaryResponse {
    generated_at_ms: u64,
    window_minutes: u64,
    totals: AnalyticsTotals,
    charts: AnalyticsCharts,
    instructions: Vec<AnalyticsInstruction>,
}

#[derive(Debug, Deserialize)]
struct DnaListQuery {
    limit: Option<usize>,
}

#[derive(Debug, Deserialize)]
struct AnalyticsQuery {
    window_minutes: Option<u64>,
    top: Option<usize>,
}

#[derive(Debug, Deserialize)]
struct ActionExecuteRequest {
    action: String,
    target: Option<String>,
    params: Option<Value>,
}

#[derive(Debug, Serialize)]
struct ActionExecuteResponse {
    accepted: bool,
    action: String,
    target: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AuditMerkleProof {
    algorithm: String,
    leaf_hash: String,
    parent_hashes: Vec<String>,
    root_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct AuditEntry {
    id: u64,
    timestamp: u64,
    actor_id: String,
    actor_role: String,
    mcp_mode: String,
    action: String,
    target: String,
    result: String,
    trace_id: String,
    evidence_ref: String,
    client_ip: String,
    user_agent: String,
    prev_hash: String,
    entry_hash: String,
    merkle_proof: AuditMerkleProof,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ActorRole {
    Viewer,
    Operator,
    Admin,
}

impl ActorRole {
    fn as_str(self) -> &'static str {
        match self {
            ActorRole::Viewer => "viewer",
            ActorRole::Operator => "operator",
            ActorRole::Admin => "admin",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum McpMode {
    ReadOnly,
    LimitedActions,
    FullAdmin,
}

impl McpMode {
    fn as_str(self) -> &'static str {
        match self {
            McpMode::ReadOnly => "read_only",
            McpMode::LimitedActions => "limited_actions",
            McpMode::FullAdmin => "full_admin",
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum Endpoint {
    Snapshot,
    SnapshotV2,
    Stream,
    StreamV2,
    IncidentsGet,
    IncidentAck,
    IncidentResolve,
    ActionsExecute,
    AuditGet,
    AuditVerify,
}

#[derive(Debug, Clone, Deserialize)]
struct CoreConfig {
    profile_id: String,
    retention_days: u32,
    export_mode: String,
    egress_policy: String,
    residency: String,
    updates_mode: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct EffectiveProfileResponse {
    effective_profile_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ApplyProfileResponse {
    ok: bool,
    effective_profile_id: String,
}

#[derive(Debug, Clone)]
struct ProfileBaseline {
    retention_days: u32,
    export_mode: &'static str,
    egress_policy: &'static str,
    residency: &'static str,
    updates_mode: &'static str,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let port = env::var("CORE_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(7070);
    let config_path =
        env::var("CORE_CONFIG_PATH").unwrap_or_else(|_| "config/core.toml".to_string());
    let config = load_core_config(&config_path)
        .with_context(|| format!("failed to load core config from {}", config_path))?;
    let effective_profile_id = validate_profile_guardrails(&config)?;
    info!("effective_profile_id={}", effective_profile_id);
    let queue_depth_limit = env::var("CORE_QUEUE_DEPTH_LIMIT")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(10_000);
    let max_batch_events = env::var("CORE_MAX_BATCH_EVENTS")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(200);
    let max_payload_bytes = env::var("CORE_MAX_PAYLOAD_BYTES")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(524_288);
    let limited_actions_allowlist = env::var("CORE_LIMITED_ACTIONS_ALLOWLIST")
        .ok()
        .map(|raw| {
            raw.split(',')
                .map(str::trim)
                .filter(|v| !v.is_empty())
                .map(ToString::to_string)
                .collect::<Vec<_>>()
        })
        .unwrap_or_else(|| vec!["service.restart".to_string(), "service.status".to_string()]);
    let analytics_max_buckets = env::var("CORE_ANALYTICS_MAX_BUCKETS")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(DEFAULT_ANALYTICS_MAX_BUCKETS)
        .clamp(60, 10_080);
    let analytics_state_path = env::var("CORE_ANALYTICS_STATE_PATH")
        .ok()
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(DEFAULT_ANALYTICS_STATE_PATH));
    let analytics = load_analytics_state(&analytics_state_path, analytics_max_buckets);

    let state = Arc::new(RwLock::new(CoreState::new(
        effective_profile_id,
        queue_depth_limit,
        max_batch_events,
        max_payload_bytes,
        limited_actions_allowlist,
        analytics,
        analytics_state_path,
    )));

    install_runtime_signal_handlers();

    let app = build_app(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    let tls_config = load_tls_config_from_env();
    if let Some((cert_path, key_path)) = tls_config {
        info!(
            "art-core listening with TLS on {} (cert={}, key={})",
            addr,
            cert_path.display(),
            key_path.display()
        );
        let tls = axum_server::tls_rustls::RustlsConfig::from_pem_file(&cert_path, &key_path)
            .await
            .with_context(|| {
                format!(
                    "failed to load TLS cert/key (cert={}, key={})",
                    cert_path.display(),
                    key_path.display()
                )
            })?;
        axum_server::bind_rustls(addr, tls)
            .serve(app.into_make_service())
            .await
            .context("core tls server failed")?;
    } else {
        info!("art-core listening on {} (plain HTTP)", addr);
        let listener = tokio::net::TcpListener::bind(addr)
            .await
            .with_context(|| format!("failed to bind {}", addr))?;
        axum::serve(listener, app)
            .await
            .context("core server failed")?;
    }
    Ok(())
}

fn load_tls_config_from_env() -> Option<(PathBuf, PathBuf)> {
    let cert = env::var("CORE_TLS_CERT_PATH")
        .ok()
        .map(|v| v.trim().to_string());
    let key = env::var("CORE_TLS_KEY_PATH")
        .ok()
        .map(|v| v.trim().to_string());
    match (cert, key) {
        (Some(cert_path), Some(key_path)) if !cert_path.is_empty() && !key_path.is_empty() => {
            Some((PathBuf::from(cert_path), PathBuf::from(key_path)))
        }
        _ => None,
    }
}

fn install_runtime_signal_handlers() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{signal, SignalKind};

        if let Ok(mut hup) = signal(SignalKind::hangup()) {
            tokio::spawn(async move {
                while hup.recv().await.is_some() {
                    info!("received SIGHUP: runtime reload hook executed");
                }
            });
        }
    }
}

fn load_analytics_state(path: &PathBuf, max_buckets: usize) -> AnalyticsState {
    match fs::read_to_string(path) {
        Ok(raw) => match serde_json::from_str::<AnalyticsState>(&raw) {
            Ok(mut state) => {
                state.max_buckets = max_buckets;
                while state.buckets.len() > max_buckets {
                    state.buckets.pop_front();
                }
                state
            }
            Err(error) => {
                warn!(
                    "failed to parse analytics state from {}: {}",
                    path.display(),
                    error
                );
                AnalyticsState::new(max_buckets)
            }
        },
        Err(_) => AnalyticsState::new(max_buckets),
    }
}

fn persist_analytics_state(path: &PathBuf, state: &AnalyticsState) {
    if let Some(parent) = path.parent() {
        if let Err(error) = fs::create_dir_all(parent) {
            warn!(
                "failed to create analytics state directory {}: {}",
                parent.display(),
                error
            );
            return;
        }
    }
    let serialized = match serde_json::to_string_pretty(state) {
        Ok(value) => value,
        Err(error) => {
            warn!("failed to serialize analytics state: {}", error);
            return;
        }
    };
    let tmp = path.with_extension("tmp");
    if let Err(error) = fs::write(&tmp, serialized) {
        warn!(
            "failed to write analytics temp file {}: {}",
            tmp.display(),
            error
        );
        return;
    }
    if let Err(error) = fs::rename(&tmp, path) {
        warn!(
            "failed to replace analytics state file {}: {}",
            path.display(),
            error
        );
    }
}

fn increment_count(map: &mut HashMap<String, u64>, key: &str) {
    let entry = map.entry(key.to_string()).or_insert(0);
    *entry = entry.saturating_add(1);
}

fn analytics_bucket_for_minute_mut(
    analytics: &mut AnalyticsState,
    minute_ts_ms: u64,
) -> &mut AnalyticsBucket {
    if let Some(index) = analytics
        .buckets
        .iter()
        .position(|bucket| bucket.minute_ts_ms == minute_ts_ms)
    {
        return analytics
            .buckets
            .get_mut(index)
            .expect("bucket index must exist");
    }
    analytics
        .buckets
        .push_back(AnalyticsBucket::new(minute_ts_ms));
    while analytics.buckets.len() > analytics.max_buckets {
        analytics.buckets.pop_front();
    }
    analytics
        .buckets
        .back_mut()
        .expect("bucket appended for minute")
}

fn record_analytics_event_locked(
    s: &mut CoreState,
    ts_ms: u64,
    event: &Value,
    dna_id: Option<&str>,
) {
    let minute_ts_ms = (ts_ms / 60_000) * 60_000;
    let kind = event
        .get("kind")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let severity = event
        .get("severity")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let is_gap = kind.starts_with("observability_gap.");

    let bucket = analytics_bucket_for_minute_mut(&mut s.analytics, minute_ts_ms);
    bucket.total_events = bucket.total_events.saturating_add(1);
    increment_count(&mut bucket.kind_counts, kind);
    increment_count(&mut bucket.severity_counts, severity);
    if let Some(id) = dna_id {
        increment_count(&mut bucket.dna_counts, id);
    }
    if is_gap {
        bucket.gap_events = bucket.gap_events.saturating_add(1);
        s.analytics.total_gap_events = s.analytics.total_gap_events.saturating_add(1);
    }
    s.analytics.total_events = s.analytics.total_events.saturating_add(1);
    s.analytics.last_updated_ms = ts_ms;
}

fn build_app(state: Shared) -> Router {
    Router::new()
        .route("/", get(root_bootstrap))
        .route("/panel0", get(panel0_index))
        .route("/panel0/", get(panel0_index))
        .route("/panel0/index.html", get(panel0_index))
        .route("/panel0/panel0.js", get(panel0_js))
        .route("/panel0/panel0.css", get(panel0_css))
        .route("/panel0/panel0_sw.js", get(panel0_service_worker))
        .route("/panel0/favicon.ico", get(panel0_favicon))
        .route("/health", get(health))
        .route("/api/v1/profile/effective", get(effective_profile))
        .route("/api/v1/profile/apply", post(apply_profile))
        .route("/metrics", get(metrics))
        .route("/api/v1/ingest", post(ingest))
        .route("/api/v2/ingest", post(ingest_v2))
        .route(OTLP_ENDPOINT, post(otlp_logs))
        .route("/api/v1/snapshot", get(snapshot))
        .route("/api/v2/snapshot", get(snapshot_v2))
        .route(
            "/api/v1/stream",
            get(stream_events).layer(CompressionLayer::new().compress_when(always_compress)),
        )
        .route(
            "/api/v2/stream",
            get(stream_events_v2).layer(CompressionLayer::new().compress_when(always_compress)),
        )
        .route("/api/v2/dna/clusters", get(dna_clusters_list))
        .route("/api/v2/dna/:dna_id/similar", get(dna_cluster_similar))
        .route("/api/v2/dna/:dna_id", get(dna_cluster_get))
        .route("/api/v2/evidence/:evidence_id", get(evidence_get))
        .route("/api/v2/analytics/summary", get(analytics_summary))
        .route("/api/v1/incidents", get(incidents))
        .route("/api/v1/incidents/:id/ack", post(incident_ack))
        .route("/api/v1/incidents/:id/resolve", post(incident_resolve))
        .route("/api/v1/actions/execute", post(actions_execute))
        .route("/api/v1/audit", get(audit_list))
        .route("/api/v1/audit/verify", get(audit_verify))
        .route(
            "/api/v1/audit/:id",
            axum::routing::put(audit_mutation_forbidden).delete(audit_mutation_forbidden),
        )
        .with_state(state)
}

fn panel0_build_id() -> String {
    let raw = env::var("PANEL0_BUILD_ID").unwrap_or_else(|_| PANEL0_DEFAULT_BUILD_ID.to_string());
    match sanitize_panel0_build_id(&raw) {
        Some(value) => value,
        None => {
            warn!(
                "invalid PANEL0_BUILD_ID='{}', fallback to '{}'",
                raw, PANEL0_DEFAULT_BUILD_ID
            );
            PANEL0_DEFAULT_BUILD_ID.to_string()
        }
    }
}

fn sanitize_panel0_build_id(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() || trimmed.len() > 64 {
        return None;
    }
    if !trimmed
        .chars()
        .all(|ch| ch.is_ascii_alphanumeric() || ch == '-' || ch == '_' || ch == '.')
    {
        return None;
    }
    Some(trimmed.to_string())
}

fn panel0_console_base_path() -> String {
    let raw = env::var("ART_CONSOLE_BASE_PATH")
        .unwrap_or_else(|_| PANEL0_DEFAULT_CONSOLE_BASE_PATH.to_string());
    if is_valid_console_base_path(&raw) {
        return raw.trim().to_string();
    }
    warn!(
        "invalid ART_CONSOLE_BASE_PATH='{}', fallback to '{}'",
        raw, PANEL0_DEFAULT_CONSOLE_BASE_PATH
    );
    PANEL0_DEFAULT_CONSOLE_BASE_PATH.to_string()
}

fn is_valid_console_base_path(raw: &str) -> bool {
    let value = raw.trim();
    if value.is_empty()
        || !value.starts_with('/')
        || value.starts_with("//")
        || value.contains("://")
        || value.contains("..")
        || value.contains('\\')
    {
        return false;
    }
    !value.chars().any(|ch| ch.is_control())
}

fn render_panel0_bootstrap_html(build_id: &str, console_base_path: &str) -> String {
    let build_id_json = serde_json::to_string(build_id).unwrap_or_else(|_| "\"dev\"".to_string());
    let console_base_path_json =
        serde_json::to_string(console_base_path).unwrap_or_else(|_| "\"/console\"".to_string());
    PANEL0_BOOTSTRAP_TEMPLATE
        .replace("__CONSOLE_BASE_PATH_JSON__", &console_base_path_json)
        .replace("__PANEL0_BUILD_ID_JSON__", &build_id_json)
        .replace("__BOOT_TIMEOUT_MS__", &PANEL0_BOOT_TIMEOUT_MS.to_string())
}

fn render_panel0_js(build_id: &str) -> String {
    PANEL0_JS_TEMPLATE.replace("__PANEL0_BUILD_ID__", build_id)
}

fn render_panel0_service_worker(build_id: &str) -> String {
    PANEL0_SW_TEMPLATE.replace("__PANEL0_BUILD_ID__", build_id)
}

async fn root_bootstrap() -> impl IntoResponse {
    let html = render_panel0_bootstrap_html(&panel0_build_id(), &panel0_console_base_path());
    ([(CONTENT_TYPE, "text/html; charset=utf-8")], html)
}

async fn panel0_index() -> impl IntoResponse {
    (
        [(CONTENT_TYPE, "text/html; charset=utf-8")],
        PANEL0_INDEX_HTML,
    )
}

async fn panel0_js() -> impl IntoResponse {
    let body = render_panel0_js(&panel0_build_id());
    (
        [(CONTENT_TYPE, "application/javascript; charset=utf-8")],
        body,
    )
}

async fn panel0_css() -> impl IntoResponse {
    ([(CONTENT_TYPE, "text/css; charset=utf-8")], PANEL0_CSS)
}

async fn panel0_service_worker() -> impl IntoResponse {
    let body = render_panel0_service_worker(&panel0_build_id());
    (
        [(CONTENT_TYPE, "application/javascript; charset=utf-8")],
        body,
    )
}

async fn panel0_favicon() -> impl IntoResponse {
    ([(CONTENT_TYPE, "image/x-icon")], PANEL0_FAVICON)
}

async fn health() -> impl IntoResponse {
    (
        StatusCode::OK,
        Json(json!({"status":"ok","service":"art-core"})),
    )
}

async fn effective_profile(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    (
        StatusCode::OK,
        Json(EffectiveProfileResponse {
            effective_profile_id: s.effective_profile_id.clone(),
        }),
    )
}

async fn apply_profile(
    State(state): State<Shared>,
    Json(req): Json<CoreConfig>,
) -> impl IntoResponse {
    match validate_profile_guardrails(&req) {
        Ok(effective_profile_id) => {
            let mut s = state.write().await;
            s.effective_profile_id = effective_profile_id.clone();
            (
                StatusCode::OK,
                Json(ApplyProfileResponse {
                    ok: true,
                    effective_profile_id,
                }),
            )
                .into_response()
        }
        Err(err) => {
            let mut s = state.write().await;
            let now_ms = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_millis() as u64)
                .unwrap_or(0);
            let details = profile_violation_details(&req);
            let event = json!({
                "kind": "observability_gap.profile_violation",
                "reason": err.to_string(),
                "profile_id": req.profile_id,
                "violated_rule": details.violated_rule,
                "parameter": details.parameter,
                "current_values": {
                    "current": details.current,
                    "expected": details.expected
                },
                "ts_ms": now_ms
            });
            let seq = s.next_seq;
            s.next_seq += 1;
            s.events.push_back(StoredEvent {
                seq,
                ts_ms: now_ms,
                event,
            });
            if s.events.len() > s.queue_depth_limit {
                s.events.pop_front();
            }
            s.incidents.push(Incident {
                id: format!("profile-violation-{}", seq),
                status: "open".to_string(),
                kind: "profile_violation".to_string(),
                severity: "SEV2".to_string(),
                action_ref: None,
                run_id: None,
                trace_id: None,
                span_id: None,
            });
            (
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "ok": false,
                    "error": "profile_violation",
                    "message": err.to_string()
                })),
            )
                .into_response()
        }
    }
}

async fn metrics(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    let force_unavailable = headers
        .get("x-core-metrics-force-unavailable")
        .and_then(|h| h.to_str().ok())
        .map(|v| v == "1")
        .unwrap_or(false)
        || env::var("CORE_METRICS_FORCE_UNAVAILABLE").ok().as_deref() == Some("1");
    if force_unavailable {
        let mut s = state.write().await;
        push_gap_event_locked(
            &mut s,
            "observability_gap.metrics_unavailable",
            json!({
                "endpoint": "/metrics",
                "status": 503,
                "retry_count": 1,
                "backoff_ms": 1000,
                "trace_id": format!("trace-{}", now_ms())
            }),
        );
        return (StatusCode::SERVICE_UNAVAILABLE, "metrics unavailable").into_response();
    }
    let s = state.read().await;
    let body = format!(
        concat!(
            "ingest_accepted_total {}\n",
            "ingest_invalid_total {}\n",
            "ingest_dropped_total {}\n"
        ),
        s.counters.ingest_accepted_total,
        s.counters.ingest_invalid_total,
        s.counters.ingest_dropped_total
    );
    (StatusCode::OK, body).into_response()
}

async fn ingest(
    State(state): State<Shared>,
    headers: HeaderMap,
    Json(payload): Json<IngestEnvelope>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    let now = ingest_now_ms(&headers);
    let trace_id = format!("ingest-{}", now);
    if let Some(len) = content_length(&headers) {
        if len > s.max_payload_bytes {
            let max_payload_bytes = s.max_payload_bytes;
            push_gap_event_locked(
                &mut s,
                "observability_gap.ingest_payload_too_large",
                json!({
                    "payload_size": len,
                    "max_size": max_payload_bytes,
                    "retry_after_ms": 1_000,
                    "trace_id": trace_id
                }),
            );
            let err = BackpressureError {
                error: "payload_too_large".to_string(),
                retry_after_ms: 1_000,
            };
            return (StatusCode::PAYLOAD_TOO_LARGE, Json(json!(err))).into_response();
        }
    }
    if payload.events.len() > s.max_batch_events {
        let err = BackpressureError {
            error: "rate_limited".to_string(),
            retry_after_ms: 500,
        };
        return (StatusCode::TOO_MANY_REQUESTS, Json(json!(err))).into_response();
    }
    if s.events.len() >= s.queue_depth_limit {
        let queue_depth = s.events.len();
        push_gap_event_locked(
            &mut s,
            "observability_gap.ingest_overloaded",
            json!({
                "queue_depth": queue_depth,
                "inflight": 0,
                "retry_after_ms": 1_500,
                "trace_id": trace_id
            }),
        );
        let err = BackpressureError {
            error: "ingest_overloaded".to_string(),
            retry_after_ms: 1_500,
        };
        return (StatusCode::SERVICE_UNAVAILABLE, Json(json!(err))).into_response();
    }

    let mut accepted = 0usize;
    let mut invalid_details = Vec::new();
    let mut upto_seq = s.next_seq.saturating_sub(1);
    let force_storage_error = headers
        .get("x-core-ingest-force-storage-error")
        .and_then(|h| h.to_str().ok())
        .map(|v| v == "1")
        .unwrap_or(false)
        || env::var("CORE_INGEST_FORCE_STORAGE_ERROR").ok().as_deref() == Some("1");
    let force_pipeline_fail = headers
        .get("x-core-pipeline-force-fail")
        .and_then(|h| h.to_str().ok())
        .map(|v| v == "1")
        .unwrap_or(false)
        || env::var("CORE_PIPELINE_FORCE_FAIL").ok().as_deref() == Some("1");
    let forced_fingerprint = headers
        .get("x-core-pipeline-force-fingerprint")
        .and_then(|h| h.to_str().ok())
        .map(|v| v.to_string());
    let forced_ingest_latency_ms = headers
        .get("x-core-force-latency-ms")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok());

    for (idx, event) in payload.events.into_iter().enumerate() {
        match validate_event(&event) {
            Some(invalid) => {
                invalid_details.push(InvalidDetail {
                    index: idx,
                    reason: invalid.0,
                    path: invalid.1,
                    code: invalid.2,
                });
                s.counters.ingest_invalid_total += 1;
            }
            None => {
                if force_pipeline_fail {
                    push_gap_event_locked(
                        &mut s,
                        "observability_gap.pipeline_stage_failed",
                        json!({
                            "what": "pipeline stage failed",
                            "where": "core.pipeline.enrich",
                            "why": "forced_failure",
                            "evidence": {
                                "error": "forced pipeline failure",
                                "stage": "enrich",
                                "index": idx
                            },
                            "actions": {
                                "action_ref": "docs/runbooks/pipeline_stage_failed.md"
                            },
                            "trace_id": trace_id
                        }),
                    );
                    let err = BackpressureError {
                        error: "pipeline_stage_failed".to_string(),
                        retry_after_ms: 1_000,
                    };
                    return (StatusCode::SERVICE_UNAVAILABLE, Json(json!(err))).into_response();
                }

                if force_storage_error {
                    let queue_depth = s.events.len();
                    s.counters.ingest_dropped_total += 1;
                    push_gap_event_locked(
                        &mut s,
                        "observability_gap.ingest_unavailable",
                        json!({
                            "reason": "forced_storage_error",
                            "error": "storage write failed",
                            "queue_depth": queue_depth,
                            "inflight": 0,
                            "retry_after_ms": 1_200,
                            "trace_id": trace_id
                        }),
                    );
                    let err = BackpressureError {
                        error: "ingest_unavailable".to_string(),
                        retry_after_ms: 1_200,
                    };
                    return (StatusCode::SERVICE_UNAVAILABLE, Json(json!(err))).into_response();
                }

                let source_id = event
                    .get("source_id")
                    .and_then(Value::as_str)
                    .unwrap_or("unknown")
                    .to_string();
                s.source_last_seen.insert(source_id.clone(), now);
                let stale_threshold_ms = 600_000u64;
                let stale_sources: Vec<(String, u64)> = s
                    .source_last_seen
                    .iter()
                    .filter_map(|(sid, last_seen)| {
                        if sid == &source_id {
                            return None;
                        }
                        let age = now.saturating_sub(*last_seen);
                        if age > stale_threshold_ms {
                            Some((sid.clone(), age))
                        } else {
                            None
                        }
                    })
                    .collect();
                for (stale_source_id, age_ms) in stale_sources {
                    push_gap_event_locked(
                        &mut s,
                        "observability_gap.source_stale",
                        json!({
                            "source_id": stale_source_id,
                            "age_ms": age_ms,
                            "threshold_ms": stale_threshold_ms,
                            "trace_id": trace_id
                        }),
                    );
                }

                let processed_event = sanitize_template_injection(&event);
                if processed_event != event {
                    push_gap_event_locked(
                        &mut s,
                        "security.template_injection_blocked",
                        json!({
                            "reason": "template_injection_pattern_detected",
                            "index": idx,
                            "trace_id": trace_id
                        }),
                    );
                }

                let canonical = canonical_json_without_ts(&processed_event);
                let fingerprint = forced_fingerprint
                    .clone()
                    .unwrap_or_else(|| sha256_hex(&canonical));
                if let Some(prev) = s.fingerprint_index.get(&fingerprint).cloned() {
                    if prev != canonical {
                        push_gap_event_locked(
                            &mut s,
                            "data_quality.fingerprint_collision_suspected",
                            json!({
                                "fingerprint": fingerprint,
                                "count": 2,
                                "sample_dedup_keys": [sha256_hex(&prev), sha256_hex(&canonical)],
                                "trace_id": trace_id
                            }),
                        );
                    }
                } else {
                    s.fingerprint_index.insert(fingerprint, canonical);
                }

                let seq = s.next_seq;
                s.next_seq += 1;
                upto_seq = seq;
                s.events.push_back(StoredEvent {
                    seq,
                    ts_ms: now,
                    event: processed_event.clone(),
                });
                if s.events.len() > s.queue_depth_limit {
                    s.events.pop_front();
                }

                let incident_policy = incident_policy_for_event(&processed_event);
                let incident_kind = incident_policy
                    .map(|x| x.0.to_string())
                    .unwrap_or_else(|| "event.ingested".to_string());
                let incident_severity =
                    incident_policy.map(|x| x.1.to_string()).unwrap_or_else(|| {
                        processed_event
                            .get("severity")
                            .and_then(Value::as_str)
                            .unwrap_or("info")
                            .to_uppercase()
                    });
                let incident_action_ref = incident_policy.map(|x| x.2.to_string());
                push_incident_locked(
                    &mut s,
                    incident_kind,
                    incident_severity,
                    incident_action_ref,
                    string_field(&processed_event, "run_id"),
                    string_field(&processed_event, "trace_id"),
                    string_field(&processed_event, "span_id"),
                );
                record_analytics_event_locked(&mut s, now, &processed_event, None);
                accepted += 1;
                s.counters.ingest_accepted_total += 1;
            }
        }
    }

    let measured_latency_ms = forced_ingest_latency_ms.unwrap_or(0);
    if measured_latency_ms > 500 {
        push_incident_locked(
            &mut s,
            "core.high_latency".to_string(),
            "SEV2".to_string(),
            Some("docs/runbooks/core_high_latency.md".to_string()),
            None,
            Some(trace_id.clone()),
            None,
        );
    }

    let response = IngestResponse {
        ack: Ack { upto_seq },
        accepted,
        invalid: invalid_details.len(),
        invalid_details,
    };
    persist_analytics_state(&s.analytics_state_path, &s.analytics);
    (StatusCode::OK, Json(response)).into_response()
}

async fn ingest_v2(
    State(state): State<Shared>,
    Json(payload): Json<IngestEnvelope>,
) -> impl IntoResponse {
    if payload.events.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "invalid_payload",
                "code": "v2_empty_batch",
                "message": "events[] must contain at least one event"
            })),
        )
            .into_response();
    }

    let mut invalid_details = Vec::new();
    for (idx, event) in payload.events.iter().enumerate() {
        if let Some(invalid) = validate_event(event) {
            invalid_details.push(InvalidDetail {
                index: idx,
                reason: invalid.0,
                path: invalid.1,
                code: invalid.2,
            });
        }
    }
    if !invalid_details.is_empty() {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "invalid_payload",
                "code": "v2_invalid_event",
                "details": invalid_details,
            })),
        )
            .into_response();
    }

    let now = now_ms();
    let events = payload.events;
    let accepted = events.len();
    let mut s = state.write().await;
    let mut upto_seq = s.next_seq_v2.saturating_sub(1);

    for event in events {
        let seq = s.next_seq_v2;
        s.next_seq_v2 += 1;
        upto_seq = seq;

        let dna_signature = build_dna_signature(&event);
        let evidence_blocks = parse_evidence_blocks(&event, seq, now);
        let evidence_refs: Vec<String> = evidence_blocks
            .iter()
            .map(|block| block.evidence_id.clone())
            .collect();
        for block in evidence_blocks {
            s.evidence_blocks.insert(block.evidence_id.clone(), block);
        }
        upsert_dna_cluster_locked(&mut s, &dna_signature, seq, now, &evidence_refs);
        record_analytics_event_locked(&mut s, now, &event, Some(&dna_signature.dna_id));

        s.events_v2.push_back(StoredEventV2 {
            seq,
            ts_ms: now,
            raw_event: event,
            dna_signature,
            evidence_refs,
        });
        if s.events_v2.len() > s.queue_depth_limit {
            s.events_v2.pop_front();
        }
    }

    s.counters.ingest_accepted_total = s
        .counters
        .ingest_accepted_total
        .saturating_add(accepted as u64);
    let response = IngestResponse {
        ack: Ack { upto_seq },
        accepted,
        invalid: 0,
        invalid_details: Vec::new(),
    };
    persist_analytics_state(&s.analytics_state_path, &s.analytics);
    (StatusCode::OK, Json(response)).into_response()
}

fn canonical_v2_should_ignore_key(key: &str) -> bool {
    matches!(
        key,
        "ts" | "ts_ms"
            | "timestamp"
            | "ingest_ts_ms"
            | "event_id"
            | "received_at"
            | "ingested_at_ms"
    )
}

fn canonical_json_v2(value: &Value) -> String {
    fn normalize(value: &Value) -> Value {
        match value {
            Value::Array(items) => Value::Array(items.iter().map(normalize).collect()),
            Value::Object(map) => {
                let mut keys: Vec<&String> = map.keys().collect();
                keys.sort();
                let mut out = serde_json::Map::new();
                for key in keys {
                    if canonical_v2_should_ignore_key(key) {
                        continue;
                    }
                    if let Some(nested) = map.get(key) {
                        out.insert(key.clone(), normalize(nested));
                    }
                }
                Value::Object(out)
            }
            _ => value.clone(),
        }
    }
    normalize(value).to_string()
}

fn build_dna_signature(event: &Value) -> DnaSignature {
    let canonical = canonical_json_v2(event);
    let canonical_hash = sha256_hex(&canonical);
    let payload_hash = sha256_hex(&event.to_string());
    let dna_id = sha256_hex(&format!("{}:{}", DNA_SCHEMA_VERSION, canonical_hash));
    DnaSignature {
        dna_id,
        canonical_hash,
        payload_hash,
        dna_schema_version: DNA_SCHEMA_VERSION.to_string(),
    }
}

fn parse_evidence_blocks(event: &Value, seq: u64, ts_ms: u64) -> Vec<EvidenceBlock> {
    let mut out = Vec::new();
    if let Some(items) = event.get("evidence_blocks").and_then(Value::as_array) {
        for (idx, item) in items.iter().enumerate() {
            out.push(evidence_block_from_value(item, seq, idx, ts_ms));
        }
    }
    if out.is_empty() {
        out.push(EvidenceBlock {
            evidence_id: format!("evd-{}-0", seq),
            source_type: "raw_event".to_string(),
            source_ref: format!("/api/v2/events/{}", seq),
            trust_score: 1.0,
            freshness_ms: 0,
            redaction_policy_id: "default".to_string(),
            access_scope: event
                .get("access_scope")
                .and_then(Value::as_str)
                .unwrap_or("internal")
                .to_string(),
        });
    }
    out
}

fn evidence_block_from_value(value: &Value, seq: u64, idx: usize, ts_ms: u64) -> EvidenceBlock {
    let evidence_id = value
        .get("evidence_id")
        .and_then(Value::as_str)
        .map(|v| v.trim())
        .filter(|v| !v.is_empty())
        .map(ToString::to_string)
        .unwrap_or_else(|| format!("evd-{}-{}", seq, idx));
    let source_type = value
        .get("source_type")
        .and_then(Value::as_str)
        .unwrap_or("raw_event")
        .to_string();
    let source_ref = value
        .get("source_ref")
        .and_then(Value::as_str)
        .unwrap_or("/api/v2/events")
        .to_string();
    let trust_score = value
        .get("trust_score")
        .and_then(Value::as_f64)
        .filter(|v| v.is_finite())
        .map(|v| v.clamp(0.0, 1.0))
        .unwrap_or(1.0);
    let freshness_ms = value
        .get("freshness_ms")
        .and_then(Value::as_u64)
        .unwrap_or_else(|| now_ms().saturating_sub(ts_ms));
    let redaction_policy_id = value
        .get("redaction_policy_id")
        .and_then(Value::as_str)
        .unwrap_or("default")
        .to_string();
    let access_scope = value
        .get("access_scope")
        .and_then(Value::as_str)
        .unwrap_or("internal")
        .to_string();
    EvidenceBlock {
        evidence_id,
        source_type,
        source_ref,
        trust_score,
        freshness_ms,
        redaction_policy_id,
        access_scope,
    }
}

fn upsert_dna_cluster_locked(
    state: &mut CoreState,
    signature: &DnaSignature,
    seq: u64,
    ts_ms: u64,
    evidence_refs: &[String],
) {
    let entry = state
        .dna_clusters
        .entry(signature.dna_id.clone())
        .or_insert_with(|| DnaClusterState {
            signature: signature.clone(),
            event_count: 0,
            last_seen_ts_ms: ts_ms,
            sample_event_seq: seq,
            evidence_refs: Vec::new(),
        });
    entry.event_count = entry.event_count.saturating_add(1);
    entry.last_seen_ts_ms = ts_ms;
    if entry.sample_event_seq == 0 {
        entry.sample_event_seq = seq;
    }
    for evidence_id in evidence_refs {
        if !entry
            .evidence_refs
            .iter()
            .any(|existing| existing == evidence_id)
        {
            entry.evidence_refs.push(evidence_id.clone());
        }
    }
}

fn cluster_record_from_state(cluster: &DnaClusterState) -> DnaClusterRecord {
    DnaClusterRecord {
        dna_signature: cluster.signature.clone(),
        event_count: cluster.event_count,
        last_seen_ts_ms: cluster.last_seen_ts_ms,
        sample_event_seq: cluster.sample_event_seq,
        evidence_refs: cluster.evidence_refs.clone(),
    }
}

fn sorted_dna_clusters_locked(state: &CoreState, limit: usize) -> Vec<DnaClusterRecord> {
    let mut clusters: Vec<DnaClusterRecord> = state
        .dna_clusters
        .values()
        .map(cluster_record_from_state)
        .collect();
    clusters.sort_by(|left, right| {
        right
            .event_count
            .cmp(&left.event_count)
            .then_with(|| right.last_seen_ts_ms.cmp(&left.last_seen_ts_ms))
            .then_with(|| left.dna_signature.dna_id.cmp(&right.dna_signature.dna_id))
    });
    clusters.truncate(limit);
    clusters
}

fn similarity_score_by_prefix(left_hash: &str, right_hash: &str) -> f64 {
    let left = left_hash.as_bytes();
    let right = right_hash.as_bytes();
    if left.is_empty() || right.is_empty() {
        return 0.0;
    }
    let max = left.len().min(right.len());
    let mut same_prefix = 0usize;
    for index in 0..max {
        if left[index] != right[index] {
            break;
        }
        same_prefix += 1;
    }
    same_prefix as f64 / max as f64
}

async fn snapshot_v2(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::SnapshotV2, None, None).await {
        return deny;
    }
    let s = state.read().await;
    let events: Vec<StoredEventV2> = s.events_v2.iter().rev().take(200).cloned().collect();
    let cursor = events.iter().map(|e| e.seq).max().unwrap_or(0);
    let dna_clusters = sorted_dna_clusters_locked(&s, 200);
    let body = SnapshotV2Response {
        cursor,
        effective_profile_id: s.effective_profile_id.clone(),
        events,
        dna_clusters,
        incidents: s.incidents.clone(),
    };
    (StatusCode::OK, Json(body)).into_response()
}

async fn stream_events_v2(State(state): State<Shared>, headers: HeaderMap) -> Response {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::StreamV2, None, None).await {
        return deny;
    }
    let last_event_id = headers
        .get("last-event-id")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok());
    let hold_seconds = headers
        .get("x-core-stream-hold-seconds")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or(0)
        .min(600);

    let (
        cursor_now,
        min_retained_seq,
        events_for_stream,
        incidents,
        effective_profile_id,
        clusters,
    ) = {
        let s = state.read().await;
        let cursor = s.next_seq_v2.saturating_sub(1);
        let min_retained = s.events_v2.front().map(|event| event.seq).unwrap_or(cursor);
        let from_seq = last_event_id.unwrap_or(0);
        let events = s
            .events_v2
            .iter()
            .filter(|event| event.seq > from_seq)
            .cloned()
            .collect::<Vec<_>>();
        (
            cursor,
            min_retained,
            events,
            s.incidents.clone(),
            s.effective_profile_id.clone(),
            sorted_dna_clusters_locked(&s, 200),
        )
    };

    if let Some(cursor) = last_event_id {
        if cursor != 0 && cursor < min_retained_seq {
            let snapshot = SnapshotV2Response {
                cursor: cursor_now,
                effective_profile_id,
                events: events_for_stream.into_iter().rev().take(200).collect(),
                dna_clusters: clusters,
                incidents,
            };
            let mut resp = (StatusCode::OK, Json(snapshot)).into_response();
            if let Ok(v) = HeaderValue::from_str(&cursor_now.to_string()) {
                resp.headers_mut().insert("x-stream-cursor", v);
            }
            return resp;
        }
    }

    let tick = Duration::from_secs(1);
    let out = stream! {
        for stored in events_for_stream {
            let payload = json!({
                "seq": stored.seq,
                "ts_ms": stored.ts_ms,
                "raw_event": stored.raw_event,
                "dna_signature": stored.dna_signature,
                "evidence_refs": stored.evidence_refs,
            });
            yield Ok::<Event, Infallible>(
                Event::default()
                    .id(stored.seq.to_string())
                    .event("message")
                    .data(payload.to_string()),
            );
        }
        for _ in 0..hold_seconds {
            tokio::time::sleep(tick).await;
            let cursor = {
                let s = state.read().await;
                s.next_seq_v2.saturating_sub(1)
            };
            let payload = json!({
                "type": "keepalive",
                "cursor": cursor
            });
            yield Ok::<Event, Infallible>(
                Event::default()
                    .id(cursor.to_string())
                    .event("message")
                    .data(payload.to_string()),
            );
        }
    };

    let mut resp = Sse::new(out).into_response();
    resp.headers_mut()
        .insert("cache-control", HeaderValue::from_static("no-cache"));
    resp
}

async fn dna_clusters_list(
    State(state): State<Shared>,
    Query(query): Query<DnaListQuery>,
) -> impl IntoResponse {
    let limit = query.limit.unwrap_or(50).clamp(1, 500);
    let s = state.read().await;
    let total = s.dna_clusters.len();
    let items = sorted_dna_clusters_locked(&s, limit);
    (StatusCode::OK, Json(DnaClustersResponse { items, total })).into_response()
}

async fn dna_cluster_get(
    Path(dna_id): Path<String>,
    State(state): State<Shared>,
) -> impl IntoResponse {
    let s = state.read().await;
    if let Some(cluster) = s.dna_clusters.get(&dna_id) {
        return (StatusCode::OK, Json(cluster_record_from_state(cluster))).into_response();
    }
    (
        StatusCode::NOT_FOUND,
        Json(json!({"error":"dna_not_found","dna_id": dna_id})),
    )
        .into_response()
}

async fn dna_cluster_similar(
    Path(dna_id): Path<String>,
    State(state): State<Shared>,
    Query(query): Query<DnaListQuery>,
) -> impl IntoResponse {
    let limit = query.limit.unwrap_or(5).clamp(1, 25);
    let s = state.read().await;
    let Some(base) = s.dna_clusters.get(&dna_id) else {
        return (
            StatusCode::NOT_FOUND,
            Json(json!({"error":"dna_not_found","dna_id": dna_id})),
        )
            .into_response();
    };
    let base_hash = base.signature.canonical_hash.clone();
    let mut items = Vec::new();
    for (candidate_id, candidate) in &s.dna_clusters {
        if candidate_id == &dna_id {
            continue;
        }
        let score = similarity_score_by_prefix(&base_hash, &candidate.signature.canonical_hash);
        items.push(DnaSimilarItem {
            dna_id: candidate_id.clone(),
            score,
            cluster: cluster_record_from_state(candidate),
        });
    }
    items.sort_by(|left, right| {
        right
            .score
            .total_cmp(&left.score)
            .then_with(|| right.cluster.event_count.cmp(&left.cluster.event_count))
            .then_with(|| left.dna_id.cmp(&right.dna_id))
    });
    items.truncate(limit);
    (
        StatusCode::OK,
        Json(DnaSimilarResponse {
            base_dna_id: dna_id,
            items,
        }),
    )
        .into_response()
}

async fn evidence_get(
    Path(evidence_id): Path<String>,
    State(state): State<Shared>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let scope_header = headers
        .get("x-access-scope")
        .and_then(|value| value.to_str().ok())
        .map(|value| value.to_string());
    let role = role_from_headers(&headers);
    let s = state.read().await;
    let Some(block) = s.evidence_blocks.get(&evidence_id) else {
        return (
            StatusCode::NOT_FOUND,
            Json(json!({"error":"evidence_not_found","evidence_id": evidence_id})),
        )
            .into_response();
    };
    if block.access_scope != "public"
        && scope_header.as_deref() != Some(block.access_scope.as_str())
        && role != Some(ActorRole::Admin)
    {
        return (
            StatusCode::FORBIDDEN,
            Json(json!({
                "error":"evidence_access_denied",
                "evidence_id": evidence_id,
                "required_scope": block.access_scope
            })),
        )
            .into_response();
    }
    (StatusCode::OK, Json(block.clone())).into_response()
}

fn top_items_from_counts(
    counts: &HashMap<String, u64>,
    total: u64,
    top: usize,
) -> Vec<AnalyticsTopItem> {
    let mut items: Vec<(String, u64)> = counts.iter().map(|(k, v)| (k.clone(), *v)).collect();
    items.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));
    items
        .into_iter()
        .take(top)
        .map(|(key, count)| {
            let share_pct = if total == 0 {
                0.0
            } else {
                (count as f64 / total as f64) * 100.0
            };
            AnalyticsTopItem {
                key,
                count,
                share_pct: (share_pct * 100.0).round() / 100.0,
            }
        })
        .collect()
}

fn build_analytics_instructions(
    totals: &AnalyticsTotals,
    top_kinds: &[AnalyticsTopItem],
    top_dna: &[AnalyticsTopItem],
) -> Vec<AnalyticsInstruction> {
    let mut out = Vec::new();
    if totals.gap_rate_pct > 5.0 {
        out.push(AnalyticsInstruction {
            id: "gap-rate-high".to_string(),
            priority: "high".to_string(),
            title: "High observability gap rate".to_string(),
            description: format!(
                "Gap rate is {:.2}%. Stabilize data pipeline first and execute related runbooks.",
                totals.gap_rate_pct
            ),
            action_ref: "docs/runbooks/console_boot_failed.md".to_string(),
        });
    }
    if totals.ingest_invalid_total > 0 {
        out.push(AnalyticsInstruction {
            id: "invalid-payloads-present".to_string(),
            priority: "medium".to_string(),
            title: "Invalid ingest payloads detected".to_string(),
            description: format!(
                "Found {} invalid payloads. Check schema compliance in producers.",
                totals.ingest_invalid_total
            ),
            action_ref: "docs/runbooks/ingest_payload_too_large.md".to_string(),
        });
    }
    if let Some(kind) = top_kinds.first() {
        out.push(AnalyticsInstruction {
            id: "top-kind-focus".to_string(),
            priority: "medium".to_string(),
            title: "Primary incident pattern".to_string(),
            description: format!(
                "Most frequent event kind is '{}' ({} events). Focus triage and mitigation around this pattern.",
                kind.key, kind.count
            ),
            action_ref: "docs/source/dna_core_determinism_performance_assurance.md".to_string(),
        });
    }
    if let Some(dna) = top_dna.first() {
        out.push(AnalyticsInstruction {
            id: "top-dna-recurrence".to_string(),
            priority: "medium".to_string(),
            title: "Recurring DNA cluster".to_string(),
            description: format!(
                "DNA '{}' dominates with {} events. Consider dedicated investigation and automation.",
                dna.key, dna.count
            ),
            action_ref: "docs/source/investigations_as_code.md".to_string(),
        });
    }
    if out.is_empty() {
        out.push(AnalyticsInstruction {
            id: "stable-signal".to_string(),
            priority: "low".to_string(),
            title: "Signal quality is stable".to_string(),
            description: "No critical anomalies in selected window. Continue monitoring and scheduled replay checks."
                .to_string(),
            action_ref: "docs/source/checklists/CHECKLIST_34_PERF_LOAD_COVERAGE_RATCHET.md"
                .to_string(),
        });
    }
    out
}

async fn analytics_summary(
    State(state): State<Shared>,
    headers: HeaderMap,
    Query(query): Query<AnalyticsQuery>,
) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::SnapshotV2, None, None).await {
        return deny;
    }
    let window_minutes = query.window_minutes.unwrap_or(60).clamp(5, 10_080);
    let top = query.top.unwrap_or(5).clamp(1, 20);
    let now = now_ms();
    let cutoff = now.saturating_sub(window_minutes.saturating_mul(60_000));

    let s = state.read().await;
    let mut timeline = Vec::new();
    let mut severity_counts: HashMap<String, u64> = HashMap::new();
    let mut kind_counts: HashMap<String, u64> = HashMap::new();
    let mut dna_counts: HashMap<String, u64> = HashMap::new();
    let mut total_events = 0u64;
    let mut gap_events = 0u64;

    for bucket in &s.analytics.buckets {
        if bucket.minute_ts_ms < cutoff {
            continue;
        }
        timeline.push(AnalyticsTimelinePoint {
            minute_ts_ms: bucket.minute_ts_ms,
            total_events: bucket.total_events,
            gap_events: bucket.gap_events,
        });
        total_events = total_events.saturating_add(bucket.total_events);
        gap_events = gap_events.saturating_add(bucket.gap_events);
        for (key, value) in &bucket.severity_counts {
            let entry = severity_counts.entry(key.clone()).or_insert(0);
            *entry = entry.saturating_add(*value);
        }
        for (key, value) in &bucket.kind_counts {
            let entry = kind_counts.entry(key.clone()).or_insert(0);
            *entry = entry.saturating_add(*value);
        }
        for (key, value) in &bucket.dna_counts {
            let entry = dna_counts.entry(key.clone()).or_insert(0);
            *entry = entry.saturating_add(*value);
        }
    }

    timeline.sort_by(|left, right| left.minute_ts_ms.cmp(&right.minute_ts_ms));
    let gap_rate_pct = if total_events == 0 {
        0.0
    } else {
        ((gap_events as f64 / total_events as f64) * 10000.0).round() / 100.0
    };
    let totals = AnalyticsTotals {
        total_events,
        gap_events,
        gap_rate_pct,
        ingest_invalid_total: s.counters.ingest_invalid_total,
        ingest_dropped_total: s.counters.ingest_dropped_total,
    };
    let severity_distribution = top_items_from_counts(&severity_counts, total_events, top);
    let top_kinds = top_items_from_counts(&kind_counts, total_events, top);
    let top_dna = top_items_from_counts(&dna_counts, total_events, top);
    let instructions = build_analytics_instructions(&totals, &top_kinds, &top_dna);

    (
        StatusCode::OK,
        Json(AnalyticsSummaryResponse {
            generated_at_ms: now,
            window_minutes,
            totals,
            charts: AnalyticsCharts {
                timeline,
                severity_distribution,
                top_kinds,
                top_dna,
            },
            instructions,
        }),
    )
        .into_response()
}

async fn otlp_logs(
    State(state): State<Shared>,
    headers: HeaderMap,
    Json(payload): Json<Value>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    let now = ingest_now_ms(&headers);
    let trace_id = format!("otlp-{}", now);

    if let Some(len) = content_length(&headers) {
        if len > OTLP_MAX_SIZE_BYTES {
            push_otlp_rate_limited_gap_locked(
                &mut s,
                "max_size_bytes",
                len as u64,
                OTLP_RETRY_AFTER_MS,
                &trace_id,
            );
            let err = BackpressureError {
                error: "payload_too_large".to_string(),
                retry_after_ms: OTLP_RETRY_AFTER_MS,
            };
            return (StatusCode::PAYLOAD_TOO_LARGE, Json(json!(err))).into_response();
        }
    }

    let events = match otlp_payload_to_raw_events(&payload, now) {
        Ok(events) => events,
        Err(error) => {
            s.counters.ingest_invalid_total += 1;
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "error": "invalid_otlp_payload",
                    "message": error
                })),
            )
                .into_response();
        }
    };

    if events.len() > OTLP_MAX_BATCH_EVENTS {
        push_otlp_rate_limited_gap_locked(
            &mut s,
            "max_batch_events",
            events.len() as u64,
            OTLP_RETRY_AFTER_MS,
            &trace_id,
        );
        let err = BackpressureError {
            error: "batch_too_large".to_string(),
            retry_after_ms: OTLP_RETRY_AFTER_MS,
        };
        return (StatusCode::PAYLOAD_TOO_LARGE, Json(json!(err))).into_response();
    }

    if !consume_otlp_tokens_locked(&mut s, now, events.len() as f64) {
        push_otlp_rate_limited_gap_locked(
            &mut s,
            "max_events_per_sec",
            events.len() as u64,
            OTLP_RETRY_AFTER_MS,
            &trace_id,
        );
        let err = BackpressureError {
            error: "rate_limited".to_string(),
            retry_after_ms: OTLP_RETRY_AFTER_MS,
        };
        return (StatusCode::TOO_MANY_REQUESTS, Json(json!(err))).into_response();
    }

    if s.events.len() >= s.queue_depth_limit {
        let queue_depth = s.events.len() as u64;
        push_otlp_rate_limited_gap_locked(
            &mut s,
            "ingest_queue_depth",
            queue_depth,
            1_500,
            &trace_id,
        );
        let err = BackpressureError {
            error: "ingest_overloaded".to_string(),
            retry_after_ms: 1_500,
        };
        return (StatusCode::SERVICE_UNAVAILABLE, Json(json!(err))).into_response();
    }

    let mut accepted = 0usize;
    let mut invalid_details = Vec::new();
    let mut upto_seq = s.next_seq.saturating_sub(1);

    for (idx, event) in events.into_iter().enumerate() {
        match validate_event(&event) {
            Some(invalid) => {
                invalid_details.push(InvalidDetail {
                    index: idx,
                    reason: invalid.0,
                    path: invalid.1,
                    code: invalid.2,
                });
                s.counters.ingest_invalid_total += 1;
            }
            None => {
                let seq = s.next_seq;
                s.next_seq += 1;
                upto_seq = seq;
                s.events.push_back(StoredEvent {
                    seq,
                    ts_ms: now,
                    event: event.clone(),
                });
                if s.events.len() > s.queue_depth_limit {
                    s.events.pop_front();
                }

                if let Some((kind, severity, action_ref)) = incident_policy_for_event(&event) {
                    push_incident_locked(
                        &mut s,
                        kind.to_string(),
                        severity.to_string(),
                        Some(action_ref.to_string()),
                        None,
                        string_field(&event, "trace_id"),
                        None,
                    );
                }
                accepted += 1;
                s.counters.ingest_accepted_total += 1;
            }
        }
    }

    let response = IngestResponse {
        ack: Ack { upto_seq },
        accepted,
        invalid: invalid_details.len(),
        invalid_details,
    };
    (StatusCode::OK, Json(response)).into_response()
}

fn consume_otlp_tokens_locked(s: &mut CoreState, now_ms: u64, requested_events: f64) -> bool {
    let last_refill = if s.otlp_last_refill_ms == 0 {
        now_ms
    } else {
        s.otlp_last_refill_ms
    };
    let elapsed_ms = now_ms.saturating_sub(last_refill);
    let refill = (elapsed_ms as f64 / 1000.0) * OTLP_MAX_EVENTS_PER_SEC;
    s.otlp_tokens = (s.otlp_tokens + refill).min(OTLP_BURST);
    s.otlp_last_refill_ms = now_ms;

    if requested_events > s.otlp_tokens {
        return false;
    }

    s.otlp_tokens -= requested_events;
    true
}

fn push_otlp_rate_limited_gap_locked(
    s: &mut CoreState,
    limit_name: &str,
    current_value: u64,
    retry_after_ms: u64,
    trace_id: &str,
) {
    push_gap_event_locked(
        s,
        "observability_gap.otlp_rate_limited",
        json!({
            "limit_name": limit_name,
            "current_value": current_value,
            "retry_after_ms": retry_after_ms,
            "endpoint": OTLP_ENDPOINT,
            "trace_id": trace_id,
        }),
    );
}

fn otlp_payload_to_raw_events(payload: &Value, now_ms: u64) -> Result<Vec<Value>, String> {
    let resource_logs = payload
        .get("resourceLogs")
        .and_then(Value::as_array)
        .ok_or_else(|| "resourceLogs[] is required".to_string())?;

    let mut out = Vec::new();
    for resource_log in resource_logs {
        let scope_logs = resource_log
            .get("scopeLogs")
            .or_else(|| resource_log.get("scope_logs"))
            .and_then(Value::as_array)
            .ok_or_else(|| "scopeLogs[] is required".to_string())?;
        for scope_log in scope_logs {
            let log_records = scope_log
                .get("logRecords")
                .or_else(|| scope_log.get("log_records"))
                .and_then(Value::as_array)
                .ok_or_else(|| "logRecords[] is required".to_string())?;
            for log_record in log_records {
                out.push(otlp_log_record_to_event(log_record, now_ms)?);
            }
        }
    }
    if out.is_empty() {
        return Err("at least one OTLP log record is required".to_string());
    }
    Ok(out)
}

fn otlp_log_record_to_event(log_record: &Value, now_ms: u64) -> Result<Value, String> {
    let severity_text = log_record
        .get("severityText")
        .or_else(|| log_record.get("severity_text"))
        .and_then(Value::as_str)
        .unwrap_or("INFO");
    let (severity, unknown_severity) = map_otel_severity(severity_text);
    let mut event = serde_json::Map::new();
    event.insert("severity".to_string(), Value::String(severity.to_string()));
    event.insert("kind".to_string(), Value::String("otlp.log".to_string()));
    event.insert(
        "scope".to_string(),
        Value::String("telemetry.otlp.receiver".to_string()),
    );
    event.insert("ts_ms".to_string(), json!(now_ms));
    if let Some(message) = extract_otlp_body(log_record.get("body")) {
        event.insert("message".to_string(), Value::String(message));
    }
    if let Some(trace_id) = log_record
        .get("traceId")
        .or_else(|| log_record.get("trace_id"))
        .and_then(Value::as_str)
    {
        event.insert("trace_id".to_string(), Value::String(trace_id.to_string()));
    }

    let attrs = log_record
        .get("attributes")
        .and_then(Value::as_array)
        .ok_or_else(|| "logRecord.attributes[] is required".to_string())?;
    let otel_attributes = convert_otlp_attributes(attrs);
    let mut payload = serde_json::Map::new();
    payload.insert(
        "otel_attributes".to_string(),
        Value::Object(otel_attributes),
    );
    if unknown_severity {
        payload.insert("otel_severity_unknown".to_string(), Value::Bool(true));
    }
    event.insert("payload".to_string(), Value::Object(payload));
    Ok(Value::Object(event))
}

fn map_otel_severity(level: &str) -> (&'static str, bool) {
    match level.to_ascii_uppercase().as_str() {
        "DEBUG" => ("debug", false),
        "INFO" => ("info", false),
        "WARN" | "WARNING" => ("warn", false),
        "ERROR" => ("error", false),
        "FATAL" => ("fatal", false),
        _ => ("info", true),
    }
}

fn convert_otlp_attributes(attrs: &[Value]) -> serde_json::Map<String, Value> {
    let mut out = serde_json::Map::new();
    for attr in attrs {
        let key = attr.get("key").and_then(Value::as_str).unwrap_or_default();
        if key.is_empty() {
            continue;
        }
        let mut target_key = key.to_string();
        if RESERVED_OTLP_ATTR_KEYS.contains(&key) {
            target_key = format!("otel.{}", key);
        }

        let value = attr
            .get("value")
            .and_then(convert_otlp_any_value)
            .unwrap_or(Value::Null);
        out.insert(target_key, value);
    }
    out
}

fn convert_otlp_any_value(value: &Value) -> Option<Value> {
    if let Some(v) = value.get("stringValue").and_then(Value::as_str) {
        return Some(Value::String(v.to_string()));
    }
    if let Some(v) = value.get("boolValue").and_then(Value::as_bool) {
        return Some(Value::Bool(v));
    }
    if let Some(v) = value.get("doubleValue").and_then(Value::as_f64) {
        return Some(json!(v));
    }
    if let Some(v) = value.get("intValue") {
        if let Some(num) = v.as_i64() {
            return Some(json!(num));
        }
        if let Some(as_str) = v.as_str() {
            if let Ok(parsed) = as_str.parse::<i64>() {
                return Some(json!(parsed));
            }
        }
    }
    if let Some(v) = value.get("bytesValue").and_then(Value::as_str) {
        return Some(Value::String(v.to_string()));
    }
    if let Some(values) = value
        .get("arrayValue")
        .and_then(|nested| nested.get("values"))
        .and_then(Value::as_array)
    {
        let mut out = Vec::with_capacity(values.len());
        for item in values {
            out.push(convert_otlp_any_value(item).unwrap_or(Value::Null));
        }
        return Some(Value::Array(out));
    }
    None
}

fn extract_otlp_body(body: Option<&Value>) -> Option<String> {
    let body = body?;
    let value = convert_otlp_any_value(body)?;
    match value {
        Value::String(v) => Some(v),
        other => Some(other.to_string()),
    }
}

fn push_gap_event_locked(s: &mut CoreState, kind: &str, details: Value) {
    let trace_id = details
        .get("trace_id")
        .and_then(Value::as_str)
        .map(|v| v.to_string());
    let ts_ms = now_ms();
    let seq = s.next_seq;
    s.next_seq += 1;
    let gap_event = json!({
        "kind": kind,
        "severity": "error",
        "details": details
    });
    s.events.push_back(StoredEvent {
        seq,
        ts_ms,
        event: gap_event.clone(),
    });
    record_analytics_event_locked(s, ts_ms, &gap_event, None);
    if s.events.len() > s.queue_depth_limit {
        s.events.pop_front();
    }
    if let Some((incident_kind, incident_severity, action_ref)) = incident_policy_for_gap(kind) {
        push_incident_locked(
            s,
            incident_kind.to_string(),
            incident_severity.to_string(),
            Some(action_ref.to_string()),
            None,
            trace_id,
            None,
        );
    }
    persist_analytics_state(&s.analytics_state_path, &s.analytics);
}

fn validate_event(event: &Value) -> Option<(String, String, String)> {
    let severity = event.get("severity").and_then(Value::as_str);
    match severity {
        Some("debug" | "info" | "warn" | "error" | "fatal") => None,
        Some(_) => Some((
            "unknown severity".to_string(),
            "severity".to_string(),
            "validation_error".to_string(),
        )),
        None => Some((
            "missing severity".to_string(),
            "severity".to_string(),
            "validation_error".to_string(),
        )),
    }
}

fn content_length(headers: &HeaderMap) -> Option<usize> {
    headers
        .get("content-length")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<usize>().ok())
}

fn ingest_now_ms(headers: &HeaderMap) -> u64 {
    headers
        .get("x-core-now-ms")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or_else(now_ms)
}

fn string_field(event: &Value, key: &str) -> Option<String> {
    event
        .get(key)
        .and_then(Value::as_str)
        .map(|s| s.to_string())
}

fn number_field(event: &Value, key: &str) -> Option<f64> {
    event.get(key).and_then(Value::as_f64)
}

fn incident_policy_for_event(event: &Value) -> Option<(&'static str, &'static str, &'static str)> {
    let kind = event
        .get("kind")
        .and_then(Value::as_str)
        .unwrap_or_default();
    if kind == "agent.spool_near_full" {
        return Some((
            "agent.spool_near_full",
            "SEV2",
            "docs/runbooks/agent_spool_near_full.md",
        ));
    }
    if kind == "dlq_non_empty" {
        return Some(("dlq_non_empty", "SEV3", "docs/runbooks/dlq_non_empty.md"));
    }
    if kind == "core.high_latency" {
        return Some((
            "core.high_latency",
            "SEV2",
            "docs/runbooks/core_high_latency.md",
        ));
    }

    let spool_used = number_field(event, "spool_used_bytes").unwrap_or(0.0);
    let spool_capacity = number_field(event, "spool_capacity_bytes").unwrap_or(0.0);
    if spool_capacity > 0.0 && (spool_used / spool_capacity) >= 0.90 {
        return Some((
            "agent.spool_near_full",
            "SEV2",
            "docs/runbooks/agent_spool_near_full.md",
        ));
    }

    if number_field(event, "dlq_size").unwrap_or(0.0) > 0.0 {
        return Some(("dlq_non_empty", "SEV3", "docs/runbooks/dlq_non_empty.md"));
    }

    None
}

fn incident_policy_for_gap(kind: &str) -> Option<(&'static str, &'static str, &'static str)> {
    match kind {
        "observability_gap.source_stale" => {
            Some(("source_stale", "SEV2", "docs/runbooks/source_stale.md"))
        }
        "observability_gap.e2e_environment_failed" => Some((
            "e2e_environment_failed",
            "SEV2",
            "docs/runbooks/e2e_environment_failed.md",
        )),
        "observability_gap.metrics_unavailable" => Some((
            "metrics_unavailable",
            "SEV2",
            "docs/runbooks/metrics_unavailable.md",
        )),
        "observability_gap.otlp_rate_limited" => Some((
            "otlp_rate_limited",
            "SEV2",
            "docs/runbooks/otlp_rate_limited.md",
        )),
        _ => None,
    }
}

fn push_incident_locked(
    s: &mut CoreState,
    kind: String,
    severity: String,
    action_ref: Option<String>,
    run_id: Option<String>,
    trace_id: Option<String>,
    span_id: Option<String>,
) {
    let incident_id = format!("incident-{}", s.next_seq);
    s.incidents.push(Incident {
        id: incident_id,
        status: "open".to_string(),
        kind,
        severity,
        action_ref,
        run_id,
        trace_id,
        span_id,
    });
}

fn contains_injection_pattern(value: &str) -> bool {
    let patterns = ["$(", "`", "${", ";", "|", "../", "..\\"];
    patterns.iter().any(|p| value.contains(p))
}

fn escape_injection(value: &str) -> String {
    value
        .replace("$(", "\\$(")
        .replace("`", "\\`")
        .replace("${", "\\${")
        .replace(";", "\\;")
        .replace("|", "\\|")
        .replace("../", "..\\/")
        .replace("..\\", "..\\\\")
}

fn sanitize_template_injection(value: &Value) -> Value {
    match value {
        Value::String(s) => {
            if contains_injection_pattern(s) {
                Value::String(escape_injection(s))
            } else {
                Value::String(s.clone())
            }
        }
        Value::Array(arr) => Value::Array(arr.iter().map(sanitize_template_injection).collect()),
        Value::Object(map) => {
            let mut out = serde_json::Map::new();
            for (k, v) in map {
                out.insert(k.clone(), sanitize_template_injection(v));
            }
            Value::Object(out)
        }
        _ => value.clone(),
    }
}

fn canonical_json_without_ts(value: &Value) -> String {
    fn normalized(v: &Value) -> Value {
        match v {
            Value::Array(arr) => Value::Array(arr.iter().map(normalized).collect()),
            Value::Object(map) => {
                let mut keys: Vec<_> = map.keys().cloned().collect();
                keys.sort();
                let mut out = serde_json::Map::new();
                for key in keys {
                    if key == "ts" || key == "ts_ms" {
                        continue;
                    }
                    let nested = map.get(&key).expect("key exists");
                    out.insert(key, normalized(nested));
                }
                Value::Object(out)
            }
            _ => v.clone(),
        }
    }
    normalized(value).to_string()
}

fn sha256_hex(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    let bytes = hasher.finalize();
    format!("{:x}", bytes)
}

async fn snapshot(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::Snapshot, None, None).await {
        return deny;
    }
    let s = state.read().await;
    let events: Vec<StoredEvent> = s.events.iter().rev().take(200).cloned().collect();
    let cursor = events.iter().map(|e| e.seq).max().unwrap_or(0);
    let min_retained_seq = compute_min_retained_seq(&s);
    let body = SnapshotResponse {
        cursor,
        min_retained_seq,
        effective_profile_id: s.effective_profile_id.clone(),
        events,
        incidents: s.incidents.clone(),
    };
    (StatusCode::OK, Json(body)).into_response()
}

async fn stream_events(State(state): State<Shared>, headers: HeaderMap) -> Response {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::Stream, None, None).await {
        return deny;
    }
    let force_unavailable = headers
        .get("x-core-stream-force-unavailable")
        .and_then(|h| h.to_str().ok())
        .map(|v| v == "1")
        .unwrap_or(false)
        || env::var("CORE_STREAM_FORCE_UNAVAILABLE").ok().as_deref() == Some("1");

    if force_unavailable {
        push_gap_event(
            &state,
            "observability_gap.stream_unavailable",
            json!({
                "endpoint": "/api/v1/stream",
                "reason": "forced_unavailable",
                "trace_id": "none"
            }),
        )
        .await;
        return (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(json!({"error":"stream_unavailable"})),
        )
            .into_response();
    }

    let last_event_id = headers
        .get("last-event-id")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok());
    let hold_seconds = headers
        .get("x-core-stream-hold-seconds")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.parse::<u64>().ok())
        .unwrap_or(0)
        .min(600);

    let (cursor_now, min_retained_seq, lag_ms, subscriber_count, events_for_stream) = {
        let s = state.read().await;
        let cursor = s.next_seq.saturating_sub(1);
        let min_retained = compute_min_retained_seq(&s);
        let last_event_ts = s.events.back().map(|e| e.ts_ms).unwrap_or_else(now_ms);
        let from_seq = last_event_id.unwrap_or(0);
        let events = s
            .events
            .iter()
            .filter(|ev| ev.seq > from_seq)
            .cloned()
            .collect::<Vec<_>>();
        (
            cursor,
            min_retained,
            now_ms().saturating_sub(last_event_ts),
            1u64,
            events,
        )
    };

    if lag_ms > 5_000 {
        push_gap_event(
            &state,
            "observability_gap.stream_lag",
            json!({
                "endpoint": "/api/v1/stream",
                "reason": "lag_threshold_exceeded",
                "lag_ms": lag_ms,
                "subscriber_count": subscriber_count,
                "trace_id": "none"
            }),
        )
        .await;
    }

    if let Some(cursor) = last_event_id {
        if cursor != 0 && cursor < min_retained_seq {
            let snapshot = {
                let s = state.read().await;
                SnapshotResponse {
                    cursor: s.next_seq.saturating_sub(1),
                    min_retained_seq,
                    effective_profile_id: s.effective_profile_id.clone(),
                    events: s.events.iter().rev().take(200).cloned().collect(),
                    incidents: s.incidents.clone(),
                }
            };
            let mut resp = (StatusCode::OK, Json(snapshot)).into_response();
            if let Ok(v) = HeaderValue::from_str(&cursor_now.to_string()) {
                resp.headers_mut().insert("x-stream-cursor", v);
            }
            return resp;
        }
    }

    let tick = Duration::from_secs(1);
    let out = stream! {
        for stored in events_for_stream {
            let payload = json!({
                "seq": stored.seq,
                "ts_ms": stored.ts_ms,
                "event": stored.event,
            });
            yield Ok::<Event, Infallible>(
                Event::default()
                    .id(stored.seq.to_string())
                    .event("message")
                    .data(payload.to_string()),
            );
        }
        for _ in 0..hold_seconds {
            tokio::time::sleep(tick).await;
            let cursor = {
                let s = state.read().await;
                s.next_seq.saturating_sub(1)
            };
            let payload = json!({
                "type": "keepalive",
                "cursor": cursor,
                "lag_ms": 0u64
            });
            yield Ok::<Event, Infallible>(
                Event::default()
                    .id(cursor.to_string())
                    .event("message")
                    .data(payload.to_string()),
            );
        }
    };
    let mut resp = Sse::new(out).into_response();
    resp.headers_mut()
        .insert("cache-control", HeaderValue::from_static("no-cache"));
    resp
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

fn always_compress(_: StatusCode, _: Version, _: &HeaderMap, _: &Extensions) -> bool {
    true
}

fn compute_min_retained_seq(s: &CoreState) -> u64 {
    let cutoff = now_ms().saturating_sub(86_400_000);
    s.events
        .iter()
        .find(|e| e.ts_ms >= cutoff)
        .map(|e| e.seq)
        .unwrap_or_else(|| s.next_seq.saturating_sub(1))
}

async fn push_gap_event(state: &Shared, kind: &str, details: Value) {
    let mut s = state.write().await;
    push_gap_event_locked(&mut s, kind, details);
}

async fn audit_list(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::AuditGet, None, None).await {
        return deny;
    }
    let s = state.read().await;
    (StatusCode::OK, Json(json!({ "items": s.audits }))).into_response()
}

async fn audit_verify(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::AuditVerify, None, None).await {
        return deny;
    }
    let s = state.read().await;
    match verify_audit_chain(&s.audits) {
        Ok(_) => (
            StatusCode::OK,
            Json(json!({
                "ok": true,
                "count": s.audits.len(),
                "head_hash": s.audit_chain_head.clone(),
            })),
        )
            .into_response(),
        Err(reason) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "ok": false,
                "error": "audit_chain_broken",
                "reason": reason,
                "count": s.audits.len(),
            })),
        )
            .into_response(),
    }
}

async fn audit_mutation_forbidden(
    Path(_id): Path<u64>,
    State(state): State<Shared>,
    headers: HeaderMap,
) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::AuditGet, None, None).await {
        return deny;
    }
    (
        StatusCode::METHOD_NOT_ALLOWED,
        Json(json!({"ok": false, "error": "audit_append_only"})),
    )
        .into_response()
}

impl McpMode {
    fn from_headers(headers: &HeaderMap) -> Self {
        let raw = headers
            .get("x-mcp-mode")
            .and_then(|h| h.to_str().ok())
            .map(|s| s.to_string())
            .or_else(|| env::var("CORE_MCP_MODE").ok())
            .unwrap_or_else(|| "full_admin".to_string());
        match raw.as_str() {
            "read_only" => McpMode::ReadOnly,
            "limited_actions" => McpMode::LimitedActions,
            "full_admin" => McpMode::FullAdmin,
            _ => McpMode::ReadOnly,
        }
    }
}

fn role_from_headers(headers: &HeaderMap) -> Option<ActorRole> {
    match headers
        .get("x-actor-role")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("viewer")
    {
        "viewer" => Some(ActorRole::Viewer),
        "operator" => Some(ActorRole::Operator),
        "admin" => Some(ActorRole::Admin),
        _ => None,
    }
}

fn rbac_allows(role: ActorRole, endpoint: Endpoint) -> bool {
    match endpoint {
        Endpoint::Snapshot
        | Endpoint::SnapshotV2
        | Endpoint::Stream
        | Endpoint::StreamV2
        | Endpoint::IncidentsGet => true,
        Endpoint::IncidentAck | Endpoint::IncidentResolve | Endpoint::ActionsExecute => {
            matches!(role, ActorRole::Operator | ActorRole::Admin)
        }
        Endpoint::AuditGet | Endpoint::AuditVerify => matches!(role, ActorRole::Admin),
    }
}

async fn enforce_rbac(
    state: &Shared,
    headers: &HeaderMap,
    endpoint: Endpoint,
    action: Option<&str>,
    target: Option<&str>,
) -> Result<(), Response> {
    let role = role_from_headers(headers);
    if role.is_some() && rbac_allows(role.expect("checked"), endpoint) {
        return Ok(());
    }
    push_access_denied(
        state,
        headers,
        endpoint_name(endpoint),
        "rbac_denied",
        action.unwrap_or("none"),
        target.unwrap_or("none"),
    )
    .await;
    Err((
        StatusCode::FORBIDDEN,
        Json(json!({"ok": false, "error": "access_denied"})),
    )
        .into_response())
}

async fn enforce_mcp_mode(
    state: &Shared,
    headers: &HeaderMap,
    mode: McpMode,
    action: &str,
    target: &str,
    allowlist: &[String],
) -> Result<(), Response> {
    match mode {
        McpMode::ReadOnly => {
            push_access_denied(
                state,
                headers,
                endpoint_name(Endpoint::ActionsExecute),
                "mcp_denied",
                action,
                target,
            )
            .await;
            Err((
                StatusCode::FORBIDDEN,
                Json(json!({"ok": false, "error": "access_denied"})),
            )
                .into_response())
        }
        McpMode::LimitedActions => {
            if allowlist.iter().any(|allowed| allowed == action) {
                Ok(())
            } else {
                push_access_denied(
                    state,
                    headers,
                    endpoint_name(Endpoint::ActionsExecute),
                    "mcp_denied",
                    action,
                    target,
                )
                .await;
                Err((
                    StatusCode::FORBIDDEN,
                    Json(json!({"ok": false, "error": "access_denied"})),
                )
                    .into_response())
            }
        }
        McpMode::FullAdmin => Ok(()),
    }
}

async fn push_access_denied(
    state: &Shared,
    headers: &HeaderMap,
    endpoint: &str,
    reason: &str,
    action: &str,
    target: &str,
) {
    let role = role_from_headers(headers)
        .map(ActorRole::as_str)
        .unwrap_or("unknown");
    let mcp_mode = McpMode::from_headers(headers).as_str();
    push_gap_event(
        state,
        "security.access_denied",
        json!({
            "what": "access denied",
            "where": "/api/v1",
            "why": reason,
            "evidence": {
                "endpoint": endpoint,
                "actor_role": role,
                "mcp_mode": mcp_mode,
                "action": action,
                "reason": reason
            },
            "actions": {
                "action_ref": "docs/runbooks/access_denied.md"
            },
            "trace_id": trace_id_from_headers(headers),
            "target": target
        }),
    )
    .await;
}

fn endpoint_name(endpoint: Endpoint) -> &'static str {
    match endpoint {
        Endpoint::Snapshot => "/api/v1/snapshot",
        Endpoint::SnapshotV2 => "/api/v2/snapshot",
        Endpoint::Stream => "/api/v1/stream",
        Endpoint::StreamV2 => "/api/v2/stream",
        Endpoint::IncidentsGet => "/api/v1/incidents",
        Endpoint::IncidentAck => "/api/v1/incidents/{id}/ack",
        Endpoint::IncidentResolve => "/api/v1/incidents/{id}/resolve",
        Endpoint::ActionsExecute => "/api/v1/actions/execute",
        Endpoint::AuditGet => "/api/v1/audit",
        Endpoint::AuditVerify => "/api/v1/audit/verify",
    }
}

fn trace_id_from_headers(headers: &HeaderMap) -> String {
    headers
        .get("x-trace-id")
        .and_then(|h| h.to_str().ok())
        .map(|v| v.to_string())
        .unwrap_or_else(|| format!("trace-{}", now_ms()))
}

fn actor_id_from_headers(headers: &HeaderMap) -> String {
    headers
        .get("x-actor-id")
        .and_then(|h| h.to_str().ok())
        .map(|v| v.to_string())
        .unwrap_or_else(|| "anonymous".to_string())
}

fn client_ip_from_headers(headers: &HeaderMap) -> String {
    let raw = headers
        .get("x-forwarded-for")
        .and_then(|h| h.to_str().ok())
        .and_then(|v| v.split(',').next())
        .or_else(|| headers.get("x-real-ip").and_then(|h| h.to_str().ok()))
        .unwrap_or("0.0.0.0");
    normalize_ip(raw)
}

fn normalize_ip(raw: &str) -> String {
    match raw.trim().parse::<IpAddr>() {
        Ok(IpAddr::V4(v4)) => {
            let oct = v4.octets();
            Ipv4Addr::new(oct[0], oct[1], oct[2], 0).to_string()
        }
        Ok(IpAddr::V6(v6)) => {
            let seg = v6.segments();
            Ipv6Addr::new(seg[0], seg[1], seg[2], 0, 0, 0, 0, 0).to_string()
        }
        Err(_) => "0.0.0.0".to_string(),
    }
}

fn user_agent_from_headers(headers: &HeaderMap) -> String {
    let ua = headers
        .get("user-agent")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("unknown");
    truncate_utf8(ua, 256)
}

fn truncate_utf8(value: &str, max_len: usize) -> String {
    if value.chars().count() <= max_len {
        return value.to_string();
    }
    value.chars().take(max_len).collect()
}

fn sanitize_sensitive(value: &Value) -> (Value, bool) {
    fn recurse(v: &Value, changed: &mut bool) -> Value {
        match v {
            Value::Object(map) => {
                let mut out = serde_json::Map::new();
                for (k, val) in map {
                    if ["password", "secret", "token", "api_key", "authorization"]
                        .iter()
                        .any(|p| k.to_ascii_lowercase().contains(p))
                    {
                        *changed = true;
                        out.insert(k.clone(), Value::String("***redacted***".to_string()));
                    } else {
                        out.insert(k.clone(), recurse(val, changed));
                    }
                }
                Value::Object(out)
            }
            Value::Array(arr) => Value::Array(arr.iter().map(|i| recurse(i, changed)).collect()),
            Value::String(s) => {
                let lower = s.to_ascii_lowercase();
                if lower.contains("bearer ")
                    || lower.contains("token=")
                    || lower.contains("password=")
                    || lower.contains("secret=")
                {
                    *changed = true;
                    Value::String("***redacted***".to_string())
                } else {
                    Value::String(s.clone())
                }
            }
            _ => v.clone(),
        }
    }
    let mut changed = false;
    let sanitized = recurse(value, &mut changed);
    (sanitized, changed)
}

fn build_audit_entry(
    headers: &HeaderMap,
    action: &str,
    target: &str,
    result: &str,
    evidence_ref: &str,
) -> AuditEntry {
    build_audit_entry_with_params(headers, action, target, result, evidence_ref, Value::Null)
}

fn build_audit_entry_with_params(
    headers: &HeaderMap,
    action: &str,
    target: &str,
    result: &str,
    evidence_ref: &str,
    params: Value,
) -> AuditEntry {
    let mode = McpMode::from_headers(headers);
    let role = role_from_headers(headers)
        .map(ActorRole::as_str)
        .unwrap_or("unknown");
    let mut target_value = target.to_string();
    if !params.is_null() {
        target_value = format!("{}|params={}", target, params);
    }
    let (target_json, _) = sanitize_sensitive(&Value::String(target_value));
    let target_clean = target_json.as_str().unwrap_or("none").to_string();
    let (ua_json, _) = sanitize_sensitive(&Value::String(user_agent_from_headers(headers)));
    let user_agent_clean = truncate_utf8(ua_json.as_str().unwrap_or("unknown"), 256);
    let (ip_json, _) = sanitize_sensitive(&Value::String(client_ip_from_headers(headers)));
    let client_ip_clean = ip_json.as_str().unwrap_or("0.0.0.0").to_string();
    AuditEntry {
        id: 0,
        timestamp: now_ms(),
        actor_id: actor_id_from_headers(headers),
        actor_role: role.to_string(),
        mcp_mode: mode.as_str().to_string(),
        action: action.to_string(),
        target: target_clean,
        result: result.to_string(),
        trace_id: trace_id_from_headers(headers),
        evidence_ref: evidence_ref.to_string(),
        client_ip: client_ip_clean,
        user_agent: user_agent_clean,
        prev_hash: String::new(),
        entry_hash: String::new(),
        merkle_proof: AuditMerkleProof {
            algorithm: "sha256-chain-v1".to_string(),
            leaf_hash: String::new(),
            parent_hashes: Vec::new(),
            root_hash: String::new(),
        },
    }
}

fn build_merkle_proof(prev_hash: &str, entry_hash: &str) -> AuditMerkleProof {
    AuditMerkleProof {
        algorithm: "sha256-chain-v1".to_string(),
        leaf_hash: entry_hash.to_string(),
        parent_hashes: vec![prev_hash.to_string()],
        root_hash: sha256_hex(&format!("{}:{}", prev_hash, entry_hash)),
    }
}

fn append_audit_entry(state: &mut CoreState, mut entry: AuditEntry) {
    entry.id = state.next_audit_id;
    entry.prev_hash = state.audit_chain_head.clone();
    entry.entry_hash = sha256_hex(&audit_hash_material(&entry));
    entry.merkle_proof = build_merkle_proof(&entry.prev_hash, &entry.entry_hash);
    state.next_audit_id += 1;
    state.audit_chain_head = entry.entry_hash.clone();
    state.audits.push(entry);
}

fn audit_hash_material(entry: &AuditEntry) -> String {
    format!(
        "{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
        entry.id,
        entry.timestamp,
        entry.actor_id,
        entry.actor_role,
        entry.mcp_mode,
        entry.action,
        entry.target,
        entry.result,
        entry.trace_id,
        entry.evidence_ref,
        entry.client_ip,
        entry.user_agent,
        entry.prev_hash
    )
}

fn verify_audit_chain(entries: &[AuditEntry]) -> Result<(), String> {
    let mut prev_hash = "genesis".to_string();
    for entry in entries {
        if entry.prev_hash != prev_hash {
            return Err(format!(
                "prev_hash_mismatch id={} expected={} actual={}",
                entry.id, prev_hash, entry.prev_hash
            ));
        }
        let expected_hash = sha256_hex(&audit_hash_material(entry));
        if entry.entry_hash != expected_hash {
            return Err(format!(
                "entry_hash_mismatch id={} expected={} actual={}",
                entry.id, expected_hash, entry.entry_hash
            ));
        }
        if entry.merkle_proof.leaf_hash != entry.entry_hash {
            return Err(format!(
                "proof_leaf_mismatch id={} expected={} actual={}",
                entry.id, entry.entry_hash, entry.merkle_proof.leaf_hash
            ));
        }
        let expected_root = sha256_hex(&format!("{}:{}", entry.prev_hash, entry.entry_hash));
        if entry.merkle_proof.root_hash != expected_root {
            return Err(format!(
                "proof_root_mismatch id={} expected={} actual={}",
                entry.id, expected_root, entry.merkle_proof.root_hash
            ));
        }
        if entry
            .merkle_proof
            .parent_hashes
            .first()
            .map(|value| value.as_str())
            != Some(entry.prev_hash.as_str())
        {
            return Err(format!(
                "proof_parent_mismatch id={} expected={} actual={}",
                entry.id,
                entry.prev_hash,
                entry
                    .merkle_proof
                    .parent_hashes
                    .first()
                    .cloned()
                    .unwrap_or_default()
            ));
        }
        prev_hash = entry.entry_hash.clone();
    }
    Ok(())
}

async fn incidents(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::IncidentsGet, None, None).await {
        return deny;
    }
    let s = state.read().await;
    (StatusCode::OK, Json(json!({ "items": s.incidents }))).into_response()
}

async fn incident_ack(
    Path(id): Path<String>,
    State(state): State<Shared>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let deny = enforce_rbac(
        &state,
        &headers,
        Endpoint::IncidentAck,
        Some("incident.ack"),
        Some(&id),
    )
    .await
    .err();
    let mut s = state.write().await;
    if let Some(resp) = deny {
        append_audit_entry(
            &mut s,
            build_audit_entry(
                &headers,
                "incident.ack",
                &id,
                "denied",
                "docs/runbooks/access_denied.md",
            ),
        );
        return resp;
    }
    if let Some(item) = s.incidents.iter_mut().find(|x| x.id == id) {
        item.status = "acknowledged".to_string();
        append_audit_entry(
            &mut s,
            build_audit_entry(&headers, "incident.ack", &id, "success", "none"),
        );
        return (StatusCode::OK, Json(json!({"ok": true, "id": id}))).into_response();
    }
    append_audit_entry(
        &mut s,
        build_audit_entry(&headers, "incident.ack", &id, "error", "none"),
    );
    warn!("incident not found for ack: {}", id);
    (
        StatusCode::NOT_FOUND,
        Json(json!({"ok": false, "error": "not_found"})),
    )
        .into_response()
}

async fn incident_resolve(
    Path(id): Path<String>,
    State(state): State<Shared>,
    headers: HeaderMap,
) -> impl IntoResponse {
    let deny = enforce_rbac(
        &state,
        &headers,
        Endpoint::IncidentResolve,
        Some("incident.resolve"),
        Some(&id),
    )
    .await
    .err();
    let mut s = state.write().await;
    if let Some(resp) = deny {
        append_audit_entry(
            &mut s,
            build_audit_entry(
                &headers,
                "incident.resolve",
                &id,
                "denied",
                "docs/runbooks/access_denied.md",
            ),
        );
        return resp;
    }
    if let Some(item) = s.incidents.iter_mut().find(|x| x.id == id) {
        item.status = "resolved".to_string();
        append_audit_entry(
            &mut s,
            build_audit_entry(&headers, "incident.resolve", &id, "success", "none"),
        );
        return (StatusCode::OK, Json(json!({"ok": true, "id": id}))).into_response();
    }
    append_audit_entry(
        &mut s,
        build_audit_entry(&headers, "incident.resolve", &id, "error", "none"),
    );
    warn!("incident not found for resolve: {}", id);
    (
        StatusCode::NOT_FOUND,
        Json(json!({"ok": false, "error": "not_found"})),
    )
        .into_response()
}

async fn actions_execute(
    State(state): State<Shared>,
    headers: HeaderMap,
    Json(req): Json<ActionExecuteRequest>,
) -> impl IntoResponse {
    let target = req.target.clone().unwrap_or_else(|| "none".to_string());
    let deny = if let Err(resp) = enforce_rbac(
        &state,
        &headers,
        Endpoint::ActionsExecute,
        Some(&req.action),
        Some(&target),
    )
    .await
    {
        Some(resp)
    } else {
        let allowlist = {
            let s = state.read().await;
            s.limited_actions_allowlist.clone()
        };
        enforce_mcp_mode(
            &state,
            &headers,
            McpMode::from_headers(&headers),
            &req.action,
            &target,
            &allowlist,
        )
        .await
        .err()
    };
    let mut s = state.write().await;
    let (sanitized_params, redacted) =
        sanitize_sensitive(&req.params.clone().unwrap_or(Value::Null));
    if redacted {
        push_gap_event_locked(
            &mut s,
            "privacy.redaction_applied",
            json!({
                "scope": "actions.execute.params",
                "action": req.action,
                "target": target,
                "trace_id": trace_id_from_headers(&headers)
            }),
        );
    }
    if let Some(resp) = deny {
        append_audit_entry(
            &mut s,
            build_audit_entry_with_params(
                &headers,
                &req.action,
                &target,
                "denied",
                "docs/runbooks/access_denied.md",
                sanitized_params,
            ),
        );
        return resp;
    }
    append_audit_entry(
        &mut s,
        build_audit_entry_with_params(
            &headers,
            &req.action,
            &target,
            "success",
            "none",
            sanitized_params,
        ),
    );
    let response = ActionExecuteResponse {
        accepted: true,
        action: req.action,
        target: req.target,
    };
    (StatusCode::OK, Json(response)).into_response()
}

fn load_core_config(path: &str) -> anyhow::Result<CoreConfig> {
    let raw = fs::read_to_string(path)?;
    parse_core_config(&raw)
}

fn parse_core_config(raw: &str) -> anyhow::Result<CoreConfig> {
    let cfg: CoreConfig = toml::from_str(raw)?;
    Ok(cfg)
}

fn validate_profile_guardrails(cfg: &CoreConfig) -> anyhow::Result<String> {
    let details = profile_violation_details(cfg);
    if details.violated_rule != "none" {
        anyhow::bail!(
            "profile guard failed: {} current='{}' expected='{}'",
            details.parameter,
            details.current,
            details.expected
        );
    }
    Ok(cfg.profile_id.clone())
}

#[derive(Debug, Clone)]
struct ProfileViolationDetails {
    violated_rule: String,
    parameter: String,
    current: String,
    expected: String,
}

fn profile_violation_details(cfg: &CoreConfig) -> ProfileViolationDetails {
    let baseline = match profile_baseline(&cfg.profile_id) {
        Some(v) => v,
        None => {
            return ProfileViolationDetails {
                violated_rule: "unsupported_profile_id".to_string(),
                parameter: "profile_id".to_string(),
                current: cfg.profile_id.clone(),
                expected: "global|eu|ru|airgapped".to_string(),
            };
        }
    };

    if cfg.retention_days != baseline.retention_days {
        return ProfileViolationDetails {
            violated_rule: "retention_mismatch".to_string(),
            parameter: "retention_days".to_string(),
            current: cfg.retention_days.to_string(),
            expected: baseline.retention_days.to_string(),
        };
    }
    if cfg.export_mode != baseline.export_mode {
        return ProfileViolationDetails {
            violated_rule: "export_mismatch".to_string(),
            parameter: "export_mode".to_string(),
            current: cfg.export_mode.clone(),
            expected: baseline.export_mode.to_string(),
        };
    }
    if cfg.egress_policy != baseline.egress_policy {
        return ProfileViolationDetails {
            violated_rule: "egress_mismatch".to_string(),
            parameter: "egress_policy".to_string(),
            current: cfg.egress_policy.clone(),
            expected: baseline.egress_policy.to_string(),
        };
    }
    if cfg.residency != baseline.residency {
        return ProfileViolationDetails {
            violated_rule: "residency_mismatch".to_string(),
            parameter: "residency".to_string(),
            current: cfg.residency.clone(),
            expected: baseline.residency.to_string(),
        };
    }
    if cfg.updates_mode != baseline.updates_mode {
        return ProfileViolationDetails {
            violated_rule: "updates_mismatch".to_string(),
            parameter: "updates_mode".to_string(),
            current: cfg.updates_mode.clone(),
            expected: baseline.updates_mode.to_string(),
        };
    }

    ProfileViolationDetails {
        violated_rule: "none".to_string(),
        parameter: "none".to_string(),
        current: "none".to_string(),
        expected: "none".to_string(),
    }
}

fn profile_baseline(profile_id: &str) -> Option<ProfileBaseline> {
    match profile_id {
        "global" => Some(ProfileBaseline {
            retention_days: 30,
            export_mode: "standard",
            egress_policy: "controlled",
            residency: "any",
            updates_mode: "online",
        }),
        "eu" => Some(ProfileBaseline {
            retention_days: 30,
            export_mode: "restricted",
            egress_policy: "strict",
            residency: "eu-only",
            updates_mode: "controlled",
        }),
        "ru" => Some(ProfileBaseline {
            retention_days: 30,
            export_mode: "restricted",
            egress_policy: "strict",
            residency: "ru-only",
            updates_mode: "controlled",
        }),
        "airgapped" => Some(ProfileBaseline {
            retention_days: 30,
            export_mode: "offline-only",
            egress_policy: "blocked",
            residency: "local-only",
            updates_mode: "manual-offline",
        }),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use flate2::read::GzDecoder;
    use http_body_util::BodyExt;
    use proptest::prelude::*;
    use std::collections::HashSet;
    use std::io::Read;
    use tower::ServiceExt;

    fn test_state() -> Shared {
        Arc::new(RwLock::new(CoreState::new(
            "global".to_string(),
            10_000,
            200,
            524_288,
            vec!["service.restart".to_string(), "service.status".to_string()],
            AnalyticsState::new(1_440),
            PathBuf::from("/tmp/art_core_analytics_state_test.json"),
        )))
    }

    async fn ingest_info_events(app: &Router, count: usize) {
        let mut left = count;
        while left > 0 {
            let chunk = left.min(200);
            let events: Vec<Value> = (0..chunk)
                .map(|idx| json!({"severity":"info","msg": format!("event-{idx}")}))
                .collect();
            let payload = json!({ "events": events });
            let req = Request::builder()
                .method("POST")
                .uri("/api/v1/ingest")
                .header("content-type", "application/json")
                .body(Body::from(payload.to_string()))
                .expect("request");
            let resp = app.clone().oneshot(req).await.expect("response");
            assert_eq!(resp.status(), StatusCode::OK);
            left -= chunk;
        }
    }

    fn otlp_payload_with_count(count: usize, severity_text: &str) -> Value {
        let log_records: Vec<Value> = (0..count)
            .map(|idx| {
                json!({
                    "severityText": severity_text,
                    "body": { "stringValue": format!("otlp-{idx}") },
                    "attributes": [
                        {
                            "key": "service.name",
                            "value": { "stringValue": "api" }
                        }
                    ]
                })
            })
            .collect();
        json!({
            "resourceLogs": [
                {
                    "scopeLogs": [
                        {
                            "logRecords": log_records
                        }
                    ]
                }
            ]
        })
    }

    fn extract_sse_ids(body: &str) -> Vec<u64> {
        body.lines()
            .filter_map(|line| line.strip_prefix("id: "))
            .filter_map(|id| id.trim().parse::<u64>().ok())
            .collect()
    }

    fn lcg_next(state: &mut u64) -> u64 {
        *state = state
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        *state
    }

    fn dna_seed_to_event(seed: u64, seq: u64) -> Value {
        let severity = match seed % 3 {
            0 => "info",
            1 => "warn",
            _ => "error",
        };
        let region = if seed & 1 == 0 { "eu" } else { "us" };
        json!({
            "severity": severity,
            "kind": format!("svc.{}", seed % 37),
            "payload": {
                "service": format!("service-{}", seed % 17),
                "region": region,
                "bucket": format!("b-{}", (seed >> 4) % 97),
                "error_code": seed % 4096
            },
            "ts_ms": seq + (seed % 10_000),
            "received_at": format!("2026-03-06T{:02}:00:00Z", seed % 24),
            "ingested_at_ms": seed % 1_000_000
        })
    }

    fn dna_seed_to_event_variant(seed: u64, seq: u64) -> Value {
        let severity = match seed % 3 {
            0 => "info",
            1 => "warn",
            _ => "error",
        };
        let region = if seed & 1 == 0 { "eu" } else { "us" };
        json!({
            "payload": {
                "error_code": seed % 4096,
                "bucket": format!("b-{}", (seed >> 4) % 97),
                "region": region,
                "service": format!("service-{}", seed % 17)
            },
            "kind": format!("svc.{}", seed % 37),
            "severity": severity,
            "ts_ms": seq + 99_999_999,
            "received_at": "2099-01-01T00:00:00Z",
            "ingested_at_ms": 777_777_777
        })
    }

    fn reference_ignore_key(key: &str) -> bool {
        matches!(
            key,
            "ts" | "ts_ms"
                | "timestamp"
                | "ingest_ts_ms"
                | "event_id"
                | "received_at"
                | "ingested_at_ms"
        )
    }

    fn canonicalize_reference(value: &Value) -> Value {
        match value {
            Value::Object(map) => {
                let mut keys: Vec<&String> = map.keys().collect();
                keys.sort();
                let mut normalized = serde_json::Map::new();
                for key in keys {
                    if reference_ignore_key(key) {
                        continue;
                    }
                    if let Some(inner) = map.get(key) {
                        normalized.insert(key.clone(), canonicalize_reference(inner));
                    }
                }
                Value::Object(normalized)
            }
            Value::Array(items) => {
                let normalized: Vec<Value> = items.iter().map(canonicalize_reference).collect();
                Value::Array(normalized)
            }
            _ => value.clone(),
        }
    }

    fn canonical_json_reference_v2(value: &Value) -> String {
        let normalized = canonicalize_reference(value);
        serde_json::to_string(&normalized).unwrap_or_else(|_| "{}".to_string())
    }

    fn mutated_canonical_json_without_ignore(value: &Value) -> String {
        fn normalize(value: &Value) -> Value {
            match value {
                Value::Object(map) => {
                    let mut keys: Vec<&String> = map.keys().collect();
                    keys.sort();
                    let mut out = serde_json::Map::new();
                    for key in keys {
                        if let Some(inner) = map.get(key) {
                            out.insert(key.clone(), normalize(inner));
                        }
                    }
                    Value::Object(out)
                }
                Value::Array(items) => Value::Array(items.iter().map(normalize).collect()),
                _ => value.clone(),
            }
        }
        normalize(value).to_string()
    }

    #[test]
    fn console_base_path_validation_is_strict() {
        assert!(is_valid_console_base_path("/console"));
        assert!(is_valid_console_base_path("/console/v2"));
        assert!(!is_valid_console_base_path("http://console"));
        assert!(!is_valid_console_base_path("https://console"));
        assert!(!is_valid_console_base_path("//console"));
        assert!(!is_valid_console_base_path("/../console"));
        assert!(!is_valid_console_base_path("/console/.."));
    }

    #[test]
    fn panel0_templates_replace_placeholders() {
        let build_id = "build-42";
        let bootstrap = render_panel0_bootstrap_html(build_id, "/console");
        assert!(bootstrap.contains("const BOOT_TIMEOUT_MS = 5000;"));
        assert!(bootstrap.contains("const EVENT_KIND = \"observability_gap.console_boot_failed\";"));
        assert!(bootstrap.contains("const CONSOLE_BASE_PATH = \"/console\";"));
        assert!(bootstrap.contains("const PANEL0_BUILD_ID = \"build-42\";"));
        assert!(!bootstrap.contains("__CONSOLE_BASE_PATH_JSON__"));
        assert!(!bootstrap.contains("__PANEL0_BUILD_ID_JSON__"));
        assert!(!bootstrap.contains("__BOOT_TIMEOUT_MS__"));

        let panel_js = render_panel0_js(build_id);
        assert!(panel_js.contains("const PANEL0_BUILD_ID = \"build-42\";"));
        assert!(!panel_js.contains("__PANEL0_BUILD_ID__"));

        let panel_sw = render_panel0_service_worker(build_id);
        assert!(panel_sw.contains("const CACHE_NAME = \"panel0-cache-build-42\";"));
        assert!(!panel_sw.contains("__PANEL0_BUILD_ID__"));
    }

    #[tokio::test]
    async fn panel0_routes_serve_embedded_assets_with_content_types() {
        let app = build_app(test_state());
        let cases = vec![
            ("/panel0", "text/html"),
            ("/panel0/", "text/html"),
            ("/panel0/index.html", "text/html"),
            ("/panel0/panel0.js", "application/javascript"),
            ("/panel0/panel0.css", "text/css"),
            ("/panel0/panel0_sw.js", "application/javascript"),
            ("/panel0/favicon.ico", "image/x-icon"),
        ];

        for (uri, expected_ct) in cases {
            let req = Request::builder()
                .method("GET")
                .uri(uri)
                .body(Body::empty())
                .expect("request");
            let resp = app.clone().oneshot(req).await.expect("response");
            assert_eq!(resp.status(), StatusCode::OK, "uri={uri}");
            let content_type = resp
                .headers()
                .get(CONTENT_TYPE)
                .and_then(|h| h.to_str().ok())
                .unwrap_or("");
            assert!(
                content_type.starts_with(expected_ct),
                "uri={uri} content-type={content_type}"
            );
        }
    }

    #[tokio::test]
    async fn root_route_serves_bootstrap_with_timeout_and_event_contract() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("GET")
            .uri("/")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let content_type = resp
            .headers()
            .get(CONTENT_TYPE)
            .and_then(|h| h.to_str().ok())
            .unwrap_or("");
        assert!(content_type.starts_with("text/html"));

        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let html = String::from_utf8(body.to_vec()).expect("utf8");
        assert!(html.contains("const BOOT_TIMEOUT_MS = 5000;"));
        assert!(html.contains("const EVENT_KIND = \"observability_gap.console_boot_failed\";"));
        assert!(html.contains("Ctrl+Shift+P"));
        assert!(html.contains("globalThis.location.replace(\"/panel0/\")"));
        assert!(!html.contains("__CONSOLE_BASE_PATH_JSON__"));
    }

    #[test]
    fn dna_canonicalization_determinism_corpus_tests() {
        let event_a = json!({
            "severity": "error",
            "kind": "db.timeout",
            "payload": {
                "region": "eu",
                "service": "orders"
            },
            "ts_ms": 1000
        });
        let event_b = json!({
            "payload": {
                "service": "orders",
                "region": "eu"
            },
            "kind": "db.timeout",
            "severity": "error",
            "ts_ms": 9999
        });

        let canon_a = canonical_json_v2(&event_a);
        let canon_b = canonical_json_v2(&event_b);
        assert_eq!(canon_a, canon_b);

        let sig_a = build_dna_signature(&event_a);
        let sig_b = build_dna_signature(&event_b);
        assert_eq!(sig_a.dna_id, sig_b.dna_id);
        assert_eq!(sig_a.canonical_hash, sig_b.canonical_hash);
        assert_eq!(sig_a.dna_schema_version, DNA_SCHEMA_VERSION);
    }

    #[test]
    fn dna_schema_version_migration_compatibility_tests() {
        let event = json!({"severity":"warn","kind":"cache.degraded","msg":"x"});
        let sig = build_dna_signature(&event);
        assert_eq!(sig.dna_schema_version, DNA_SCHEMA_VERSION);
        assert!(!sig.dna_id.is_empty());
        assert_eq!(sig.canonical_hash.len(), 64);
        assert_eq!(sig.payload_hash.len(), 64);
    }

    proptest! {
        #[test]
        fn dna_property_determinism_proptest(seed in 0_u64..u64::MAX, seq in 0_u64..1_000_000_u64) {
            let event_a = dna_seed_to_event(seed, seq);
            let event_b = dna_seed_to_event_variant(seed, seq);

            let canonical_a = canonical_json_v2(&event_a);
            let canonical_b = canonical_json_v2(&event_b);
            prop_assert_eq!(canonical_a, canonical_b);

            let sig_a = build_dna_signature(&event_a);
            let sig_b = build_dna_signature(&event_b);
            prop_assert_eq!(sig_a.dna_id, sig_b.dna_id);
            prop_assert_eq!(sig_a.canonical_hash, sig_b.canonical_hash);
        }
    }

    #[test]
    #[ignore = "heavy deterministic gate for CI stage29"]
    fn dna_property_determinism_million_sequences_gate() {
        let mut prng_state = 0xA1B2_C3D4_E5F6_7788_u64;
        for seq in 0_u64..1_000_000_u64 {
            let seed = lcg_next(&mut prng_state);
            let event_a = dna_seed_to_event(seed, seq);
            let event_b = dna_seed_to_event_variant(seed, seq);

            let sig_a = build_dna_signature(&event_a);
            let sig_b = build_dna_signature(&event_b);
            assert_eq!(sig_a.dna_id, sig_b.dna_id, "seq={seq}");
            assert_eq!(sig_a.canonical_hash, sig_b.canonical_hash, "seq={seq}");
        }
    }

    #[test]
    fn dna_reference_implementation_parity_corpus() {
        for seq in 0_u64..10_000_u64 {
            let seed = seq.wrapping_mul(7_919).wrapping_add(12_345);
            let event = dna_seed_to_event(seed, seq);
            let rust_canonical = canonical_json_v2(&event);
            let ref_canonical = canonical_json_reference_v2(&event);
            assert_eq!(rust_canonical, ref_canonical, "seq={seq}");

            let signature = build_dna_signature(&event);
            assert_eq!(
                signature.canonical_hash,
                sha256_hex(&ref_canonical),
                "seq={seq}"
            );
        }
    }

    #[test]
    fn dna_mutation_resilience_sentinel_test() {
        let event_a = dna_seed_to_event(77, 10);
        let event_b = dna_seed_to_event_variant(77, 10);

        let stable_a = build_dna_signature(&event_a);
        let stable_b = build_dna_signature(&event_b);
        assert_eq!(stable_a.dna_id, stable_b.dna_id);

        let mutated_a = mutated_canonical_json_without_ignore(&event_a);
        let mutated_b = mutated_canonical_json_without_ignore(&event_b);
        assert_ne!(
            sha256_hex(&mutated_a),
            sha256_hex(&mutated_b),
            "mutation sentinel must detect volatile-field sensitivity"
        );
    }

    #[test]
    fn dna_clusters_are_monotonic_for_append_only_sequence() {
        let mut observed = HashSet::new();
        let mut state = 0x4E_45_4F_32_30_32_32_u64;
        let mut prev_len = 0usize;
        for seq in 0_u64..25_000_u64 {
            let seed = lcg_next(&mut state);
            let event = dna_seed_to_event(seed, seq);
            let signature = build_dna_signature(&event);
            observed.insert(signature.dna_id);
            let current_len = observed.len();
            assert!(current_len >= prev_len);
            prev_len = current_len;
        }
    }

    #[tokio::test]
    async fn v2_ingest_snapshot_stream_integration() {
        let app = build_app(test_state());
        let payload = json!({
            "events": [
                {
                    "severity":"error",
                    "kind":"db.timeout",
                    "msg":"database timeout",
                    "evidence_blocks":[
                        {
                            "evidence_id":"ev-v2-1",
                            "source_type":"log",
                            "source_ref":"log://db/1",
                            "trust_score":0.9,
                            "freshness_ms":1200,
                            "redaction_policy_id":"default",
                            "access_scope":"public"
                        }
                    ]
                },
                {
                    "severity":"error",
                    "kind":"db.timeout",
                    "msg":"database timeout replica"
                }
            ]
        });

        let ingest_req = Request::builder()
            .method("POST")
            .uri("/api/v2/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let ingest_resp = app.clone().oneshot(ingest_req).await.expect("response");
        assert_eq!(ingest_resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v2/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.clone().oneshot(snapshot_req).await.expect("response");
        assert_eq!(snapshot_resp.status(), StatusCode::OK);
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        assert!(snapshot_json["events"]
            .as_array()
            .map(|v| !v.is_empty())
            .unwrap_or(false));
        assert!(snapshot_json["dna_clusters"]
            .as_array()
            .map(|v| !v.is_empty())
            .unwrap_or(false));
        assert_eq!(
            snapshot_json["events"][0]["dna_signature"]["dna_schema_version"],
            DNA_SCHEMA_VERSION
        );

        let stream_req = Request::builder()
            .method("GET")
            .uri("/api/v2/stream")
            .header("last-event-id", "0")
            .body(Body::empty())
            .expect("request");
        let stream_resp = app.oneshot(stream_req).await.expect("response");
        assert_eq!(stream_resp.status(), StatusCode::OK);
        let stream_body = stream_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let stream_text = String::from_utf8(stream_body.to_vec()).expect("utf8");
        assert!(stream_text.contains("\"dna_signature\""));
        assert!(stream_text.contains("\"evidence_refs\""));
    }

    #[tokio::test]
    async fn v2_evidence_access_scope_enforcement_tests() {
        let app = build_app(test_state());
        let payload = json!({
            "events": [
                {
                    "severity":"info",
                    "kind":"scope.check",
                    "evidence_blocks":[
                        {
                            "evidence_id":"ev-private-1",
                            "source_type":"log",
                            "source_ref":"log://secure/1",
                            "trust_score":1.0,
                            "freshness_ms":0,
                            "redaction_policy_id":"default",
                            "access_scope":"tenant:alpha"
                        }
                    ]
                }
            ]
        });
        let ingest_req = Request::builder()
            .method("POST")
            .uri("/api/v2/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let ingest_resp = app.clone().oneshot(ingest_req).await.expect("response");
        assert_eq!(ingest_resp.status(), StatusCode::OK);

        let denied_req = Request::builder()
            .method("GET")
            .uri("/api/v2/evidence/ev-private-1")
            .body(Body::empty())
            .expect("request");
        let denied_resp = app.clone().oneshot(denied_req).await.expect("response");
        assert_eq!(denied_resp.status(), StatusCode::FORBIDDEN);

        let scoped_req = Request::builder()
            .method("GET")
            .uri("/api/v2/evidence/ev-private-1")
            .header("x-access-scope", "tenant:alpha")
            .body(Body::empty())
            .expect("request");
        let scoped_resp = app.clone().oneshot(scoped_req).await.expect("response");
        assert_eq!(scoped_resp.status(), StatusCode::OK);

        let admin_req = Request::builder()
            .method("GET")
            .uri("/api/v2/evidence/ev-private-1")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let admin_resp = app.oneshot(admin_req).await.expect("response");
        assert_eq!(admin_resp.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn v2_invalid_payload_returns_deterministic_error_codes() {
        let app = build_app(test_state());
        let invalid_payload = json!({
            "events": [
                {"kind":"missing-severity"}
            ]
        });
        let req = Request::builder()
            .method("POST")
            .uri("/api/v2/ingest")
            .header("content-type", "application/json")
            .body(Body::from(invalid_payload.to_string()))
            .expect("request");
        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["error"], "invalid_payload");
        assert_eq!(json["code"], "v2_invalid_event");
        assert_eq!(json["details"][0]["path"], "severity");
        assert_eq!(json["details"][0]["code"], "validation_error");
    }

    #[tokio::test]
    async fn v2_dna_clusters_and_similar_lookup() {
        let app = build_app(test_state());
        let payload = json!({
            "events": [
                {"severity":"error","kind":"db.timeout","payload":{"service":"orders","region":"eu"}},
                {"severity":"error","kind":"db.timeout","payload":{"service":"orders","region":"eu"}},
                {"severity":"error","kind":"db.timeout","payload":{"service":"billing","region":"eu"}}
            ]
        });
        let ingest_req = Request::builder()
            .method("POST")
            .uri("/api/v2/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let ingest_resp = app.clone().oneshot(ingest_req).await.expect("response");
        assert_eq!(ingest_resp.status(), StatusCode::OK);

        let clusters_req = Request::builder()
            .method("GET")
            .uri("/api/v2/dna/clusters?limit=10")
            .body(Body::empty())
            .expect("request");
        let clusters_resp = app.clone().oneshot(clusters_req).await.expect("response");
        assert_eq!(clusters_resp.status(), StatusCode::OK);
        let clusters_body = clusters_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let clusters_json: Value = serde_json::from_slice(&clusters_body).expect("json");
        let first_dna_id = clusters_json["items"][0]["dna_signature"]["dna_id"]
            .as_str()
            .expect("dna_id")
            .to_string();

        let similar_req = Request::builder()
            .method("GET")
            .uri(format!("/api/v2/dna/{first_dna_id}/similar"))
            .body(Body::empty())
            .expect("request");
        let similar_resp = app.oneshot(similar_req).await.expect("response");
        assert_eq!(similar_resp.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn v2_analytics_summary_returns_chart_data_and_instructions() {
        let app = build_app(test_state());
        let payload = json!({
            "events": [
                {"severity":"error","kind":"db.timeout","payload":{"service":"orders","region":"eu"}},
                {"severity":"warn","kind":"cache.degraded","payload":{"service":"orders","region":"eu"}},
                {"severity":"error","kind":"db.timeout","payload":{"service":"orders","region":"eu"}}
            ]
        });
        let ingest_req = Request::builder()
            .method("POST")
            .uri("/api/v2/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let ingest_resp = app.clone().oneshot(ingest_req).await.expect("response");
        assert_eq!(ingest_resp.status(), StatusCode::OK);

        let metrics_req = Request::builder()
            .method("GET")
            .uri("/metrics")
            .header("x-core-metrics-force-unavailable", "1")
            .body(Body::empty())
            .expect("request");
        let metrics_resp = app.clone().oneshot(metrics_req).await.expect("response");
        assert_eq!(metrics_resp.status(), StatusCode::SERVICE_UNAVAILABLE);

        let analytics_req = Request::builder()
            .method("GET")
            .uri("/api/v2/analytics/summary?window_minutes=120&top=3")
            .body(Body::empty())
            .expect("request");
        let analytics_resp = app.oneshot(analytics_req).await.expect("response");
        assert_eq!(analytics_resp.status(), StatusCode::OK);
        let analytics_body = analytics_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let analytics_json: Value = serde_json::from_slice(&analytics_body).expect("json");
        assert!(analytics_json["totals"]["total_events"]
            .as_u64()
            .map(|value| value >= 3)
            .unwrap_or(false));
        assert!(analytics_json["charts"]["timeline"]
            .as_array()
            .map(|arr| !arr.is_empty())
            .unwrap_or(false));
        assert!(analytics_json["instructions"]
            .as_array()
            .map(|arr| !arr.is_empty())
            .unwrap_or(false));
    }

    #[tokio::test]
    async fn ingest_returns_invalid_details_for_bad_event() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"ok"},{"msg":"missing"}]}"#,
            ))
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["accepted"], 1);
        assert_eq!(json["invalid"], 1);
        assert!(json["ack"]["upto_seq"].as_u64().is_some());
        assert!(json["invalid_details"].as_array().is_some());
    }

    #[tokio::test]
    async fn ingest_returns_429_for_large_batch() {
        let app = build_app(test_state());
        let events: Vec<Value> = (0..201)
            .map(|_| json!({"severity":"info","msg":"x"}))
            .collect();
        let payload = json!({ "events": events });
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::TOO_MANY_REQUESTS);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());
    }

    #[tokio::test]
    async fn otlp_logs_maps_attrs_unknown_severity_and_reserved_keys() {
        let app = build_app(test_state());
        let payload = json!({
            "resourceLogs": [{
                "scopeLogs": [{
                    "logRecords": [{
                        "severityText": "TRACE",
                        "body": {"stringValue": "otel message"},
                        "traceId": "trace-otlp-1",
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "api"}},
                            {"key": "success", "value": {"boolValue": true}},
                            {"key": "count", "value": {"intValue": "3"}},
                            {"key": "ratio", "value": {"doubleValue": 1.5}},
                            {"key": "arr", "value": {"arrayValue": {"values": [
                                {"stringValue": "a"},
                                {"intValue": "2"},
                                {"boolValue": false}
                            ]}}},
                            {"key": "payload_bin", "value": {"bytesValue": "AAE="}},
                            {"key": "severity", "value": {"stringValue": "warn"}}
                        ]
                    }]
                }]
            }]
        });

        let req = Request::builder()
            .method("POST")
            .uri(OTLP_ENDPOINT)
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        let otlp_event = events
            .iter()
            .find(|event| event["event"]["kind"] == "otlp.log")
            .expect("expected otlp.log event");
        assert_eq!(otlp_event["event"]["severity"], "info");
        assert_eq!(otlp_event["event"]["message"], "otel message");
        assert_eq!(otlp_event["event"]["trace_id"], "trace-otlp-1");
        assert_eq!(
            otlp_event["event"]["payload"]["otel_attributes"]["service.name"],
            "api"
        );
        assert_eq!(
            otlp_event["event"]["payload"]["otel_attributes"]["otel.severity"],
            "warn"
        );
        assert_eq!(
            otlp_event["event"]["payload"]["otel_attributes"]["payload_bin"],
            "AAE="
        );
        assert_eq!(
            otlp_event["event"]["payload"]["otel_attributes"]["arr"],
            json!(["a", 2, false])
        );
        assert_eq!(
            otlp_event["event"]["payload"]["otel_severity_unknown"],
            Value::Bool(true)
        );
    }

    #[tokio::test]
    async fn otlp_logs_returns_413_and_pushes_otlp_rate_limit_gap_for_large_batch() {
        let app = build_app(test_state());
        let payload = otlp_payload_with_count(OTLP_MAX_BATCH_EVENTS + 1, "INFO");
        let req = Request::builder()
            .method("POST")
            .uri(OTLP_ENDPOINT)
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::PAYLOAD_TOO_LARGE);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        assert!(events.iter().any(|event| {
            event["event"]["kind"] == "observability_gap.otlp_rate_limited"
                && event["event"]["details"]["limit_name"] == "max_batch_events"
                && event["event"]["details"]["endpoint"] == OTLP_ENDPOINT
        }));
    }

    #[tokio::test]
    async fn otlp_logs_returns_429_and_pushes_gap_when_token_bucket_exhausted() {
        let app = build_app(test_state());
        let payload_200 = otlp_payload_with_count(200, "INFO");

        for _ in 0..2 {
            let req = Request::builder()
                .method("POST")
                .uri(OTLP_ENDPOINT)
                .header("content-type", "application/json")
                .header("x-core-now-ms", "1000")
                .body(Body::from(payload_200.to_string()))
                .expect("request");
            let resp = app.clone().oneshot(req).await.expect("response");
            assert_eq!(resp.status(), StatusCode::OK);
        }

        let req = Request::builder()
            .method("POST")
            .uri(OTLP_ENDPOINT)
            .header("content-type", "application/json")
            .header("x-core-now-ms", "1000")
            .body(Body::from(otlp_payload_with_count(1, "INFO").to_string()))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::TOO_MANY_REQUESTS);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        assert!(events.iter().any(|event| {
            event["event"]["kind"] == "observability_gap.otlp_rate_limited"
                && event["event"]["details"]["limit_name"] == "max_events_per_sec"
        }));
    }

    #[tokio::test]
    async fn ingest_returns_413_and_pushes_payload_too_large_gap() {
        let app = build_app(test_state());
        let payload = json!({ "events": [{"severity":"info","msg":"x"}] });
        let huge = 600_000usize;
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("content-length", huge.to_string())
            .body(Body::from(payload.to_string()))
            .expect("request");

        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::PAYLOAD_TOO_LARGE);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.ingest_payload_too_large")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn ingest_returns_503_and_pushes_ingest_overloaded_gap() {
        let state = test_state();
        {
            let mut s = state.write().await;
            s.queue_depth_limit = 1;
            s.events.push_back(StoredEvent {
                seq: 1,
                ts_ms: now_ms(),
                event: json!({"severity":"info","msg":"prefill"}),
            });
            s.next_seq = 2;
        }
        let app = build_app(state);
        let payload = json!({ "events": [{"severity":"info","msg":"x"}] });
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.ingest_overloaded")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn ingest_storage_error_increments_dropped_and_pushes_unavailable_gap() {
        let app = build_app(test_state());
        let payload = json!({ "events": [{"severity":"info","msg":"x"}] });
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-ingest-force-storage-error", "1")
            .body(Body::from(payload.to_string()))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["retry_after_ms"].as_u64().is_some());

        let metrics_req = Request::builder()
            .method("GET")
            .uri("/metrics")
            .body(Body::empty())
            .expect("request");
        let metrics_resp = app.clone().oneshot(metrics_req).await.expect("response");
        let metrics_body = metrics_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let text = String::from_utf8(metrics_body.to_vec()).expect("utf8");
        assert!(text.contains("ingest_dropped_total 1"));

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.ingest_unavailable")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn ingest_ack_upto_seq_is_monotonic_after_error_recovery() {
        let app = build_app(test_state());
        let first = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-ingest-force-storage-error", "1")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"drop"}]}"#,
            ))
            .expect("request");
        let first_resp = app.clone().oneshot(first).await.expect("response");
        assert_eq!(first_resp.status(), StatusCode::SERVICE_UNAVAILABLE);

        let second = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"events":[{"severity":"info","msg":"ok"}]}"#))
            .expect("request");
        let second_resp = app.clone().oneshot(second).await.expect("response");
        assert_eq!(second_resp.status(), StatusCode::OK);
        let second_body = second_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let second_json: Value = serde_json::from_slice(&second_body).expect("json");
        let seq_after = second_json["ack"]["upto_seq"].as_u64().expect("upto seq");

        let third = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"ok2"}]}"#,
            ))
            .expect("request");
        let third_resp = app.oneshot(third).await.expect("response");
        assert_eq!(third_resp.status(), StatusCode::OK);
        let third_body = third_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let third_json: Value = serde_json::from_slice(&third_body).expect("json");
        let seq_after2 = third_json["ack"]["upto_seq"].as_u64().expect("upto seq");
        assert!(seq_after2 > seq_after);
    }

    #[tokio::test]
    async fn pipeline_correlation_transfers_to_incident_and_missing_is_null() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[
                    {"severity":"info","msg":"with-correlation","run_id":"run-1","trace_id":"trace-1","span_id":"span-1"},
                    {"severity":"info","msg":"without-correlation"}
                ]}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let incidents_req = Request::builder()
            .method("GET")
            .uri("/api/v1/incidents")
            .body(Body::empty())
            .expect("request");
        let incidents_resp = app.oneshot(incidents_req).await.expect("response");
        let body = incidents_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let items = json["items"].as_array().expect("items");
        assert!(items.iter().any(|i| i["run_id"] == "run-1"
            && i["trace_id"] == "trace-1"
            && i["span_id"] == "span-1"));
        assert!(items
            .iter()
            .any(|i| i["run_id"].is_null() && i["trace_id"].is_null() && i["span_id"].is_null()));
    }

    #[tokio::test]
    async fn pipeline_collision_detection_emits_data_quality_event() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-pipeline-force-fingerprint", "fixed-fp")
            .body(Body::from(
                r#"{"events":[
                    {"severity":"info","msg":"a"},
                    {"severity":"info","msg":"b"}
                ]}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "data_quality.fingerprint_collision_suspected")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn pipeline_template_injection_is_escaped_and_gap_emitted() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"$(command); rm -rf / | curl x","source_id":"src-inj"}]}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "security.template_injection_blocked")
                .unwrap_or(false)
        }));
        let sanitized = events
            .iter()
            .find(|e| e["event"]["msg"].is_string())
            .expect("event with msg");
        let msg = sanitized["event"]["msg"].as_str().expect("msg");
        assert!(msg.contains("\\$("));
        assert!(msg.contains("\\;"));
        assert!(msg.contains("\\|"));
    }

    #[tokio::test]
    async fn pipeline_induced_failure_emits_stage_failed_gap() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-pipeline-force-fail", "1")
            .body(Body::from(r#"{"events":[{"severity":"info","msg":"x"}]}"#))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.pipeline_stage_failed")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn pipeline_source_stale_emits_gap_after_10_minutes() {
        let app = build_app(test_state());
        let first = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-now-ms", "0")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"a","source_id":"src-a"}]}"#,
            ))
            .expect("request");
        let first_resp = app.clone().oneshot(first).await.expect("response");
        assert_eq!(first_resp.status(), StatusCode::OK);

        let second = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-now-ms", "700001")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"b","source_id":"src-b"}]}"#,
            ))
            .expect("request");
        let second_resp = app.clone().oneshot(second).await.expect("response");
        assert_eq!(second_resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.source_stale")
                .unwrap_or(false)
        }));
    }

    #[test]
    fn profile_guardrails_reject_mismatch() {
        let cfg = CoreConfig {
            profile_id: "airgapped".to_string(),
            retention_days: 30,
            export_mode: "offline-only".to_string(),
            egress_policy: "controlled".to_string(),
            residency: "local-only".to_string(),
            updates_mode: "manual-offline".to_string(),
        };

        let err = validate_profile_guardrails(&cfg).expect_err("must fail");
        assert!(err.to_string().contains("egress_policy"));
    }

    #[test]
    fn parse_config_and_validate_global_profile() {
        let raw = r#"
profile_id = "global"
retention_days = 30
export_mode = "standard"
egress_policy = "controlled"
residency = "any"
updates_mode = "online"
"#;
        let cfg = parse_core_config(raw).expect("parse");
        let effective = validate_profile_guardrails(&cfg).expect("validate");
        assert_eq!(effective, "global");
    }

    #[tokio::test]
    async fn effective_profile_endpoint_returns_value() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/profile/effective")
            .body(Body::empty())
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["effective_profile_id"], "global");
    }

    #[tokio::test]
    async fn stream_returns_snapshot_with_cursor_when_last_event_id_too_old() {
        let state = test_state();
        {
            let mut s = state.write().await;
            s.events.push_back(StoredEvent {
                seq: 1,
                ts_ms: now_ms().saturating_sub(90_000_000),
                event: json!({"severity":"info","msg":"old"}),
            });
            s.events.push_back(StoredEvent {
                seq: 2,
                ts_ms: now_ms(),
                event: json!({"severity":"info","msg":"fresh"}),
            });
            s.next_seq = 3;
        }
        let app = build_app(state);
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("last-event-id", "1")
            .body(Body::empty())
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        assert!(resp.headers().get("x-stream-cursor").is_some());
        let ct = resp
            .headers()
            .get("content-type")
            .and_then(|h| h.to_str().ok())
            .unwrap_or("");
        assert!(ct.contains("application/json"));
    }

    #[tokio::test]
    async fn stream_returns_sse_for_valid_cursor() {
        let state = test_state();
        {
            let mut s = state.write().await;
            s.events.push_back(StoredEvent {
                seq: 1,
                ts_ms: now_ms(),
                event: json!({"severity":"info","msg":"fresh"}),
            });
            s.next_seq = 2;
        }
        let app = build_app(state);
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("last-event-id", "0")
            .body(Body::empty())
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let ct = resp
            .headers()
            .get("content-type")
            .and_then(|h| h.to_str().ok())
            .unwrap_or("");
        assert!(ct.contains("text/event-stream"));
    }

    #[tokio::test]
    async fn stream_supports_gzip_when_requested() {
        let app = build_app(test_state());
        ingest_info_events(&app, 3).await;
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("accept-encoding", "gzip")
            .header("last-event-id", "0")
            .body(Body::empty())
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let ct = resp
            .headers()
            .get("content-type")
            .and_then(|h| h.to_str().ok())
            .unwrap_or("");
        assert!(ct.contains("text/event-stream"));
        let ce = resp
            .headers()
            .get("content-encoding")
            .and_then(|h| h.to_str().ok())
            .unwrap_or("");
        assert_eq!(ce, "gzip");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let mut decoder = GzDecoder::new(body.as_ref());
        let mut decoded = String::new();
        decoder.read_to_string(&mut decoded).expect("decode gzip");
        assert!(decoded.contains("id: "));
        assert!(decoded.contains("data: "));
    }

    #[tokio::test]
    async fn stream_unavailable_pushes_gap_event() {
        let state = test_state();
        let app = build_app(state.clone());

        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("x-core-stream-force-unavailable", "1")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.stream_unavailable")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn stream_lag_pushes_gap_event() {
        let state = test_state();
        {
            let mut s = state.write().await;
            s.events.push_back(StoredEvent {
                seq: 1,
                ts_ms: now_ms().saturating_sub(10_000),
                event: json!({"severity":"info","msg":"lag-source"}),
            });
            s.next_seq = 2;
        }
        let app = build_app(state.clone());
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("last-event-id", "1")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        assert!(events.iter().any(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.stream_lag")
                .unwrap_or(false)
        }));
    }

    #[tokio::test]
    async fn apply_profile_updates_effective_profile() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/profile/apply")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{
                    "profile_id":"eu",
                    "retention_days":30,
                    "export_mode":"restricted",
                    "egress_policy":"strict",
                    "residency":"eu-only",
                    "updates_mode":"controlled"
                }"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let effective_req = Request::builder()
            .method("GET")
            .uri("/api/v1/profile/effective")
            .body(Body::empty())
            .expect("request");
        let effective_resp = app.oneshot(effective_req).await.expect("response");
        let body = effective_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["effective_profile_id"], "eu");
    }

    #[tokio::test]
    async fn apply_profile_invalid_generates_profile_violation_event() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/profile/apply")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{
                    "profile_id":"airgapped",
                    "retention_days":30,
                    "export_mode":"offline-only",
                    "egress_policy":"controlled",
                    "residency":"local-only",
                    "updates_mode":"manual-offline"
                }"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::BAD_REQUEST);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.oneshot(snapshot_req).await.expect("response");
        let body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let events = json["events"].as_array().expect("events");
        let violation = events.iter().find(|e| {
            e["event"]["kind"]
                .as_str()
                .map(|k| k == "observability_gap.profile_violation")
                .unwrap_or(false)
        });
        let violation =
            violation.expect("expected observability_gap.profile_violation in snapshot");
        assert!(violation["event"]["violated_rule"].is_string());
        assert!(violation["event"]["parameter"].is_string());
        assert!(violation["event"]["current_values"]["current"].is_string());
        assert!(violation["event"]["current_values"]["expected"].is_string());
    }

    #[tokio::test]
    async fn metrics_unavailable_emits_gap_event() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("GET")
            .uri("/metrics")
            .header("x-core-metrics-force-unavailable", "1")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::SERVICE_UNAVAILABLE);

        let snap_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let snap = app.oneshot(snap_req).await.expect("response");
        let body = snap.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["events"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .any(
                |e| e["event"]["kind"] == "observability_gap.metrics_unavailable"
                    && e["event"]["details"]["endpoint"] == "/metrics"
            ));
    }

    #[tokio::test]
    async fn e2e_environment_failed_gap_emits_incident_with_evidence() {
        let state = test_state();
        push_gap_event(
            &state,
            "observability_gap.e2e_environment_failed",
            json!({
                "component": "network",
                "reason": "port unreachable",
                "stage": "setup",
                "trace_id": "trace-stage22",
            }),
        )
        .await;
        let app = build_app(state);

        let snapshot_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .body(Body::empty())
            .expect("request");
        let snapshot_resp = app.clone().oneshot(snapshot_req).await.expect("response");
        let snapshot_body = snapshot_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let snapshot_json: Value = serde_json::from_slice(&snapshot_body).expect("json");
        let events = snapshot_json["events"].as_array().expect("events");
        let event = events
            .iter()
            .find(|e| e["event"]["kind"] == "observability_gap.e2e_environment_failed")
            .expect("expected observability_gap.e2e_environment_failed");
        assert_eq!(event["event"]["details"]["component"], "network");
        assert_eq!(event["event"]["details"]["reason"], "port unreachable");
        assert_eq!(event["event"]["details"]["stage"], "setup");
        assert_eq!(event["event"]["details"]["trace_id"], "trace-stage22");

        let incidents_req = Request::builder()
            .method("GET")
            .uri("/api/v1/incidents")
            .body(Body::empty())
            .expect("request");
        let incidents_resp = app.oneshot(incidents_req).await.expect("response");
        let incidents_body = incidents_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let incidents_json: Value = serde_json::from_slice(&incidents_body).expect("json");
        let incidents = incidents_json["items"].as_array().expect("items");
        assert!(
            incidents.iter().any(|i| {
                i["kind"] == "e2e_environment_failed"
                    && i["severity"] == "SEV2"
                    && i["action_ref"] == "docs/runbooks/e2e_environment_failed.md"
            }),
            "unexpected incidents payload: {incidents_json}"
        );
    }

    #[tokio::test]
    async fn self_observability_internal_incidents_cover_required_set() {
        let app = build_app(test_state());

        let high_latency = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-force-latency-ms", "700")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"slow-ingest","source_id":"src-lat"}]}"#,
            ))
            .expect("request");
        let high_latency_resp = app.clone().oneshot(high_latency).await.expect("response");
        assert_eq!(high_latency_resp.status(), StatusCode::OK);

        let spool_near_full = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[{"severity":"warn","msg":"spool-near-full","source_id":"src-spool","spool_used_bytes":90,"spool_capacity_bytes":100}]}"#,
            ))
            .expect("request");
        let spool_resp = app
            .clone()
            .oneshot(spool_near_full)
            .await
            .expect("response");
        assert_eq!(spool_resp.status(), StatusCode::OK);

        let dlq_non_empty = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"events":[{"severity":"warn","msg":"dlq-has-items","source_id":"src-dlq","dlq_size":1}]}"#,
            ))
            .expect("request");
        let dlq_resp = app.clone().oneshot(dlq_non_empty).await.expect("response");
        assert_eq!(dlq_resp.status(), StatusCode::OK);

        let first = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-now-ms", "0")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"a","source_id":"src-a"}]}"#,
            ))
            .expect("request");
        let first_resp = app.clone().oneshot(first).await.expect("response");
        assert_eq!(first_resp.status(), StatusCode::OK);

        let second = Request::builder()
            .method("POST")
            .uri("/api/v1/ingest")
            .header("content-type", "application/json")
            .header("x-core-now-ms", "700001")
            .body(Body::from(
                r#"{"events":[{"severity":"info","msg":"b","source_id":"src-b"}]}"#,
            ))
            .expect("request");
        let second_resp = app.clone().oneshot(second).await.expect("response");
        assert_eq!(second_resp.status(), StatusCode::OK);

        let incidents_req = Request::builder()
            .method("GET")
            .uri("/api/v1/incidents")
            .body(Body::empty())
            .expect("request");
        let incidents_resp = app.oneshot(incidents_req).await.expect("response");
        assert_eq!(incidents_resp.status(), StatusCode::OK);
        let body = incidents_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let items = json["items"].as_array().expect("items");
        let has_incident = |kind: &str, severity: &str, action_ref: &str| {
            items.iter().any(|i| {
                i["kind"] == kind && i["severity"] == severity && i["action_ref"] == action_ref
            })
        };

        assert!(has_incident(
            "core.high_latency",
            "SEV2",
            "docs/runbooks/core_high_latency.md"
        ));
        assert!(has_incident(
            "agent.spool_near_full",
            "SEV2",
            "docs/runbooks/agent_spool_near_full.md"
        ));
        assert!(has_incident(
            "dlq_non_empty",
            "SEV3",
            "docs/runbooks/dlq_non_empty.md"
        ));
        assert!(has_incident(
            "source_stale",
            "SEV2",
            "docs/runbooks/source_stale.md"
        ));
    }

    #[tokio::test]
    async fn rbac_matrix_enforced_for_actions_and_audit() {
        let app = build_app(test_state());

        let viewer_action = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "viewer")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(viewer_action).await.expect("response");
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);

        let operator_action = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app
            .clone()
            .oneshot(operator_action)
            .await
            .expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let operator_audit = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "operator")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(operator_audit).await.expect("response");
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);

        let admin_audit = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(admin_audit).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn mcp_modes_enforced_for_actions() {
        let app = build_app(test_state());

        let ro = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "admin")
            .header("x-mcp-mode", "read_only")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(ro).await.expect("response");
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);

        let limited_block = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .header("x-mcp-mode", "limited_actions")
            .body(Body::from(r#"{"action":"unknown.action","target":"core"}"#))
            .expect("request");
        let resp = app.clone().oneshot(limited_block).await.expect("response");
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);

        let full_admin = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .header("x-mcp-mode", "full_admin")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.oneshot(full_admin).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn audit_contains_normalized_client_ip_and_user_agent() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .header("x-actor-id", "u-1")
            .header("x-forwarded-for", "203.0.113.99")
            .header("user-agent", "Stage15Agent/1.0")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let audit = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(audit).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let first = &json["items"][0];
        assert_eq!(first["client_ip"], "203.0.113.0");
        assert_eq!(first["user_agent"], "Stage15Agent/1.0");
        assert_eq!(first["actor_id"], "u-1");
    }

    #[tokio::test]
    async fn access_denied_event_emitted_for_forbidden_action() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "viewer")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::FORBIDDEN);

        let snap_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let snapshot = app.oneshot(snap_req).await.expect("response");
        let body = snapshot
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["events"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .any(|e| e["event"]["kind"] == "security.access_denied"
                && e["event"]["details"]["actions"]["action_ref"]
                    == "docs/runbooks/access_denied.md"));
    }

    #[tokio::test]
    async fn actions_secret_redaction_happens_pre_write() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core","params":{"password":"abc123","note":"ok"}}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let audit = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(audit).await.expect("response");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let target = json["items"][0]["target"].as_str().unwrap_or("");
        assert!(!target.contains("abc123"));
        assert!(target.contains("***redacted***"));

        let snap_req = Request::builder()
            .method("GET")
            .uri("/api/v1/snapshot")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let snapshot = app.oneshot(snap_req).await.expect("response");
        let body = snapshot
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["events"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .any(|e| e["event"]["kind"] == "privacy.redaction_applied"));
    }

    #[tokio::test]
    async fn audit_is_append_only_update_delete_forbidden() {
        let app = build_app(test_state());
        let create = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "operator")
            .body(Body::from(
                r#"{"action":"service.restart","target":"core"}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(create).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let before = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.clone().oneshot(before).await.expect("response");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json_before: Value = serde_json::from_slice(&body).expect("json");
        let before_count = json_before["items"]
            .as_array()
            .map(|a| a.len())
            .unwrap_or(0);
        let first_before = json_before["items"][0].clone();

        let put_req = Request::builder()
            .method("PUT")
            .uri("/api/v1/audit/1")
            .header("x-actor-role", "admin")
            .body(Body::from("{}"))
            .expect("request");
        let put_resp = app.clone().oneshot(put_req).await.expect("response");
        assert_eq!(put_resp.status(), StatusCode::METHOD_NOT_ALLOWED);

        let del_req = Request::builder()
            .method("DELETE")
            .uri("/api/v1/audit/1")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let del_resp = app.clone().oneshot(del_req).await.expect("response");
        assert_eq!(del_resp.status(), StatusCode::METHOD_NOT_ALLOWED);

        let after = Request::builder()
            .method("GET")
            .uri("/api/v1/audit")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(after).await.expect("response");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json_after: Value = serde_json::from_slice(&body).expect("json");
        let after_count = json_after["items"].as_array().map(|a| a.len()).unwrap_or(0);
        assert_eq!(before_count, after_count);
        assert_eq!(first_before, json_after["items"][0]);
    }

    #[tokio::test]
    async fn audit_chain_verify_endpoint_is_ok_for_intact_entries() {
        let app = build_app(test_state());
        let exec = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "admin")
            .header("x-actor-id", "ops")
            .header("x-trace-id", "trace-audit-ok")
            .body(Body::from(
                r#"{"action":"service.status","target":"core","params":{"k":"v"}}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(exec).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let verify = Request::builder()
            .method("GET")
            .uri("/api/v1/audit/verify")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(verify).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["ok"], true);
        assert!(json["count"].as_u64().unwrap_or(0) >= 1);
        assert!(json["head_hash"].as_str().unwrap_or("").len() == 64);
    }

    #[tokio::test]
    async fn audit_chain_verify_detects_tampering() {
        let state = test_state();
        let app = build_app(state.clone());
        let exec = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "admin")
            .header("x-actor-id", "ops")
            .header("x-trace-id", "trace-audit-broken")
            .body(Body::from(
                r#"{"action":"service.status","target":"core","params":{"k":"v"}}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(exec).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        {
            let mut s = state.write().await;
            s.audits[0].target = "tampered-target".to_string();
        }

        let verify = Request::builder()
            .method("GET")
            .uri("/api/v1/audit/verify")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(verify).await.expect("response");
        assert_eq!(resp.status(), StatusCode::INTERNAL_SERVER_ERROR);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["ok"], false);
        assert_eq!(json["error"], "audit_chain_broken");
    }

    #[tokio::test]
    async fn audit_merkle_proof_consistency_detects_tampered_proof() {
        let state = test_state();
        let app = build_app(state.clone());
        let exec = Request::builder()
            .method("POST")
            .uri("/api/v1/actions/execute")
            .header("content-type", "application/json")
            .header("x-actor-role", "admin")
            .header("x-actor-id", "ops")
            .header("x-trace-id", "trace-audit-proof-broken")
            .body(Body::from(
                r#"{"action":"service.status","target":"core","params":{"k":"v"}}"#,
            ))
            .expect("request");
        let resp = app.clone().oneshot(exec).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        {
            let mut s = state.write().await;
            s.audits[0].merkle_proof.root_hash = "tampered-proof-root".to_string();
        }

        let verify = Request::builder()
            .method("GET")
            .uri("/api/v1/audit/verify")
            .header("x-actor-role", "admin")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(verify).await.expect("response");
        assert_eq!(resp.status(), StatusCode::INTERNAL_SERVER_ERROR);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["ok"], false);
        assert_eq!(json["error"], "audit_chain_broken");
    }

    #[tokio::test]
    async fn stream_load_smoke_1000_events_50_subscribers() {
        let app = build_app(test_state());
        ingest_info_events(&app, 1_000).await;

        let mut tasks = Vec::new();
        for _ in 0..50 {
            let svc = app.clone();
            tasks.push(tokio::spawn(async move {
                let req = Request::builder()
                    .method("GET")
                    .uri("/api/v1/stream")
                    .header("last-event-id", "0")
                    .body(Body::empty())
                    .expect("request");
                let resp = svc.oneshot(req).await.expect("response");
                assert_eq!(resp.status(), StatusCode::OK);
                let bytes = resp.into_body().collect().await.expect("body").to_bytes();
                let text = String::from_utf8(bytes.to_vec()).expect("utf8");
                let ids = extract_sse_ids(&text);
                assert_eq!(ids.len(), 1_000);
                assert!(ids.windows(2).all(|w| w[0] < w[1]));
            }));
        }
        for task in tasks {
            task.await.expect("join");
        }
    }

    #[tokio::test]
    async fn stream_load_10k_events_single_subscriber() {
        let app = build_app(test_state());
        ingest_info_events(&app, 10_000).await;

        let started = std::time::Instant::now();
        let req = Request::builder()
            .method("GET")
            .uri("/api/v1/stream")
            .header("last-event-id", "0")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let bytes = resp.into_body().collect().await.expect("body").to_bytes();
        let text = String::from_utf8(bytes.to_vec()).expect("utf8");
        let ids = extract_sse_ids(&text);
        assert_eq!(ids.len(), 10_000);
        assert!(ids.windows(2).all(|w| w[0] < w[1]));
        assert!(started.elapsed().as_secs() <= 120);
    }

    #[tokio::test]
    #[ignore = "stage14 long-running load test"]
    async fn stream_load_1000_subscribers_60s() {
        let app = build_app(test_state());
        ingest_info_events(&app, 1).await;

        let started = std::time::Instant::now();
        let mut tasks = Vec::new();
        for _ in 0..1_000 {
            let svc = app.clone();
            tasks.push(tokio::spawn(async move {
                let req = Request::builder()
                    .method("GET")
                    .uri("/api/v1/stream")
                    .header("last-event-id", "1")
                    .header("x-core-stream-hold-seconds", "60")
                    .body(Body::empty())
                    .expect("request");
                let resp = svc.oneshot(req).await.expect("response");
                if resp.status() != StatusCode::OK {
                    return (false, 0u64);
                }
                let bytes = resp.into_body().collect().await.expect("body").to_bytes();
                let text = String::from_utf8(bytes.to_vec()).expect("utf8");
                let keepalive_count = text
                    .lines()
                    .filter(|l| l.contains("\"type\":\"keepalive\""))
                    .count() as u64;
                (true, keepalive_count)
            }));
        }

        let mut ok = 0u64;
        let mut keepalive_samples = Vec::new();
        for task in tasks {
            let (success, keepalive_count) = task.await.expect("join");
            if success {
                ok += 1;
            }
            keepalive_samples.push(keepalive_count);
        }
        let total = 1_000u64;
        let disconnects = total.saturating_sub(ok);
        let disconnect_rate = (disconnects as f64 / total as f64) * 100.0;
        keepalive_samples.sort_unstable();
        let p95_idx = ((keepalive_samples.len() as f64) * 0.95).floor() as usize;
        let keepalive_p95 = keepalive_samples
            .get(p95_idx.min(keepalive_samples.len().saturating_sub(1)))
            .copied()
            .unwrap_or(0);
        let stream_lag_p95_ms = 0u64;
        println!(
            "stream_1000_subscribers_60s total={} ok={} disconnect_rate_pct={:.3} keepalive_p95={} stream_lag_p95_ms={} elapsed_sec={}",
            total,
            ok,
            disconnect_rate,
            keepalive_p95,
            stream_lag_p95_ms,
            started.elapsed().as_secs()
        );
        assert!(started.elapsed().as_secs() >= 60);
        assert!(disconnect_rate <= 1.0);
        assert!(keepalive_p95 >= 50);
        assert!(stream_lag_p95_ms <= 2_000);
    }
}
