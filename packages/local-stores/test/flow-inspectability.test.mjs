import test from "node:test";
import assert from "node:assert/strict";
import { createLocalStores } from "../dist/index.js";

test("flow inspectability: every semantic node type resolves evidence lineage", () => {
  const stores = createLocalStores();
  const scene = stores.buildFlowScene();
  const nodeTypes = new Set(stores.flowNodeTypes());

  for (const node of scene.nodes) {
    const details = stores.inspectFlowNode(node.node_id);
    assert.ok(details, `missing inspect data for ${node.node_id}`);
    assert.ok(Array.isArray(details.evidence_refs) && details.evidence_refs.length > 0);
    assert.ok(Array.isArray(details.lineage) && details.lineage.length > 0);
    nodeTypes.delete(node.type);
  }

  assert.equal(nodeTypes.size, 0, "all semantic node types must be represented in flow scene");
});
