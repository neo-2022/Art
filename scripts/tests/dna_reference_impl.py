#!/usr/bin/env python3
"""Reference DNA canonicalization/signature implementation (slow-but-correct)."""

from __future__ import annotations

import hashlib
import json
import sys
from typing import Any

DNA_SCHEMA_VERSION = "v2.0.0"
IGNORE_KEYS = {
    "ts",
    "ts_ms",
    "timestamp",
    "ingest_ts_ms",
    "event_id",
    "received_at",
    "ingested_at_ms",
}


def normalize(value: Any) -> Any:
    if isinstance(value, dict):
        out = {}
        for key in sorted(value.keys()):
            if key in IGNORE_KEYS:
                continue
            out[key] = normalize(value[key])
        return out
    if isinstance(value, list):
        return [normalize(item) for item in value]
    return value


def canonical_json(value: Any) -> str:
    normalized = normalize(value)
    return json.dumps(normalized, separators=(",", ":"), ensure_ascii=False)


def sha256_hex(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def build_signature(event: Any) -> dict[str, str]:
    canonical = canonical_json(event)
    canonical_hash = sha256_hex(canonical)
    payload_hash = sha256_hex(json.dumps(event, separators=(",", ":"), ensure_ascii=False))
    dna_id = sha256_hex(f"{DNA_SCHEMA_VERSION}:{canonical_hash}")
    return {
        "dna_id": dna_id,
        "canonical_hash": canonical_hash,
        "payload_hash": payload_hash,
        "dna_schema_version": DNA_SCHEMA_VERSION,
    }


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: dna_reference_impl.py <event.json>", file=sys.stderr)
        return 2

    path = sys.argv[1]
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)

    print(json.dumps(build_signature(data), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
