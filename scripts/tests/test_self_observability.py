import unittest


def evaluate_alerts(ingest_p95, spool_used, spool_capacity, dlq_size, source_stale):
    incidents = []
    if ingest_p95 > 500:
        incidents.append("core.high_latency")
    if spool_capacity > 0 and (spool_used / spool_capacity) >= 0.90:
        incidents.append("agent.spool_near_full")
    if dlq_size > 0:
        incidents.append("dlq_non_empty")
    if source_stale:
        incidents.append("source_stale")
    return incidents


class SelfObsTests(unittest.TestCase):
    def test_core_high_latency(self):
        incidents = evaluate_alerts(ingest_p95=700, spool_used=10, spool_capacity=100, dlq_size=0, source_stale=False)
        self.assertIn("core.high_latency", incidents)

    def test_agent_spool_near_full(self):
        incidents = evaluate_alerts(ingest_p95=100, spool_used=90, spool_capacity=100, dlq_size=0, source_stale=False)
        self.assertIn("agent.spool_near_full", incidents)

    def test_dlq_non_empty(self):
        incidents = evaluate_alerts(ingest_p95=100, spool_used=10, spool_capacity=100, dlq_size=1, source_stale=False)
        self.assertIn("dlq_non_empty", incidents)

    def test_source_stale(self):
        incidents = evaluate_alerts(ingest_p95=100, spool_used=10, spool_capacity=100, dlq_size=0, source_stale=True)
        self.assertIn("source_stale", incidents)


if __name__ == "__main__":
    unittest.main()
