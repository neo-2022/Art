#!/usr/bin/env python3
import json
import unittest
from pathlib import Path

import jsonschema


SCHEMA_PATH = Path("docs/contracts/v2/schemas/investigation_doc_v1.json")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class InvestigationDocSchemaTests(unittest.TestCase):
    def test_schema_is_valid_json_schema(self) -> None:
        schema = load_json(SCHEMA_PATH)
        jsonschema.Draft202012Validator.check_schema(schema)

    def test_valid_payload_passes_validation(self) -> None:
        schema = load_json(SCHEMA_PATH)
        payload = {
            "doc_id": "inv-001",
            "doc_version": 1,
            "created_at": 1741264800000,
            "updated_at": 1741268400000,
            "claims": [
                {
                    "claim_id": "cl-1",
                    "statement": "Core degraded because queue depth exceeded threshold.",
                    "status": "valid",
                    "evidence_refs": ["ev-1", "ev-2"]
                }
            ],
            "decisions": [
                {
                    "decision_id": "dec-1",
                    "text": "Scale workers to restore throughput.",
                    "evidence_refs": ["ev-2"]
                }
            ],
            "actions": [
                {
                    "action_id": "act-1",
                    "kind": "scale_workers",
                    "status": "executed"
                }
            ],
            "results": [
                {
                    "result_id": "res-1",
                    "action_id": "act-1",
                    "summary": "Queue depth returned to SLO budget."
                }
            ],
            "evidence_refs": ["ev-1", "ev-2"],
            "audit_refs": ["aud-1"],
            "proofs": [
                {"proof_id": "pr-1", "kind": "merkle", "ref": "proof://merkle/aud-1"}
            ]
        }
        jsonschema.validate(payload, schema)

    def test_invalid_payload_missing_required_fields_fails(self) -> None:
        schema = load_json(SCHEMA_PATH)
        invalid_payload = {
            "doc_id": "inv-002",
            "doc_version": 1
        }
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(invalid_payload, schema)


if __name__ == "__main__":
    unittest.main(verbosity=2)
