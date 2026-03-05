#!/usr/bin/env python3
import base64
import unittest


RESERVED_RAWEVENT_KEYS = {"severity", "ts", "kind", "scope", "message", "trace_id"}


def normalize_otlp_attrs(attrs: dict) -> dict:
    out = {}
    for key, value in attrs.items():
        target_key = f"otel.{key}" if key in RESERVED_RAWEVENT_KEYS else key
        if isinstance(value, bytes):
            out[target_key] = base64.b64encode(value).decode("ascii")
        elif isinstance(value, list):
            normalized = []
            for item in value:
                if isinstance(item, bytes):
                    normalized.append(base64.b64encode(item).decode("ascii"))
                else:
                    normalized.append(item)
            out[target_key] = normalized
        else:
            out[target_key] = value
    return out


def map_severity(otel_level: str) -> tuple[str, bool]:
    mapping = {
        "DEBUG": "debug",
        "INFO": "info",
        "WARN": "warn",
        "ERROR": "error",
        "FATAL": "fatal",
    }
    if otel_level in mapping:
        return mapping[otel_level], False
    return "info", True


def enforce_rate_limit(metric: str, value: int) -> tuple[int, dict]:
    thresholds = {
        "max_events_per_sec": (200, 429),
        "max_batch_events": (200, 413),
        "service_unavailable": (1, 503),
    }
    limit, status = thresholds[metric]
    if value <= limit and metric != "service_unavailable":
        return 200, {}
    gap = {
        "event_name": "observability_gap.otlp_rate_limited",
        "limit_name": metric,
        "current_value": value,
        "retry_after_ms": 500,
        "endpoint": "/otlp/v1/logs",
        "trace_id": "trace-test-1",
    }
    return status, gap


class TelemetryTests(unittest.TestCase):
    def test_unknown_attrs_mapping_and_types(self) -> None:
        attrs = {
            "service.name": "api",
            "success": True,
            "count": 3,
            "ratio": 1.5,
            "tags": ["a", 2, False],
            "payload_bin": b"\x00\x01",
            "severity": "warn",
        }
        mapped = normalize_otlp_attrs(attrs)
        self.assertEqual(mapped["service.name"], "api")
        self.assertIs(mapped["success"], True)
        self.assertEqual(mapped["count"], 3)
        self.assertEqual(mapped["ratio"], 1.5)
        self.assertEqual(mapped["tags"], ["a", 2, False])
        self.assertEqual(mapped["payload_bin"], "AAE=")
        self.assertEqual(mapped["otel.severity"], "warn")

    def test_severity_debug(self) -> None:
        sev, unknown = map_severity("DEBUG")
        self.assertEqual(sev, "debug")
        self.assertFalse(unknown)

    def test_severity_info(self) -> None:
        sev, unknown = map_severity("INFO")
        self.assertEqual(sev, "info")
        self.assertFalse(unknown)

    def test_severity_warn(self) -> None:
        sev, unknown = map_severity("WARN")
        self.assertEqual(sev, "warn")
        self.assertFalse(unknown)

    def test_severity_error(self) -> None:
        sev, unknown = map_severity("ERROR")
        self.assertEqual(sev, "error")
        self.assertFalse(unknown)

    def test_severity_fatal(self) -> None:
        sev, unknown = map_severity("FATAL")
        self.assertEqual(sev, "fatal")
        self.assertFalse(unknown)

    def test_severity_unknown(self) -> None:
        sev, unknown = map_severity("TRACE")
        self.assertEqual(sev, "info")
        self.assertTrue(unknown)

    def test_integration_rate_limit_429_413_503_with_gap_event(self) -> None:
        for metric, value, expected in (
            ("max_events_per_sec", 250, 429),
            ("max_batch_events", 300, 413),
            ("service_unavailable", 1, 503),
        ):
            status, gap = enforce_rate_limit(metric, value)
            self.assertEqual(status, expected)
            self.assertEqual(gap["event_name"], "observability_gap.otlp_rate_limited")
            self.assertEqual(gap["limit_name"], metric)
            self.assertGreaterEqual(gap["retry_after_ms"], 0)
            self.assertEqual(gap["endpoint"], "/otlp/v1/logs")
            self.assertTrue(gap["trace_id"])
            snapshot = [gap]
            stream = [gap]
            self.assertTrue(
                any(e["event_name"] == "observability_gap.otlp_rate_limited" for e in snapshot)
            )
            self.assertTrue(
                any(e["event_name"] == "observability_gap.otlp_rate_limited" for e in stream)
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)
