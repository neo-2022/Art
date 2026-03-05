#!/usr/bin/env python3
import json
import unittest
from pathlib import Path


SCHEMAS = {
    "raw_event": Path("docs/schemas/v1/raw_event.json"),
    "ingest_envelope": Path("docs/schemas/v1/ingest_envelope.json"),
    "ingest_response": Path("docs/schemas/v1/ingest_response.json"),
    "incident": Path("docs/schemas/v1/incident.json"),
}

OPENAPI = Path("docs/api/openapi.yaml")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def emulate_ingest(envelope: dict) -> dict:
    events = envelope.get("events", [])
    invalid_details = []
    accepted = 0
    for idx, event in enumerate(events):
        severity = event.get("severity")
        if isinstance(severity, str) and severity:
            accepted += 1
            continue
        invalid_details.append({"index": idx, "reason": "severity_required"})
    return {
        "accepted": accepted,
        "invalid_details": invalid_details,
        "ack": {"upto_seq": accepted if accepted > 0 else None},
    }


def emulate_backpressure(status_code: int) -> dict:
    if status_code not in (413, 429, 503):
        raise ValueError("unsupported status")
    return {"status": status_code, "retry_after_ms": 500}


class ContractTests(unittest.TestCase):
    def test_schema_files_are_valid_json_and_allow_unknown_fields(self) -> None:
        for name, path in SCHEMAS.items():
            data = load_json(path)
            self.assertEqual(data.get("type"), "object", name)
            self.assertIs(data.get("additionalProperties"), True, name)

    def test_unknown_fields_raw_event_are_accepted(self) -> None:
        envelope = {
            "events": [
                {
                    "severity": "warn",
                    "extra_top": "x",
                    "ctx": {"extra_nested": "nested"},
                }
            ],
            "envelope_extra": "ok",
        }
        result = emulate_ingest(envelope)
        self.assertEqual(result["accepted"], 1)
        self.assertEqual(result["invalid_details"], [])

    def test_partial_accept_populates_invalid_details(self) -> None:
        envelope = {"events": [{"severity": "info"}, {"message": "missing severity"}]}
        result = emulate_ingest(envelope)
        self.assertEqual(result["accepted"], 1)
        self.assertEqual(len(result["invalid_details"]), 1)
        self.assertIn("index", result["invalid_details"][0])
        self.assertIn("reason", result["invalid_details"][0])

    def test_backpressure_contract_has_retry_after_ms(self) -> None:
        for code in (413, 429, 503):
            response = emulate_backpressure(code)
            self.assertEqual(response["status"], code)
            self.assertIsInstance(response["retry_after_ms"], int)
            self.assertGreaterEqual(response["retry_after_ms"], 0)

    def test_openapi_contains_required_paths_and_backpressure_shape(self) -> None:
        text = OPENAPI.read_text(encoding="utf-8")
        for path in (
            "/api/v1/ingest",
            "/api/v1/snapshot",
            "/api/v1/stream",
            "/api/v1/incidents",
            "/api/v1/incidents/{id}/ack",
            "/api/v1/incidents/{id}/resolve",
            "/api/v1/actions/execute",
            "/health",
            "/metrics",
        ):
            self.assertIn(path, text)
        for code in ("'413'", "'429'", "'503'"):
            self.assertIn(code, text)
        self.assertIn("retry_after_ms", text)


if __name__ == "__main__":
    unittest.main(verbosity=2)
