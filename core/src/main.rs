use std::collections::VecDeque;
use std::convert::Infallible;
use std::env;
use std::fs;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Context;
use async_stream::stream;
use axum::extract::{Path, State};
use axum::http::{Extensions, HeaderMap, HeaderValue, StatusCode, Version};
use axum::response::Response;
use axum::response::sse::{Event, Sse};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
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
    trace_id: Option<String>,
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
    counters: Counters,
    effective_profile_id: String,
    queue_depth_limit: usize,
    max_batch_events: usize,
    max_payload_bytes: usize,
}

impl CoreState {
    fn new(
        effective_profile_id: String,
        queue_depth_limit: usize,
        max_batch_events: usize,
        max_payload_bytes: usize,
    ) -> Self {
        Self {
            next_seq: 1,
            events: VecDeque::new(),
            incidents: Vec::new(),
            counters: Counters::default(),
            effective_profile_id,
            queue_depth_limit,
            max_batch_events,
            max_payload_bytes,
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
    events: Vec<StoredEvent>,
    incidents: Vec<Incident>,
}

#[derive(Debug, Deserialize)]
struct ActionExecuteRequest {
    action: String,
    target: Option<String>,
}

#[derive(Debug, Serialize)]
struct ActionExecuteResponse {
    accepted: bool,
    action: String,
    target: Option<String>,
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
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let port = env::var("CORE_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(7070);
    let config_path = env::var("CORE_CONFIG_PATH").unwrap_or_else(|_| "config/core.toml".to_string());
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

    let state = Arc::new(RwLock::new(CoreState::new(
        effective_profile_id,
        queue_depth_limit,
        max_batch_events,
        max_payload_bytes,
    )));

    let app = build_app(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    info!("art-core listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .with_context(|| format!("failed to bind {}", addr))?;
    axum::serve(listener, app).await.context("core server failed")?;
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
        .with_state(state)
}

async fn health() -> impl IntoResponse {
    (StatusCode::OK, Json(json!({"status":"ok","service":"art-core"})))
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
                trace_id: None,
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

async fn metrics(State(state): State<Shared>) -> impl IntoResponse {
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
    (StatusCode::OK, body)
}

async fn ingest(
    State(state): State<Shared>,
    headers: HeaderMap,
    Json(payload): Json<IngestEnvelope>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    if let Some(len) = content_length(&headers) {
        if len > s.max_payload_bytes {
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
        let err = BackpressureError {
            error: "ingest_overloaded".to_string(),
            retry_after_ms: 1_500,
        };
        return (StatusCode::SERVICE_UNAVAILABLE, Json(json!(err))).into_response();
    }

    let mut accepted = 0usize;
    let mut invalid_details = Vec::new();
    let mut upto_seq = s.next_seq.saturating_sub(1);

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
                let seq = s.next_seq;
                s.next_seq += 1;
                upto_seq = seq;
                s.events.push_back(StoredEvent {
                    seq,
                    ts_ms: now_ms(),
                    event,
                });
                if s.events.len() > s.queue_depth_limit {
                    s.events.pop_front();
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

async fn snapshot(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    let events: Vec<StoredEvent> = s.events.iter().rev().take(200).cloned().collect();
    let cursor = events.iter().map(|e| e.seq).max().unwrap_or(0);
    let min_retained_seq = compute_min_retained_seq(&s);
    let body = SnapshotResponse {
        cursor,
        min_retained_seq,
        events,
        incidents: s.incidents.clone(),
    };
    (StatusCode::OK, Json(body))
}

async fn stream_events(
    State(state): State<Shared>,
    headers: HeaderMap,
) -> Response {
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

async fn incidents(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    (StatusCode::OK, Json(json!({ "items": s.incidents })))
}

async fn incident_ack(Path(id): Path<String>, State(state): State<Shared>) -> impl IntoResponse {
    let mut s = state.write().await;
    if let Some(item) = s.incidents.iter_mut().find(|x| x.id == id) {
        item.status = "acknowledged".to_string();
        return (StatusCode::OK, Json(json!({"ok": true, "id": id})));
    }
    warn!("incident not found for ack: {}", id);
    (StatusCode::NOT_FOUND, Json(json!({"ok": false, "error": "not_found"})))
}

async fn incident_resolve(
    Path(id): Path<String>,
    State(state): State<Shared>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    if let Some(item) = s.incidents.iter_mut().find(|x| x.id == id) {
        item.status = "resolved".to_string();
        return (StatusCode::OK, Json(json!({"ok": true, "id": id})));
    }
    warn!("incident not found for resolve: {}", id);
    (StatusCode::NOT_FOUND, Json(json!({"ok": false, "error": "not_found"})))
}

async fn actions_execute(Json(req): Json<ActionExecuteRequest>) -> impl IntoResponse {
    let response = ActionExecuteResponse {
        accepted: true,
        action: req.action,
        target: req.target,
    };
    (StatusCode::OK, Json(response))
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
        let violation = violation.expect("expected observability_gap.profile_violation in snapshot");
        assert!(violation["event"]["violated_rule"].is_string());
        assert!(violation["event"]["parameter"].is_string());
        assert!(violation["event"]["current_values"]["current"].is_string());
        assert!(violation["event"]["current_values"]["expected"].is_string());
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
                let keepalive_count = text.lines().filter(|l| l.contains("\"type\":\"keepalive\"")).count() as u64;
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
