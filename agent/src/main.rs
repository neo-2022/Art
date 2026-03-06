use std::collections::VecDeque;
use std::env;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Context;
use axum::extract::State;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::sync::RwLock;
use tracing::info;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct SpoolRecord {
    id: u64,
    bytes: u64,
    payload: Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Incident {
    kind: String,
    severity: String,
    action_ref: String,
}

#[derive(Debug, Default)]
struct AgentState {
    spool_pending: VecDeque<SpoolRecord>,
    spool_dlq: Vec<SpoolRecord>,
    mode: String,
    capacity_bytes: u64,
    used_bytes: u64,
    paused_receivers: bool,
    next_id: u64,
    spool_path: String,
    events: Vec<Value>,
    incidents: Vec<Incident>,
    dropped_total: u64,
    rejected_total: u64,
}

type Shared = Arc<RwLock<AgentState>>;

#[derive(Debug, Serialize)]
struct ReceiverStatus {
    receivers: Vec<String>,
}

#[derive(Debug, Serialize)]
struct SpoolStatus {
    mode: String,
    pending: u64,
    dlq: u64,
    capacity_bytes: u64,
    used_bytes: u64,
    paused_receivers: bool,
    spool_dropped_total: u64,
    spool_rejected_total: u64,
}

#[derive(Debug, Deserialize)]
struct EnqueueRequest {
    count: Option<u64>,
    bytes: Option<u64>,
    payload: Option<Value>,
}

#[derive(Debug, Deserialize)]
struct RecoveryRequest {
    corruption_type: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ParseRequest {
    receiver_kind: String,
    source: String,
    multiline: Option<bool>,
}

#[derive(Debug, Serialize)]
struct ParseResponse {
    events: Vec<Value>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    let port = env::var("AGENT_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(7071);

    let state = Arc::new(RwLock::new(AgentState {
        mode: "never_drop_unacked".to_string(),
        capacity_bytes: 1024,
        spool_path: "/var/lib/art-agent/spool.db".to_string(),
        ..AgentState::default()
    }));

    let app = build_app(state);

    let host = env::var("AGENT_HOST")
        .ok()
        .and_then(|raw| raw.parse::<std::net::IpAddr>().ok())
        .unwrap_or(std::net::IpAddr::from([127, 0, 0, 1]));
    let addr = SocketAddr::new(host, port);
    info!("art-agent listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .with_context(|| format!("failed to bind {}", addr))?;
    axum::serve(listener, app)
        .await
        .context("agent server failed")?;
    Ok(())
}

fn build_app(state: Shared) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/metrics", get(metrics))
        .route("/api/v1/agent/receivers", get(receivers))
        .route("/api/v1/agent/spool/status", get(spool_status))
        .route("/api/v1/agent/spool/events", get(spool_events))
        .route("/api/v1/agent/spool/enqueue", post(spool_enqueue))
        .route("/api/v1/agent/spool/recheck", post(spool_recheck))
        .route(
            "/api/v1/agent/spool/simulate_corruption",
            post(simulate_corruption),
        )
        .route(
            "/api/v1/agent/spool/simulate_disk_full",
            post(simulate_disk_full),
        )
        .route("/api/v1/agent/receivers/parse", post(receivers_parse))
        .with_state(state)
}

async fn health() -> impl IntoResponse {
    Json(json!({"status":"ok","service":"art-agent"}))
}

async fn metrics(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    let body = format!(
        concat!(
            "agent_spool_pending {}\n",
            "agent_spool_dlq {}\n",
            "spool_used_bytes {}\n",
            "spool_capacity_bytes {}\n",
            "spool_dropped_total {}\n",
            "spool_rejected_total {}\n"
        ),
        s.spool_pending.len(),
        s.spool_dlq.len(),
        s.used_bytes,
        s.capacity_bytes,
        s.dropped_total,
        s.rejected_total,
    );
    body
}

async fn receivers() -> impl IntoResponse {
    Json(ReceiverStatus {
        receivers: vec![
            "file_tail".to_string(),
            "journald".to_string(),
            "stdout_stderr".to_string(),
        ],
    })
}

async fn spool_status(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    Json(SpoolStatus {
        mode: s.mode.clone(),
        pending: s.spool_pending.len() as u64,
        dlq: s.spool_dlq.len() as u64,
        capacity_bytes: s.capacity_bytes,
        used_bytes: s.used_bytes,
        paused_receivers: s.paused_receivers,
        spool_dropped_total: s.dropped_total,
        spool_rejected_total: s.rejected_total,
    })
}

async fn spool_events(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    Json(json!({"events": s.events, "incidents": s.incidents}))
}

async fn spool_enqueue(
    State(state): State<Shared>,
    Json(req): Json<EnqueueRequest>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    let count = req.count.unwrap_or(1);
    let bytes = req.bytes.unwrap_or(128).max(1);

    for _ in 0..count {
        if s.used_bytes + bytes > s.capacity_bytes {
            if s.mode == "never_drop_unacked" {
                s.paused_receivers = true;
                s.rejected_total += 1;
                let spool_path = s.spool_path.clone();
                let capacity_bytes = s.capacity_bytes;
                let used_bytes = s.used_bytes;
                let backlog_count = s.spool_pending.len();
                let trace_id = format!("trace-{}", now_ms());
                s.events.push(json!({
                    "kind": "observability_gap.spool_full",
                    "details": {
                        "spool_path": spool_path,
                        "capacity_bytes": capacity_bytes,
                        "used_bytes": used_bytes,
                        "backlog_count": backlog_count,
                        "trace_id": trace_id
                    }
                }));
                let paused_backlog = s.spool_pending.len();
                let paused_used = s.used_bytes;
                let paused_trace = format!("trace-{}", now_ms());
                s.events.push(json!({
                    "kind": "observability_gap.receiver_paused_spool_full",
                    "details": {
                        "receiver_kind": "file_tail",
                        "source_id": "file:/var/log/app.log",
                        "backlog_count": paused_backlog,
                        "used_bytes": paused_used,
                        "trace_id": paused_trace
                    }
                }));
                return (
                    axum::http::StatusCode::INSUFFICIENT_STORAGE,
                    Json(json!({"ok": false, "error": "spool_full"})),
                )
                    .into_response();
            }

            while s.used_bytes + bytes > s.capacity_bytes {
                if let Some(old) = s.spool_pending.pop_front() {
                    s.used_bytes = s.used_bytes.saturating_sub(old.bytes);
                    s.dropped_total += 1;
                } else {
                    break;
                }
            }
            let lossy_backlog = s.spool_pending.len();
            let lossy_used = s.used_bytes;
            let lossy_trace = format!("trace-{}", now_ms());
            s.events.push(json!({
                "kind": "data_quality.lossy_spool_drop",
                "details": {
                    "dropped_count": 1,
                    "backlog_count": lossy_backlog,
                    "used_bytes": lossy_used,
                    "trace_id": lossy_trace
                }
            }));
            s.incidents.push(Incident {
                kind: "lossy_mode_active".to_string(),
                severity: "SEV1".to_string(),
                action_ref: "docs/runbooks/lossy_mode_active.md".to_string(),
            });
        }

        let payload = req
            .payload
            .clone()
            .unwrap_or_else(|| json!({"msg":"event"}));
        let payload = redact_value(&payload);
        s.next_id += 1;
        let record_id = s.next_id;
        s.spool_pending.push_back(SpoolRecord {
            id: record_id,
            bytes,
            payload,
        });
        s.used_bytes += bytes;
    }

    Json(json!({
        "ok": true,
        "pending": s.spool_pending.len(),
        "used_bytes": s.used_bytes
    }))
    .into_response()
}

async fn spool_recheck(State(state): State<Shared>) -> impl IntoResponse {
    let mut s = state.write().await;
    if s.paused_receivers && s.used_bytes < s.capacity_bytes {
        s.paused_receivers = false;
    }
    Json(json!({"ok": true, "paused_receivers": s.paused_receivers}))
}

async fn simulate_corruption(
    State(state): State<Shared>,
    Json(req): Json<RecoveryRequest>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    let old = s.spool_path.clone();
    s.spool_path = format!("/var/lib/art-agent/spool-{}.db", now_ms());
    let new_path = s.spool_path.clone();
    let trace_id = format!("trace-{}", now_ms());
    s.events.push(json!({
        "kind": "observability_gap.spool_corrupted",
        "details": {
            "old_spool_path": old,
            "new_spool_path": new_path,
            "corruption_type": req.corruption_type.unwrap_or_else(|| "io_error".to_string()),
            "trace_id": trace_id
        }
    }));
    Json(json!({"ok": true, "spool_path": s.spool_path}))
}

async fn simulate_disk_full(State(state): State<Shared>) -> impl IntoResponse {
    let mut s = state.write().await;
    let spool_path = s.spool_path.clone();
    let used_bytes = s.used_bytes;
    let backlog_count = s.spool_pending.len();
    let trace_id = format!("trace-{}", now_ms());
    s.events.push(json!({
        "kind": "observability_gap.spool_disk_full",
        "details": {
            "spool_path": spool_path,
            "free_bytes": 0,
            "used_bytes": used_bytes,
            "backlog_count": backlog_count,
            "trace_id": trace_id
        }
    }));
    (
        axum::http::StatusCode::INSUFFICIENT_STORAGE,
        Json(json!({"ok": false, "error": "disk_full"})),
    )
}

async fn receivers_parse(
    State(state): State<Shared>,
    Json(req): Json<ParseRequest>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    let source_id = source_id_for(&req.receiver_kind, "id");
    if source_id.is_none() {
        s.events.push(json!({
            "kind": "observability_gap.receiver_read_failed",
            "details": {
                "receiver_kind": req.receiver_kind,
                "source_id": "unknown",
                "error": "unsupported_receiver_kind",
                "trace_id": format!("trace-{}", now_ms())
            }
        }));
        return (
            axum::http::StatusCode::BAD_REQUEST,
            Json(json!({"ok": false, "error": "unsupported_receiver_kind"})),
        )
            .into_response();
    }

    if req.source.contains("permission_denied") {
        s.events.push(json!({
            "kind": "observability_gap.receiver_permission_denied",
            "details": {
                "receiver_kind": req.receiver_kind,
                "source_id": source_id,
                "error": "permission_denied",
                "trace_id": format!("trace-{}", now_ms())
            }
        }));
        return (
            axum::http::StatusCode::FORBIDDEN,
            Json(json!({"ok": false, "error": "permission_denied"})),
        )
            .into_response();
    }

    if req.source.contains("spawn_failed") {
        s.events.push(json!({
            "kind": "observability_gap.receiver_process_spawn_failed",
            "details": {
                "command_id": "regart-ui-proxy",
                "error": "spawn_failed",
                "trace_id": format!("trace-{}", now_ms())
            }
        }));
        return (
            axum::http::StatusCode::BAD_REQUEST,
            Json(json!({"ok": false, "error": "spawn_failed"})),
        )
            .into_response();
    }

    let multiline = req.multiline.unwrap_or(false);
    let mut out = Vec::new();
    for (idx, chunk) in parse_input(&req.source, multiline).into_iter().enumerate() {
        if chunk.len() > 65_536 {
            s.events.push(json!({
                "kind": "data_quality.receiver_multiline_truncated",
                "details": {"trace_id": format!("trace-{}", now_ms())}
            }));
        }

        let trimmed = chunk.trim();
        let mut payload = json!({"raw_line": redact_text(trimmed)});
        if trimmed.starts_with('{') {
            match serde_json::from_str::<Value>(trimmed) {
                Ok(obj) if obj.is_object() => {
                    payload["structured"] = redact_value(&obj);
                }
                _ => {
                    s.events.push(json!({
                        "kind": "data_quality.receiver_parse_failed",
                        "details": {"trace_id": format!("trace-{}", now_ms())}
                    }));
                }
            }
        }

        out.push(json!({
            "source_id": source_id,
            "source_seq": idx as u64,
            "source_ts_ms": now_ms(),
            "receiver_kind": req.receiver_kind,
            "trace_id": format!("trace-{}", now_ms()),
            "retry_count": 0,
            "payload": payload,
        }));
    }

    Json(ParseResponse { events: out }).into_response()
}

fn parse_input(input: &str, multiline: bool) -> Vec<String> {
    if !multiline {
        return input.lines().map(ToString::to_string).collect();
    }

    let mut events = Vec::new();
    let mut current = String::new();
    let mut lines_in_event = 0usize;
    for line in input.lines() {
        let starts_new = starts_multiline_event(line);
        if starts_new && !current.is_empty() {
            events.push(current.clone());
            current.clear();
            lines_in_event = 0;
        }
        if lines_in_event < 50 {
            if !current.is_empty() {
                current.push('\n');
            }
            current.push_str(line);
            lines_in_event += 1;
        }
    }
    if !current.is_empty() {
        events.push(current);
    }
    events
}

fn starts_multiline_event(line: &str) -> bool {
    let trimmed = line.trim_start();
    if trimmed.starts_with('{') {
        return true;
    }
    let parts: Vec<&str> = trimmed.split_whitespace().collect();
    parts.len() >= 2
}

fn source_id_for(receiver_kind: &str, id: &str) -> Option<String> {
    match receiver_kind {
        "file_tail" => Some(format!("file:{}", id)),
        "journald" => Some(format!("journald:{}", id)),
        "stdout_stderr" => Some(format!("proc:{}", id)),
        _ => None,
    }
}

fn redact_text(value: &str) -> String {
    let lower = value.to_ascii_lowercase();
    if lower.contains("password")
        || lower.contains("token")
        || lower.contains("secret")
        || lower.contains("authorization")
    {
        "***redacted***".to_string()
    } else {
        value.to_string()
    }
}

fn redact_value(value: &Value) -> Value {
    match value {
        Value::Object(map) => {
            let mut out = serde_json::Map::new();
            for (k, v) in map {
                let lk = k.to_ascii_lowercase();
                if lk.contains("password")
                    || lk.contains("secret")
                    || lk.contains("token")
                    || lk.contains("authorization")
                {
                    out.insert(k.clone(), Value::String("***redacted***".to_string()));
                } else {
                    out.insert(k.clone(), redact_value(v));
                }
            }
            Value::Object(out)
        }
        Value::Array(arr) => Value::Array(arr.iter().map(redact_value).collect()),
        Value::String(s) => Value::String(redact_text(s)),
        _ => value.clone(),
    }
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    fn test_state() -> Shared {
        Arc::new(RwLock::new(AgentState {
            mode: "never_drop_unacked".to_string(),
            capacity_bytes: 256,
            spool_path: "/tmp/spool.db".to_string(),
            ..AgentState::default()
        }))
    }

    #[tokio::test]
    async fn never_drop_unacked_rejects_and_pauses_receivers() {
        let app = build_app(test_state());
        let ok_req = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"bytes":200}"#))
            .expect("request");
        let ok_resp = app.clone().oneshot(ok_req).await.expect("response");
        assert_eq!(ok_resp.status(), StatusCode::OK);

        let full_req = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"bytes":100}"#))
            .expect("request");
        let full_resp = app.clone().oneshot(full_req).await.expect("response");
        assert_eq!(full_resp.status(), StatusCode::INSUFFICIENT_STORAGE);

        let status_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/status")
            .body(Body::empty())
            .expect("request");
        let status_resp = app.clone().oneshot(status_req).await.expect("response");
        let body = status_resp
            .into_body()
            .collect()
            .await
            .expect("body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["paused_receivers"], true);

        let events_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/events")
            .body(Body::empty())
            .expect("request");
        let events_resp = app.oneshot(events_req).await.expect("response");
        let body = events_resp
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
            .any(|e| e["kind"] == "observability_gap.spool_full"));
    }

    #[tokio::test]
    async fn drop_oldest_generates_lossy_and_incident() {
        let state = test_state();
        {
            let mut s = state.write().await;
            s.mode = "drop_oldest_when_full".to_string();
        }
        let app = build_app(state);

        let req1 = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"bytes":200,"payload":{"id":1}}"#))
            .expect("request");
        assert_eq!(
            app.clone().oneshot(req1).await.expect("response").status(),
            StatusCode::OK
        );

        let req2 = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"bytes":200,"payload":{"id":2}}"#))
            .expect("request");
        assert_eq!(
            app.clone().oneshot(req2).await.expect("response").status(),
            StatusCode::OK
        );

        let events_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/events")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(events_req).await.expect("response");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert!(json["events"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .any(|e| e["kind"] == "data_quality.lossy_spool_drop"));
        assert_eq!(json["incidents"][0]["kind"], "lossy_mode_active");
    }

    #[tokio::test]
    async fn spool_corruption_recovery_creates_new_spool_and_gap() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/simulate_corruption")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"corruption_type":"sqlite_header"}"#))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);

        let events_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/events")
            .body(Body::empty())
            .expect("request");
        let events_resp = app.oneshot(events_req).await.expect("response");
        let body = events_resp
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
            .any(|e| e["kind"] == "observability_gap.spool_corrupted"));
    }

    #[tokio::test]
    async fn spool_disk_full_generates_gap() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/simulate_disk_full")
            .body(Body::from("{}"))
            .expect("request");
        let resp = app.clone().oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::INSUFFICIENT_STORAGE);

        let events_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/events")
            .body(Body::empty())
            .expect("request");
        let events_resp = app.oneshot(events_req).await.expect("response");
        let body = events_resp
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
            .any(|e| e["kind"] == "observability_gap.spool_disk_full"));
    }

    #[test]
    fn source_id_rules_are_fixed() {
        assert_eq!(source_id_for("file_tail", "/a").as_deref(), Some("file:/a"));
        assert_eq!(
            source_id_for("journald", "ui-proxy.service").as_deref(),
            Some("journald:ui-proxy.service")
        );
        assert_eq!(
            source_id_for("stdout_stderr", "id1").as_deref(),
            Some("proc:id1")
        );
        assert_eq!(source_id_for("unknown", "x"), None);
    }

    #[test]
    fn parsing_plain_structured_multiline_and_failures() {
        let plain = parse_input("line1\nline2", false);
        assert_eq!(plain.len(), 2);

        let ml = parse_input(
            "2026-03-05 12:00:01 first\n  stack1\n2026-03-05 12:00:02 second",
            true,
        );
        assert_eq!(ml.len(), 2);
        assert!(starts_multiline_event("2026-03-05 12:00:01 x"));
        assert!(starts_multiline_event("{\"a\":1}"));

        let v = redact_value(&json!({"password":"abc","token":"x","k":"ok"}));
        assert_eq!(v["password"], "***redacted***");
        assert_eq!(v["token"], "***redacted***");
        assert_eq!(v["k"], "ok");
    }

    #[tokio::test]
    async fn receiver_permission_spawn_and_parse_fail_generate_events() {
        let app = build_app(test_state());

        let denied = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/receivers/parse")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"receiver_kind":"file_tail","source":"permission_denied"}"#,
            ))
            .expect("request");
        assert_eq!(
            app.clone()
                .oneshot(denied)
                .await
                .expect("response")
                .status(),
            StatusCode::FORBIDDEN
        );

        let spawn = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/receivers/parse")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"receiver_kind":"stdout_stderr","source":"spawn_failed"}"#,
            ))
            .expect("request");
        assert_eq!(
            app.clone().oneshot(spawn).await.expect("response").status(),
            StatusCode::BAD_REQUEST
        );

        let parse = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/receivers/parse")
            .header("content-type", "application/json")
            .body(Body::from(
                r#"{"receiver_kind":"journald","source":"{bad-json}"}"#,
            ))
            .expect("request");
        assert_eq!(
            app.clone().oneshot(parse).await.expect("response").status(),
            StatusCode::OK
        );

        let events_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/events")
            .body(Body::empty())
            .expect("request");
        let resp = app.oneshot(events_req).await.expect("response");
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        let empty = Vec::new();
        let events = json["events"].as_array().unwrap_or(&empty);
        assert!(events
            .iter()
            .any(|e| e["kind"] == "observability_gap.receiver_permission_denied"));
        assert!(events
            .iter()
            .any(|e| e["kind"] == "observability_gap.receiver_process_spawn_failed"));
        assert!(events
            .iter()
            .any(|e| e["kind"] == "data_quality.receiver_parse_failed"));
    }
}
