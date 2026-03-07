#!/usr/bin/env python3
import datetime as dt
import json
import sys
from pathlib import Path


def load_json(path: str):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def load_accepts(path: str):
    text = Path(path).read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        return yaml.safe_load(text)
    except Exception:
        return json.loads(text)


def normalize_accepts(data):
    accepts = {}
    for entry in data.get("entries", []):
        key = (
            entry.get("id", ""),
            entry.get("package", ""),
            Path(entry.get("path", "")).name,
        )
        accepts[key] = entry
    return accepts


def parse_expiry(value):
    if isinstance(value, dt.datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=dt.timezone.utc)
        return value
    if isinstance(value, dt.date):
        return dt.datetime(value.year, value.month, value.day, tzinfo=dt.timezone.utc)
    if isinstance(value, str):
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    raise TypeError(f"unsupported expires_utc type: {type(value)!r}")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: evaluate_osv_report.py <osv-report.json> <osv_risk_accept.yaml>")
        return 2

    report = load_json(sys.argv[1])
    accept = load_accepts(sys.argv[2])
    accepts = normalize_accepts(accept)
    today = dt.datetime.now(dt.timezone.utc)
    blocking = []

    for item in report.get("results", []):
        source_path = Path(item.get("source", {}).get("path", "")).name
        for pkg in item.get("packages", []):
            pkg_name = pkg.get("package", {}).get("name", "")
            for vuln in pkg.get("vulnerabilities", []):
                vuln_id = vuln.get("id", "")
                severities = vuln.get("severity") or []
                severe = False
                medium_or_low = False
                for sev in severities:
                    score = (sev.get("score") or "").upper()
                    if "CRITICAL" in score or "HIGH" in score:
                        severe = True
                        break
                    if "MEDIUM" in score or "LOW" in score:
                        medium_or_low = True
                key = (vuln_id, pkg_name, source_path)
                entry = accepts.get(key)
                if severe and entry is None:
                    blocking.append(f"{vuln_id} {pkg_name} {source_path}: high/critical without accept")
                    continue
                if medium_or_low and entry is None:
                    blocking.append(f"{vuln_id} {pkg_name} {source_path}: medium/low without accept")
                    continue
                if not severe and not medium_or_low and entry is None:
                    continue
                if entry is None:
                    blocking.append(f"{vuln_id} {pkg_name} {source_path}: missing risk-accept entry")
                    continue
                expires = entry.get("expires_utc")
                if not expires:
                    blocking.append(f"{vuln_id} {pkg_name} {source_path}: risk-accept missing expires_utc")
                    continue
                expiry = parse_expiry(expires)
                if expiry <= today:
                    blocking.append(f"{vuln_id} {pkg_name} {source_path}: risk-accept expired")

    if blocking:
        print("sca policy violations:")
        for line in blocking:
            print(f"- {line}")
        return 1

    print("sca policy gate: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
