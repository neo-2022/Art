import test from "node:test";
import assert from "node:assert/strict";

import {
  Level0MultiTabCoordinator,
  canonicalJsonWithoutTsMs,
} from "../src/level0_multitab.js";

class MemoryStorage {
  constructor() {
    this._data = new Map();
  }
  getItem(key) {
    return this._data.has(key) ? this._data.get(key) : null;
  }
  setItem(key, value) {
    this._data.set(key, String(value));
  }
}

class FakeChannelHub {
  constructor() {
    this._channels = new Map();
  }
  create(name) {
    if (!this._channels.has(name)) {
      this._channels.set(name, new Set());
    }
    const set = this._channels.get(name);
    const endpoint = {
      onmessage: null,
      postMessage: (data) => {
        for (const peer of set) {
          if (peer === endpoint || typeof peer.onmessage !== "function") {
            continue;
          }
          peer.onmessage({ data });
        }
      },
      close: () => {
        set.delete(endpoint);
      },
    };
    set.add(endpoint);
    return endpoint;
  }
}

test("multi-tab: обе вкладки видят локально, в ingest уходит 1 событие", async () => {
  const sharedLocalStorage = new MemoryStorage();
  const sessionA = new MemoryStorage();
  const sessionB = new MemoryStorage();
  const hub = new FakeChannelHub();
  const ingested = [];
  let nowMs = 1000;
  const now = () => nowMs;

  const createCoordinator = (sessionStorage, tabId) =>
    new Level0MultiTabCoordinator({
      sessionStorage,
      localStorage: sharedLocalStorage,
      broadcastChannelFactory: (name) => hub.create(name),
      ingestFn: async (payload) => {
        ingested.push(payload);
      },
      now,
      tabId,
    });

  const tabA = createCoordinator(sessionA, "tab-a");
  const tabB = createCoordinator(sessionB, "tab-b");

  tabA.refreshLeadership();
  tabB.refreshLeadership();
  assert.equal(tabA.isLeader(), true);
  assert.equal(tabB.isLeader(), false);

  const localA = [];
  const localB = [];
  tabA.subscribeLocal((event) => localA.push(event));
  tabB.subscribeLocal((event) => localB.push(event));

  const eventA = { kind: "demo.event", payload: { value: 1 }, ts_ms: 1111 };
  const eventB = { kind: "demo.event", payload: { value: 1 }, ts_ms: 2222 };

  await tabA.publishEvent(eventA);
  await tabB.publishEvent(eventB);

  assert.equal(localA.length, 2);
  assert.equal(localB.length, 2);
  assert.equal(ingested.length, 1);
  assert.equal(
    canonicalJsonWithoutTsMs(ingested[0].event),
    canonicalJsonWithoutTsMs(eventA)
  );

  tabA.stop();
  tabB.stop();
});

test("multi-tab: лидерство переходит при stale lock > 3000ms", () => {
  const sharedLocalStorage = new MemoryStorage();
  const sessionA = new MemoryStorage();
  const sessionB = new MemoryStorage();
  const hub = new FakeChannelHub();
  let nowMs = 1000;
  const now = () => nowMs;

  const createCoordinator = (sessionStorage, tabId) =>
    new Level0MultiTabCoordinator({
      sessionStorage,
      localStorage: sharedLocalStorage,
      broadcastChannelFactory: (name) => hub.create(name),
      ingestFn: async () => {},
      now,
      tabId,
    });

  const tabA = createCoordinator(sessionA, "tab-a");
  const tabB = createCoordinator(sessionB, "tab-b");

  tabA.refreshLeadership();
  assert.equal(tabA.isLeader(), true);

  nowMs += 4001;
  const becameLeader = tabB.refreshLeadership();
  assert.equal(becameLeader, true);
  assert.equal(tabB.isLeader(), true);
  assert.equal(tabA.isLeader(), false);

  tabA.stop();
  tabB.stop();
});

test("cors blocked: генерируется observability_gap.cors_blocked c обязательным evidence", async () => {
  const sharedLocalStorage = new MemoryStorage();
  const sessionA = new MemoryStorage();
  const hub = new FakeChannelHub();
  const gapEvents = [];
  const now = () => 1000;

  const tabA = new Level0MultiTabCoordinator({
    sessionStorage: sessionA,
    localStorage: sharedLocalStorage,
    broadcastChannelFactory: (name) => hub.create(name),
    ingestFn: async () => {
      throw new TypeError("Failed to fetch");
    },
    emitGapFn: async (gapEvent) => {
      gapEvents.push(gapEvent);
    },
    ingestEndpoint: "https://art.local/api/v1/ingest",
    browserOrigin: "https://ui.local",
    maxRetries: 2,
    now,
    tabId: "tab-a",
  });

  tabA.refreshLeadership();
  await assert.rejects(
    tabA.publishEvent({ kind: "demo.event", payload: { id: 1 }, ts_ms: 1001 }),
    /Failed to fetch/
  );

  assert.equal(gapEvents.length, 1);
  const gap = gapEvents[0];
  assert.equal(gap.kind, "observability_gap.cors_blocked");
  assert.equal(gap.where, "browser.level0.ingest");
  assert.equal(gap.why, "cors_blocked");
  assert.ok(typeof gap.what === "string" && gap.what.length > 0);
  assert.ok(typeof gap.trace_id === "string" && gap.trace_id.length > 0);
  assert.equal(gap.evidence.endpoint, "https://art.local/api/v1/ingest");
  assert.equal(gap.evidence.browser_origin, "https://ui.local");
  assert.equal(gap.evidence.block_type, "TypeError");
  assert.equal(gap.evidence.retry_count, 2);
  assert.ok(Array.isArray(gap.actions) && gap.actions.length > 0);
  assert.equal(gap.actions[0].action_ref, "docs/runbooks/cors_blocked.md");

  tabA.stop();
});
