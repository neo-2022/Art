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

test("flow snapshot replay: serialize/restore keeps positions and visibility", () => {
  const stores = createLocalStores();
  const scene = stores.buildFlowScene();
  const snapshotId = "snap-flow-1";
  const snapshot = {
    layout_id: "flow-layout",
    positions: {},
    visibility: {},
    lod: "standard",
    flow_complexity: "advanced"
  };

  scene.nodes.forEach((node, index) => {
    stores.setPosition(node.node_id, { x: index * 3, y: index * 5 }, "flow-layout");
    snapshot.positions[node.node_id] = { x: index * 3, y: index * 5 };
    snapshot.visibility[node.node_id] = index % 2 === 0;
  });

  stores.saveSnapshot(snapshotId, snapshot);
  const restored = stores.loadSnapshot(snapshotId);
  assert.deepEqual(restored, snapshot);
});
