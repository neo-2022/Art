import test from "node:test";
import assert from "node:assert/strict";

import {
  createServiceWorkerScript,
  evaluateCoreAvailability,
  gapStyleForEvent,
  panel0CacheName,
  panel0Diagnostics,
  resolvePanel0Fetch,
  shouldRegisterServiceWorker,
} from "../src/index.js";

test("e2e: gap highlight icon/color/tooltip для observability_gap.*", () => {
  const event = {
    kind: "observability_gap.stream_unavailable",
    details: {
      what: "stream down",
      where: "/api/v1/stream",
      why: "storage_error",
      actions: { action_ref: "docs/runbooks/stream_unavailable.md" },
      trace_id: "trace-1",
    },
  };
  const style = gapStyleForEvent(event);
  assert.ok(style);
  assert.equal(style.icon, "⚠");
  assert.equal(style.color, "amber");
  assert.equal(style.tooltip.kind, "observability_gap.stream_unavailable");
  assert.equal(style.tooltip.where, "/api/v1/stream");
  assert.equal(style.tooltip.action_ref, "docs/runbooks/stream_unavailable.md");
  assert.equal(style.tooltip.trace_id, "trace-1");
});

test("e2e: tooltip redaction скрывает секреты", () => {
  const style = gapStyleForEvent({
    kind: "observability_gap.any",
    details: {
      what: "Authorization: Bearer token-abc",
      where: "cookie=session",
      why: "password=123",
      trace_id: "trace-2",
    },
  });
  assert.equal(style.tooltip.what, "***redacted***");
  assert.equal(style.tooltip.where, "***redacted***");
  assert.equal(style.tooltip.why, "***redacted***");
});

test("e2e: core-down placeholder conditions + reload/recovery semantics", () => {
  const downByHealth = evaluateCoreAvailability({
    health: { status: 503 },
    snapshot: { status: 200 },
  });
  assert.equal(downByHealth.coreDown, true);
  assert.equal(downByHealth.reason, "HTTP 503");

  const downByNetwork = evaluateCoreAvailability({
    health: { status: 200 },
    snapshot: { networkError: true },
  });
  assert.equal(downByNetwork.coreDown, true);
  assert.equal(downByNetwork.reason, "network error");

  const recovered = evaluateCoreAvailability({
    health: { status: 200 },
    snapshot: { status: 200 },
  });
  assert.equal(recovered.coreDown, false);
});

test("e2e: offline cache script uses panel0-cache-<build_id> and skipWaiting", () => {
  const buildId = "build-42";
  const script = createServiceWorkerScript(buildId);
  assert.equal(panel0CacheName(buildId), "panel0-cache-build-42");
  assert.ok(script.includes("panel0-cache-build-42"));
  assert.ok(script.includes("self.skipWaiting();"));
  assert.ok(script.includes('"x-art-offline": "1"'));
  assert.ok(script.includes("/panel0/index.html"));
  assert.ok(script.includes("/panel0/panel0.js"));
  assert.ok(script.includes("/panel0/panel0.css"));
  assert.equal(shouldRegisterServiceWorker("/panel0"), true);
  assert.equal(shouldRegisterServiceWorker("/panel0", false), false);
  assert.equal(shouldRegisterServiceWorker("/"), false);
});

test("e2e: sw negative — cache put failure не ломает online response", async () => {
  const response = { status: 200, body: "ok" };
  const resolved = await resolvePanel0Fetch({
    request: { method: "GET", url: "/panel0/panel0.js" },
    fetchFn: async () => response,
    cachePutFn: async () => {
      throw new Error("cache quota exceeded");
    },
  });
  assert.equal(resolved.status, 200);
  assert.equal(resolved.body, "ok");
});

test("e2e: sw negative — offline + cache miss возвращает 503 offline marker", async () => {
  const resolved = await resolvePanel0Fetch({
    request: { method: "GET", url: "/panel0/index.html" },
    fetchFn: async () => {
      throw new Error("network down");
    },
    cacheMatchFn: async () => null,
  });
  assert.equal(resolved.status, 503);
  assert.equal(resolved.headers["x-art-offline"], "1");
  assert.equal(resolved.body, "offline");
});

test("e2e: diagnostics shows build_id and effective_profile_id", () => {
  const diagnostics = panel0Diagnostics(
    { effective_profile_id: "eu" },
    "build-99"
  );
  assert.equal(diagnostics.build_id, "build-99");
  assert.equal(diagnostics.effective_profile_id, "eu");
});
