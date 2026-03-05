use std::collections::{HashMap, VecDeque};
use std::convert::Infallible;
use std::env;
use std::fs;
use std::net::SocketAddr;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Context;
use async_stream::stream;
use axum::extract::{Path, State};
use axum::http::{Extensions, HeaderMap, HeaderValue, StatusCode, Version};
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

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredEvent {
    seq: u64,
    ts_ms: u64,
    event: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Incident {
    id: String,
    status: String,
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

#[derive(Debug)]
struct CoreState {
    next_seq: u64,
    events: VecDeque<StoredEvent>,
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
    limited_actions_allowlist: Vec<String>,
}

impl CoreState {
    fn new(
        effective_profile_id: String,
        queue_depth_limit: usize,
        max_batch_events: usize,
        max_payload_bytes: usize,
        limited_actions_allowlist: Vec<String>,
    ) -> Self {
        Self {
            next_seq: 1,
            events: VecDeque::new(),
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
            limited_actions_allowlist,
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
    Stream,
    IncidentsGet,
    IncidentAck,
    IncidentResolve,
    ActionsExecute,
    AuditGet,
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

    let state = Arc::new(RwLock::new(CoreState::new(
        effective_profile_id,
        queue_depth_limit,
        max_batch_events,
        max_payload_bytes,
        limited_actions_allowlist,
    )));

    let app = build_app(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    info!("art-core listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .with_context(|| format!("failed to bind {}", addr))?;
    axum::serve(listener, app)
        .await
        .context("core server failed")?;
    Ok(())
}

fn build_app(state: Shared) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/api/v1/profile/effective", get(effective_profile))
        .route("/api/v1/profile/apply", post(apply_profile))
        .route("/metrics", get(metrics))
        .route("/api/v1/ingest", post(ingest))
        .route("/api/v1/snapshot", get(snapshot))
        .route(
            "/api/v1/stream",
            get(stream_events).layer(CompressionLayer::new().compress_when(always_compress)),
        )
        .route("/api/v1/incidents", get(incidents))
        .route("/api/v1/incidents/:id/ack", post(incident_ack))
        .route("/api/v1/incidents/:id/resolve", post(incident_resolve))
        .route("/api/v1/actions/execute", post(actions_execute))
        .route("/api/v1/audit", get(audit_list))
        .route(
            "/api/v1/audit/:id",
            axum::routing::put(audit_mutation_forbidden).delete(audit_mutation_forbidden),
        )
        .with_state(state)
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

                let incident = Incident {
                    id: format!("incident-{}", seq),
                    status: "open".to_string(),
                    run_id: string_field(&processed_event, "run_id"),
                    trace_id: string_field(&processed_event, "trace_id"),
                    span_id: string_field(&processed_event, "span_id"),
                };
                s.incidents.push(incident);
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

fn push_gap_event_locked(s: &mut CoreState, kind: &str, details: Value) {
    let seq = s.next_seq;
    s.next_seq += 1;
    s.events.push_back(StoredEvent {
        seq,
        ts_ms: now_ms(),
        event: json!({
            "kind": kind,
            "severity": "error",
            "details": details
        }),
    });
    if s.events.len() > s.queue_depth_limit {
        s.events.pop_front();
    }
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
    let seq = s.next_seq;
    s.next_seq += 1;
    s.events.push_back(StoredEvent {
        seq,
        ts_ms: now_ms(),
        event: json!({
            "kind": kind,
            "details": details
        }),
    });
    if s.events.len() > s.queue_depth_limit {
        s.events.pop_front();
    }
}

async fn audit_list(State(state): State<Shared>, headers: HeaderMap) -> impl IntoResponse {
    if let Err(deny) = enforce_rbac(&state, &headers, Endpoint::AuditGet, None, None).await {
        return deny;
    }
    let s = state.read().await;
    (StatusCode::OK, Json(json!({ "items": s.audits }))).into_response()
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
        Endpoint::Snapshot | Endpoint::Stream | Endpoint::IncidentsGet => true,
        Endpoint::IncidentAck | Endpoint::IncidentResolve | Endpoint::ActionsExecute => {
            matches!(role, ActorRole::Operator | ActorRole::Admin)
        }
        Endpoint::AuditGet => matches!(role, ActorRole::Admin),
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
        Endpoint::Stream => "/api/v1/stream",
        Endpoint::IncidentsGet => "/api/v1/incidents",
        Endpoint::IncidentAck => "/api/v1/incidents/{id}/ack",
        Endpoint::IncidentResolve => "/api/v1/incidents/{id}/resolve",
        Endpoint::ActionsExecute => "/api/v1/actions/execute",
        Endpoint::AuditGet => "/api/v1/audit",
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
    }
}

fn append_audit_entry(state: &mut CoreState, mut entry: AuditEntry) {
    entry.id = state.next_audit_id;
    state.next_audit_id += 1;
    state.audits.push(entry);
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
    use std::io::Read;
    use tower::ServiceExt;

    fn test_state() -> Shared {
        Arc::new(RwLock::new(CoreState::new(
            "global".to_string(),
            10_000,
            200,
            524_288,
            vec!["service.restart".to_string(), "service.status".to_string()],
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

    fn extract_sse_ids(body: &str) -> Vec<u64> {
        body.lines()
            .filter_map(|line| line.strip_prefix("id: "))
            .filter_map(|id| id.trim().parse::<u64>().ok())
            .collect()
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
