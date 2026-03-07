#!/usr/bin/env python3
import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path("/home/art/Art")
EVAL = ROOT / "scripts/ci/evaluate_osv_report.py"
ACCEPT = ROOT / "docs/security/osv_risk_accept.yaml"


def run_report(payload: dict) -> int:
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "report.json"
        path.write_text(json.dumps(payload), encoding="utf-8")
        proc = subprocess.run(
            ["python3", str(EVAL), str(path), str(ACCEPT)],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        return proc.returncode


def test_policy_only_signal_without_accept_is_not_blocking() -> None:
    payload = {
        "results": [
            {
                "source": {"path": "Cargo.lock"},
                "packages": [
                    {
                        "package": {"name": "demo"},
                        "vulnerabilities": [{"id": "OSV-POLICY-1", "severity": []}],
                    }
                ],
            }
        ]
    }
    assert run_report(payload) == 0


def test_medium_low_without_accept_is_blocking() -> None:
    payload = {
        "results": [
            {
                "source": {"path": "Cargo.lock"},
                "packages": [
                    {
                        "package": {"name": "demo"},
                        "vulnerabilities": [{"id": "OSV-LOW-1", "severity": [{"score": "LOW"}]}],
                    }
                ],
            }
        ]
    }
    assert run_report(payload) == 1


def test_accepted_policy_signal_passes() -> None:
    payload = {
        "results": [
            {
                "source": {"path": "Cargo.lock"},
                "packages": [
                    {
                        "package": {"name": "rustls-pemfile"},
                        "vulnerabilities": [{"id": "RUSTSEC-2025-0134", "severity": []}],
                    }
                ],
            }
        ]
    }
    assert run_report(payload) == 0
