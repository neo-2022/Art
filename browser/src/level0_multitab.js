const LEADER_LOCK_KEY = "art:l0:leader";
const TAB_ID_KEY = "art:l0:tab_id";
const CHANNEL_NAME = "art:l0:events";
const HEARTBEAT_MS = 1000;
const LEADER_STALE_MS = 3000;
const DEDUP_TTL_MS = 300000;

function ensureCrypto() {
  if (!globalThis.crypto || !globalThis.crypto.subtle) {
    throw new Error("Web Crypto API is required");
  }
  return globalThis.crypto;
}

function sortObjectKeys(value) {
  if (Array.isArray(value)) {
    return value.map(sortObjectKeys);
  }
  if (!value || typeof value !== "object") {
    return value;
  }
  const entries = Object.keys(value)
    .sort()
    .map((key) => [key, sortObjectKeys(value[key])]);
  return Object.fromEntries(entries);
}

function stripTsMs(value) {
  if (Array.isArray(value)) {
    return value.map(stripTsMs);
  }
  if (!value || typeof value !== "object") {
    return value;
  }
  const out = {};
  for (const [key, nested] of Object.entries(value)) {
    if (key === "ts_ms") {
      continue;
    }
    out[key] = stripTsMs(nested);
  }
  return out;
}

function parseLeaderPayload(raw) {
  if (!raw) {
    return null;
  }
  try {
    const parsed = JSON.parse(raw);
    if (
      parsed &&
      typeof parsed.tab_id === "string" &&
      Number.isFinite(parsed.ts_ms)
    ) {
      return parsed;
    }
  } catch {
    return null;
  }
  return null;
}

function toHex(buffer) {
  const bytes = new Uint8Array(buffer);
  let out = "";
  for (const byte of bytes) {
    out += byte.toString(16).padStart(2, "0");
  }
  return out;
}

export function canonicalJsonWithoutTsMs(event) {
  const normalized = stripTsMs(event);
  const sorted = sortObjectKeys(normalized);
  return JSON.stringify(sorted);
}

export async function dedupKeyForEvent(event) {
  const canonical = canonicalJsonWithoutTsMs(event);
  const cryptoApi = ensureCrypto();
  const data = new TextEncoder().encode(canonical);
  const digest = await cryptoApi.subtle.digest("SHA-256", data);
  return toHex(digest);
}

export class Level0MultiTabCoordinator {
  constructor({
    sessionStorage,
    localStorage,
    broadcastChannelFactory,
    ingestFn,
    emitGapFn = async () => {},
    ingestEndpoint = "/api/v1/ingest",
    browserOrigin = globalThis.location?.origin || "unknown",
    maxRetries = 0,
    now = () => Date.now(),
    tabId,
  }) {
    this._sessionStorage = sessionStorage;
    this._localStorage = localStorage;
    this._ingestFn = ingestFn;
    this._emitGapFn = emitGapFn;
    this._ingestEndpoint = ingestEndpoint;
    this._browserOrigin = browserOrigin;
    this._maxRetries = maxRetries;
    this._now = now;
    this._localListeners = new Set();
    this._dedupTable = new Map();
    this._heartbeatTimer = null;
    this._channel = broadcastChannelFactory(CHANNEL_NAME);
    this._channel.onmessage = (message) => this._onChannelMessage(message.data);

    const existingTabId = this._sessionStorage.getItem(TAB_ID_KEY);
    this.tabId = existingTabId || tabId || ensureCrypto().randomUUID();
    if (!existingTabId) {
      this._sessionStorage.setItem(TAB_ID_KEY, this.tabId);
    }
  }

  subscribeLocal(listener) {
    this._localListeners.add(listener);
    return () => this._localListeners.delete(listener);
  }

  start() {
    this.refreshLeadership();
    this._heartbeatTimer = setInterval(() => {
      this.refreshLeadership();
    }, HEARTBEAT_MS);
  }

  stop() {
    if (this._heartbeatTimer) {
      clearInterval(this._heartbeatTimer);
      this._heartbeatTimer = null;
    }
    if (this._channel && typeof this._channel.close === "function") {
      this._channel.close();
    }
  }

  isLeader() {
    const leader = parseLeaderPayload(this._localStorage.getItem(LEADER_LOCK_KEY));
    if (!leader) {
      return false;
    }
    const stale = this._now() - leader.ts_ms > LEADER_STALE_MS;
    return !stale && leader.tab_id === this.tabId;
  }

  refreshLeadership() {
    const nowMs = this._now();
    const leader = parseLeaderPayload(this._localStorage.getItem(LEADER_LOCK_KEY));
    const stale = !leader || nowMs - leader.ts_ms > LEADER_STALE_MS;
    const mine = leader && leader.tab_id === this.tabId;
    if (stale || mine) {
      this._localStorage.setItem(
        LEADER_LOCK_KEY,
        JSON.stringify({ tab_id: this.tabId, ts_ms: nowMs })
      );
      return true;
    }
    return false;
  }

  async publishEvent(event) {
    this._emitLocal(event);
    this._channel.postMessage({ type: "event", source_tab_id: this.tabId, event });
    if (this.isLeader()) {
      await this._flushOne(event);
    }
  }

  async _onChannelMessage(data) {
    if (!data || data.type !== "event") {
      return;
    }
    if (data.source_tab_id === this.tabId) {
      return;
    }
    this._emitLocal(data.event);
    if (this.isLeader()) {
      await this._flushOne(data.event);
    }
  }

  _emitLocal(event) {
    for (const listener of this._localListeners) {
      listener(event);
    }
  }

  _pruneDedup() {
    const nowMs = this._now();
    for (const [key, expiresAt] of this._dedupTable.entries()) {
      if (expiresAt <= nowMs) {
        this._dedupTable.delete(key);
      }
    }
  }

  async _flushOne(event) {
    this._pruneDedup();
    const dedupKey = await dedupKeyForEvent(event);
    if (this._dedupTable.has(dedupKey)) {
      return;
    }
    this._dedupTable.set(dedupKey, this._now() + DEDUP_TTL_MS);
    try {
      await this._ingestFn({ event, dedup_key: dedupKey });
    } catch (error) {
      if (this._isCorsBlockedError(error)) {
        await this._emitGapFn(
          this._buildCorsBlockedEvent({
            error,
            retryCount: this._maxRetries,
          })
        );
      }
      throw error;
    }
  }

  _isCorsBlockedError(error) {
    if (!error || typeof error !== "object") {
      return false;
    }
    const name = String(error.name || "");
    const message = String(error.message || "");
    if (name === "TypeError") {
      return true;
    }
    return /cors|failed to fetch|networkerror/i.test(message);
  }

  _buildCorsBlockedEvent({ error, retryCount }) {
    const traceId = ensureCrypto().randomUUID();
    return {
      kind: "observability_gap.cors_blocked",
      ts_ms: this._now(),
      trace_id: traceId,
      what: "CORS blocked request to ingest",
      where: "browser.level0.ingest",
      why: "cors_blocked",
      evidence: {
        endpoint: this._ingestEndpoint,
        browser_origin: this._browserOrigin,
        block_type: String(error?.name || "unknown_error"),
        retry_count: Number.isInteger(retryCount) && retryCount >= 0 ? retryCount : 0,
        error_message: String(error?.message || "unknown"),
      },
      actions: [
        {
          rel: "runbook",
          action_ref: "docs/runbooks/cors_blocked.md",
          description: "Проверить CORS allowlist и preflight policy.",
        },
      ],
    };
  }
}

export const level0MultiTabConfig = {
  leaderLockKey: LEADER_LOCK_KEY,
  channelName: CHANNEL_NAME,
  heartbeatMs: HEARTBEAT_MS,
  leaderStaleMs: LEADER_STALE_MS,
  dedupTtlMs: DEDUP_TTL_MS,
};
