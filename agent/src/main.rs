use std::env;
use std::net::SocketAddr;
use std::sync::Arc;

use anyhow::Context;
use axum::extract::State;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tokio::sync::RwLock;
use tracing::info;

#[derive(Debug, Default)]
struct AgentState {
    spool_pending: u64,
    spool_dlq: u64,
    mode: String,
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
}

#[derive(Debug, Deserialize)]
struct EnqueueRequest {
    count: Option<u64>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let port = env::var("AGENT_PORT")
        .ok()
        .and_then(|v| v.parse::<u16>().ok())
        .unwrap_or(7071);

    let state = Arc::new(RwLock::new(AgentState {
        spool_pending: 0,
        spool_dlq: 0,
        mode: "never_drop_unacked".to_string(),
    }));

    let app = build_app(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    info!("art-agent listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .with_context(|| format!("failed to bind {}", addr))?;
    axum::serve(listener, app).await.context("agent server failed")?;
    Ok(())
}

fn build_app(state: Shared) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/metrics", get(metrics))
        .route("/api/v1/agent/receivers", get(receivers))
        .route("/api/v1/agent/spool/status", get(spool_status))
        .route("/api/v1/agent/spool/enqueue", post(spool_enqueue))
        .with_state(state)
}

async fn health() -> impl IntoResponse {
    Json(json!({"status":"ok","service":"art-agent"}))
}

async fn metrics(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    let body = format!(
        "agent_spool_pending {}\nagent_spool_dlq {}\n",
        s.spool_pending, s.spool_dlq
    );
    body
}

async fn receivers() -> impl IntoResponse {
    Json(ReceiverStatus {
        receivers: vec![
            "journald".to_string(),
            "file".to_string(),
            "process".to_string(),
            "otlp".to_string(),
        ],
    })
}

async fn spool_status(State(state): State<Shared>) -> impl IntoResponse {
    let s = state.read().await;
    Json(SpoolStatus {
        mode: s.mode.clone(),
        pending: s.spool_pending,
        dlq: s.spool_dlq,
    })
}

async fn spool_enqueue(
    State(state): State<Shared>,
    Json(req): Json<EnqueueRequest>,
) -> impl IntoResponse {
    let mut s = state.write().await;
    s.spool_pending += req.count.unwrap_or(1);
    Json(json!({"ok": true, "pending": s.spool_pending}))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{Request, StatusCode};
    use http_body_util::BodyExt;
    use serde_json::Value;
    use tower::ServiceExt;

    fn test_state() -> Shared {
        Arc::new(RwLock::new(AgentState {
            spool_pending: 0,
            spool_dlq: 0,
            mode: "never_drop_unacked".to_string(),
        }))
    }

    #[tokio::test]
    async fn spool_enqueue_increments_pending() {
        let app = build_app(test_state());
        let req = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"count":3}"#))
            .expect("request");

        let resp = app.oneshot(req).await.expect("response");
        assert_eq!(resp.status(), StatusCode::OK);
        let body = resp.into_body().collect().await.expect("body").to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("json");
        assert_eq!(json["ok"], true);
        assert_eq!(json["pending"], 3);
    }

    #[tokio::test]
    async fn spool_status_reflects_enqueue() {
        let app = build_app(test_state());
        let enqueue = Request::builder()
            .method("POST")
            .uri("/api/v1/agent/spool/enqueue")
            .header("content-type", "application/json")
            .body(Body::from(r#"{"count":2}"#))
            .expect("enqueue");
        app.clone().oneshot(enqueue).await.expect("enqueue response");

        let status_req = Request::builder()
            .method("GET")
            .uri("/api/v1/agent/spool/status")
            .body(Body::empty())
            .expect("status request");
        let status_resp = app.oneshot(status_req).await.expect("status response");
        assert_eq!(status_resp.status(), StatusCode::OK);
        let body = status_resp
            .into_body()
            .collect()
            .await
            .expect("status body")
            .to_bytes();
        let json: Value = serde_json::from_slice(&body).expect("status json");
        assert_eq!(json["pending"], 2);
        assert_eq!(json["mode"], "never_drop_unacked");
    }
}
