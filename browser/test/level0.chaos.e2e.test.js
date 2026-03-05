import test from "node:test";
import assert from "node:assert/strict";

import { Level0MultiTabCoordinator } from "../src/level0_multitab.js";
import { InMemoryOutboxStore, Level0Outbox } from "../src/outbox.js";

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
      close: () => set.delete(endpoint),
    };
    set.add(endpoint);
    return endpoint;
  }
}

function workerFactoryOk() {
  return {
    async execute(_operationName, runOnMainThread) {
      return runOnMainThread();
    },
  };
}

test("chaos: transient ingest error не блокирует повторную отправку dedup_key", async () => {
  const sharedLocalStorage = new MemoryStorage();
  const session = new MemoryStorage();
  const hub = new FakeChannelHub();
  let nowMs = 1_000;
  let attempt = 0;
  const ingested = [];

  const coordinator = new Level0MultiTabCoordinator({
    sessionStorage: session,
    localStorage: sharedLocalStorage,
    broadcastChannelFactory: (name) => hub.create(name),
    ingestFn: async (payload) => {
      attempt += 1;
      if (attempt === 1) {
        throw new Error("transient ingest unavailable");
      }
      ingested.push(payload);
    },
    now: () => nowMs,
    tabId: "tab-chaos-a",
  });

  coordinator.refreshLeadership();
  const event = { kind: "chaos.event", payload: { id: 1 }, ts_ms: 1010 };

  await assert.rejects(coordinator.publishEvent(event), /transient ingest unavailable/);
  nowMs += 1;
  await coordinator.publishEvent(event);

  assert.equal(ingested.length, 1);
  coordinator.stop();
});

test("chaos: outbox flush retry сохраняет pending после fail и доставляет при повторе", async () => {
  const store = new InMemoryOutboxStore();
  const ingested = [];
  let attempt = 0;
  const outbox = new Level0Outbox({
    store,
    ingestFn: async (payload) => {
      attempt += 1;
      if (attempt === 1) {
        throw new Error("upstream timeout");
      }
      ingested.push(payload);
    },
    codec: {
      gzip: async (bytes) => bytes,
      gunzip: async (bytes) => bytes,
    },
    now: () => 2_000,
    workerFactory: workerFactoryOk,
  });

  await outbox.enqueue({ kind: "raw.event", payload: { retry: true }, ts_ms: 2001 });
  await assert.rejects(outbox.flushAll(), /upstream timeout/);
  assert.equal((await store.listPending()).length, 1);

  await outbox.flushAll();
  assert.equal((await store.listPending()).length, 0);
  assert.equal(ingested.length, 1);
});
