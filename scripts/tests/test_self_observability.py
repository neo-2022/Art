from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class SelfObsTests(unittest.TestCase):
    def test_self_observability_declares_required_incidents(self):
        text = (ROOT / "docs/ops/self_observability.md").read_text(encoding="utf-8")
        required = (
            "core.high_latency",
            "agent.spool_near_full",
            "dlq_non_empty",
            "source_stale",
        )
        for name in required:
            self.assertIn(name, text)
        self.assertIn("docs/runbooks/core_high_latency.md", text)
        self.assertIn("docs/runbooks/agent_spool_near_full.md", text)
        self.assertIn("docs/runbooks/dlq_non_empty.md", text)
        self.assertIn("docs/runbooks/source_stale.md", text)

    def test_alert_thresholds_are_fixed(self):
        text = (ROOT / "docs/ops/alerts.md").read_text(encoding="utf-8")
        self.assertIn("p95 ingest latency > 500ms", text)
        self.assertIn("spool usage ratio >= 0.90", text)
        self.assertIn("dlq_size > 0", text)
        self.assertIn("source_stale threshold 600000ms", text)

    def test_gap_registry_has_required_action_refs(self):
        text = (
            ROOT / "docs/governance/observability_gap_registry.md"
        ).read_text(encoding="utf-8")
        self.assertIn("observability_gap.metrics_unavailable", text)
        self.assertIn("docs/runbooks/metrics_unavailable.md", text)
        self.assertIn("observability_gap.source_stale", text)
        self.assertIn("docs/runbooks/source_stale.md", text)


if __name__ == "__main__":
    unittest.main()
