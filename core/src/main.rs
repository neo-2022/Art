use std::collections::VecDeque;
use std::env;
use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Context;
use async_stream::stream;
use axum::extract::{Path, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::sse::{Event, Sse};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::sync::RwLock;
use tokio::time::{Duration, Instant};
use tracing::{info, warn};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredEvent {
    seq: u64,
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
    queue_depth_limit: usize,
    max_batch_events: usize,
    max_payload_bytes: usize,
}

impl CoreState {
    fn new(queue_depth_limit: usize, max_batch_events: usize, max_payload_bytes: usize) -> Self {
        Self {
            next_seq: 1,
            events: VecDeque::new(),
            incidents: Vec::new(),
            counters: Counters::default(),
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
        queue_depth_limit,
        max_batch_events,
        max_payload_bytes,
    )));

    let app = Router::new()
        .route("/health", get(health))
        .route("/metrics", get(metrics))
        .route("/api/v1/ingest", post(ingest))
        .route("/api/v1/snapshot", get(snapshot))
        .route("/api/v1/stream", get(stream_events))
        .route("/api/v1/incidents", get(incidents))
        .route("/api/v1/incidents/:id/ack", post(incident_ack))
        .route("/api/v1/incidents/:id/resolve", post(incident_resolve))
        .route("/api/v1/actions/execute", post(actions_execute))
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    info!("art-core listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .with_context(|| format!("failed to bind {}", addr))?;
    axum::serve(listener, app).await.context("core server failed")?;
    Ok(())
}

async fn health() -> impl IntoResponse {
    (StatusCode::OK, Json(json!({"status":"ok","service":"art-core"})))
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
                s.events.push_back(StoredEvent { seq, event });
                if s.events.len() > 5_000 {
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
    let body = SnapshotResponse {
        cursor,
        events,
        incidents: s.incidents.clone(),
    };
    (StatusCode::OK, Json(body))
}

async fn stream_events(
    State(state): State<Shared>,
) -> Sse<impl futures_core::Stream<Item = Result<Event, std::convert::Infallible>>> {
    let tick = Duration::from_secs(2);
    let started = Instant::now();
    let out = stream! {
        loop {
            tokio::time::sleep(tick).await;
            let cursor = {
                let s = state.read().await;
                s.next_seq.saturating_sub(1)
            };
            let payload = json!({
                "type": "tick",
                "cursor": cursor,
                "uptime_sec": started.elapsed().as_secs(),
            });
            yield Ok(Event::default().event("message").data(payload.to_string()));
        }
    };
    Sse::new(out)
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
