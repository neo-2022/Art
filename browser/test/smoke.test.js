import test from "node:test";
import assert from "node:assert/strict";

import { sum } from "../src/index.js";

test("sum returns expected value", () => {
  assert.equal(sum(2, 3), 5);
});
