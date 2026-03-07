from __future__ import annotations

from pathlib import Path
import subprocess
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[2]


class ConnectedSystemVisibilityTests(unittest.TestCase):
    def test_visibility_yaml_has_required_sections(self) -> None:
        path = ROOT / "formats" / "connected_system_visibility_v0_2.yaml"
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        for key in (
            "required_fields",
            "status_values",
            "required_pack_fields",
            "required_ui_sections",
            "required_gap_events",
            "declared_vs_observed_rules",
        ):
            self.assertIn(key, data)
            self.assertTrue(data[key])

        required = set(data["required_fields"])
        self.assertIn("declared_data_kinds", required)
        self.assertIn("observed_data_kinds", required)

    def test_regart_manifest_carries_connected_system_projection(self) -> None:
        path = ROOT / "packs" / "regart" / "manifest.yaml"
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        for key in (
            "service_inventory",
            "receiver_examples",
            "signal_coverage_claims",
            "telemetry_endpoints",
            "regulatory_tags",
            "connected_system_projection",
        ):
            self.assertIn(key, data)
            self.assertTrue(data[key])

        self.assertGreaterEqual(len(data["service_inventory"]), 3)
        self.assertIn("declared_data_kinds", data["signal_coverage_claims"])
        self.assertIn("observed_data_kinds", data["signal_coverage_claims"])
        inventory_ids = {entry["system_id"] for entry in data["service_inventory"]}
        self.assertEqual(
            inventory_ids,
            {"regart-browser-level0", "regart-ui-proxy", "regart-langgraph-runtime"},
        )
        projection = data["connected_system_projection"]
        self.assertIn("freshness_threshold_ms", projection)
        self.assertGreater(projection["freshness_threshold_ms"], 0)
        projected_ids = {entry["system_id"] for entry in projection["systems"]}
        self.assertEqual(projected_ids, inventory_ids)
        for entry in projection["systems"]:
            self.assertIn("display_name", entry)
            self.assertTrue(entry["display_name"])
            self.assertIn("integration_kind", entry)
            self.assertIn("declared_data_kinds", entry)
            self.assertTrue(entry["declared_data_kinds"])
            self.assertIn("connection_status", entry)
            self.assertIn("connected", entry["connection_status"])
            self.assertIn("degraded", entry["connection_status"])

    def test_runbook_and_registry_are_aligned(self) -> None:
        runbook = ROOT / "docs" / "runbooks" / "connected_system_not_visible.md"
        registry = (ROOT / "docs" / "governance" / "observability_gap_registry.md").read_text(encoding="utf-8")
        self.assertIn("Mitigations", runbook.read_text(encoding="utf-8"))
        self.assertIn("Verification", runbook.read_text(encoding="utf-8"))
        self.assertIn("observability_gap.connected_system_not_visible", registry)
        self.assertIn("observability_gap.connected_system_coverage_drift", registry)

    def test_checklists_carry_connected_system_requirements(self) -> None:
        checklist18 = (ROOT / "docs" / "source" / "checklists" / "CHECKLIST_18_ART_AGENT_RECEIVERS.md").read_text(encoding="utf-8")
        checklist19 = (ROOT / "docs" / "source" / "checklists" / "CHECKLIST_19_PACKS_FRAMEWORK.md").read_text(encoding="utf-8")
        checklist20 = (ROOT / "docs" / "source" / "checklists" / "CHECKLIST_20_PACK_REGART.md").read_text(encoding="utf-8")
        checklist28 = (ROOT / "docs" / "source" / "checklists" / "CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md").read_text(encoding="utf-8")
        self.assertIn("Connected System View", checklist18)
        self.assertIn("connected_system_projection", checklist19)
        self.assertIn("connected_system_projection", checklist20)
        self.assertIn("Connected System View", checklist28)

    def test_source_coverage_docs_explain_all_regart_systems(self) -> None:
        source_coverage = (ROOT / "docs" / "packs" / "source_coverage.md").read_text(encoding="utf-8")
        receiver_coverage = (ROOT / "docs" / "agent" / "receiver_source_coverage.md").read_text(encoding="utf-8")
        for system_id in (
            "regart-browser-level0",
            "regart-ui-proxy",
            "regart-langgraph-runtime",
        ):
            self.assertIn(system_id, source_coverage)
        for marker in (
            "produced_data_kinds",
            "connected_system_projection",
            "declared_data_kinds",
            "observed_data_kinds",
            "active_gap_events",
        ):
            self.assertIn(marker, source_coverage)
        self.assertIn("produced_data_kinds", receiver_coverage)
        self.assertIn("connected_system_projection", receiver_coverage)

    def test_manifest_signature_matches_current_manifest(self) -> None:
        result = subprocess.run(
            ["sha256sum", "-c", "signatures/manifest.sha256"],
            cwd=ROOT / "packs" / "regart",
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
