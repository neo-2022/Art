import test from "node:test";
import assert from "node:assert/strict";
import { createWorkerRuntime } from "../dist/index.js";

test("worker-runtime: validates task id/type", async () => {
  const runtime = createWorkerRuntime();
  const invalid = await runtime.runTask({ id: "", type: "", payload: {} });
  assert.equal(invalid.ok, false);

  const ok = await runtime.runTask({ id: "t1", type: "dna.compute", payload: { x: 1 } });
  assert.equal(ok.ok, true);
  assert.deepEqual(ok.data, { x: 1 });
});
