use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::Context;
use axum_server::tls_rustls::RustlsConfig;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tracing::{info, warn};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StartupBacklogEntry {
    pub kind: String,
    pub details: Value,
    pub persisted_at_ms: u64,
}

impl StartupBacklogEntry {
    pub fn new(kind: impl Into<String>, details: Value) -> Self {
        Self {
            kind: kind.into(),
            details,
            persisted_at_ms: now_ms(),
        }
    }
}

pub fn load_tls_config_from_env() -> Option<(PathBuf, PathBuf)> {
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

pub fn install_runtime_signal_handlers() {
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

pub fn startup_backlog_path(db_path: &Path) -> PathBuf {
    db_path.with_extension("startup_backlog.json")
}

pub fn append_startup_backlog(path: &Path, entry: &StartupBacklogEntry) {
    let mut entries = load_startup_backlog(path);
    entries.push(entry.clone());
    persist_startup_backlog(path, &entries);
}

pub async fn load_tls_server_config(
    cert_path: &Path,
    key_path: &Path,
    startup_backlog_path: &Path,
) -> anyhow::Result<RustlsConfig> {
    match RustlsConfig::from_pem_file(cert_path, key_path).await {
        Ok(tls) => Ok(tls),
        Err(error) => {
            let trace_id = format!("tls-config-invalid-{}", now_ms());
            append_startup_backlog(
                startup_backlog_path,
                &StartupBacklogEntry::new(
                    "observability_gap.tls_config_invalid",
                    json!({
                        "component": "core/tls",
                        "reason": "cert_key_mismatch",
                        "stage": "startup_tls_bootstrap",
                        "cert_path": cert_path.display().to_string(),
                        "key_path": key_path.display().to_string(),
                        "error": error.to_string(),
                        "trace_id": trace_id
                    }),
                ),
            );
            Err(error).with_context(|| {
                format!(
                    "failed to load TLS cert/key (cert={}, key={})",
                    cert_path.display(),
                    key_path.display()
                )
            })
        }
    }
}

pub fn replay_startup_backlog<F>(path: &Path, mut publish: F) -> usize
where
    F: FnMut(&str, Value),
{
    let entries = load_startup_backlog(path);
    if entries.is_empty() {
        return 0;
    }
    let count = entries.len();
    for entry in entries {
        let mut details = entry.details;
        if let Some(obj) = details.as_object_mut() {
            obj.insert("startup_backlog".to_string(), Value::Bool(true));
            obj.insert(
                "startup_backlog_persisted_at_ms".to_string(),
                Value::from(entry.persisted_at_ms),
            );
        }
        publish(&entry.kind, details);
    }
    if let Err(error) = fs::remove_file(path) {
        warn!(
            "failed to remove startup backlog file {} after replay: {}",
            path.display(),
            error
        );
    }
    count
}

fn load_startup_backlog(path: &Path) -> Vec<StartupBacklogEntry> {
    match fs::read_to_string(path) {
        Ok(raw) => match serde_json::from_str::<Vec<StartupBacklogEntry>>(&raw) {
            Ok(entries) => entries,
            Err(error) => {
                warn!(
                    "failed to parse startup backlog {}: {}",
                    path.display(),
                    error
                );
                Vec::new()
            }
        },
        Err(_) => Vec::new(),
    }
}

fn persist_startup_backlog(path: &Path, entries: &[StartupBacklogEntry]) {
    if let Some(parent) = path.parent() {
        if let Err(error) = fs::create_dir_all(parent) {
            warn!(
                "failed to create startup backlog directory {}: {}",
                parent.display(),
                error
            );
            return;
        }
    }
    let serialized = match serde_json::to_string_pretty(entries) {
        Ok(value) => value,
        Err(error) => {
            warn!(
                "failed to serialize startup backlog {}: {}",
                path.display(),
                error
            );
            return;
        }
    };
    let tmp = path.with_extension("startup_backlog.tmp");
    if let Err(error) = fs::write(&tmp, serialized) {
        warn!(
            "failed to write startup backlog temp file {}: {}",
            tmp.display(),
            error
        );
        return;
    }
    if let Err(error) = fs::rename(&tmp, path) {
        warn!(
            "failed to replace startup backlog file {}: {}",
            path.display(),
            error
        );
    }
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("clock drift")
        .as_millis() as u64
}
