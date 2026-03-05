#!/usr/bin/env python3
"""Linux-only panel0 readiness helper.

Reverse proxy in front of art-core with controllable /console and /api/v1/ingest behavior.
"""

from __future__ import annotations

import argparse
import http.client
import json
import socket
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class ProxyState:
    def __init__(self) -> None:
        self.console_mode = "up"
        self.ingest_mode = "pass"

    def as_dict(self) -> dict[str, str]:
        return {
            "console_mode": self.console_mode,
            "ingest_mode": self.ingest_mode,
        }


def parse_host_port(raw: str) -> tuple[str, int]:
    host, sep, port_raw = raw.partition(":")
    if not sep:
        raise ValueError("upstream must be host:port")
    return host, int(port_raw)


class Panel0ProxyHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    @property
    def state(self) -> ProxyState:
        return self.server.state  # type: ignore[attr-defined]

    @property
    def upstream_host(self) -> str:
        return self.server.upstream_host  # type: ignore[attr-defined]

    @property
    def upstream_port(self) -> int:
        return self.server.upstream_port  # type: ignore[attr-defined]

    def log_message(self, fmt: str, *args: object) -> None:
        message = fmt % args
        print(f"[{self.log_date_time_string()}] {self.address_string()} {message}")

    def do_GET(self) -> None:  # noqa: N802
        self._handle_request()

    def do_POST(self) -> None:  # noqa: N802
        self._handle_request()

    def do_PUT(self) -> None:  # noqa: N802
        self._handle_request()

    def do_DELETE(self) -> None:  # noqa: N802
        self._handle_request()

    def _read_body(self) -> bytes:
        size = int(self.headers.get("content-length", "0"))
        if size <= 0:
            return b""
        return self.rfile.read(size)

    def _send_json(self, status: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload, ensure_ascii=True).encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", "application/json; charset=utf-8")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, status: int, text: str, content_type: str) -> None:
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("content-type", content_type)
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _update_modes(self, body: bytes) -> None:
        if not body:
            return
        payload = json.loads(body.decode("utf-8"))
        if not isinstance(payload, dict):
            return

        console_mode = payload.get("console_mode")
        if isinstance(console_mode, str):
            if console_mode not in {"up", "http_error", "slow_timeout", "runtime_crash", "network_error"}:
                raise ValueError(f"invalid console_mode={console_mode}")
            self.state.console_mode = console_mode

        ingest_mode = payload.get("ingest_mode")
        if isinstance(ingest_mode, str):
            if ingest_mode not in {"pass", "down"}:
                raise ValueError(f"invalid ingest_mode={ingest_mode}")
            self.state.ingest_mode = ingest_mode

    def _handle_control(self) -> bool:
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == "/__panel0_status":
            self._send_json(200, self.state.as_dict())
            return True
        if parsed.path == "/__panel0_control" and self.command == "POST":
            try:
                self._update_modes(self._read_body())
            except Exception as error:  # noqa: BLE001
                self._send_json(400, {"ok": False, "error": str(error)})
                return True
            self._send_json(200, {"ok": True, **self.state.as_dict()})
            return True
        return False

    def _handle_console(self) -> bool:
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path != "/console":
            return False

        mode = self.state.console_mode
        if mode == "up":
            self._send_text(
                200,
                "<!doctype html><html><head><meta charset='utf-8'><title>Mock Console</title></head><body><h1>Mock Console</h1><p>console.up</p></body></html>",
                "text/html; charset=utf-8",
            )
            return True

        if mode == "http_error":
            self._send_json(503, {"error": "mock_console_http_error"})
            return True

        if mode == "slow_timeout":
            time.sleep(7)
            self._send_text(
                200,
                "<!doctype html><html><head><meta charset='utf-8'><title>Mock Console Slow</title></head><body><h1>Mock Console Slow</h1></body></html>",
                "text/html; charset=utf-8",
            )
            return True

        if mode == "runtime_crash":
            self._send_text(
                200,
                "<!doctype html><html><head><meta charset='utf-8'><title>Mock Console Crash</title></head><body><script>throw new Error('mock console runtime crash');</script></body></html>",
                "text/html; charset=utf-8",
            )
            return True

        if mode == "network_error":
            try:
                self.connection.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            self.connection.close()
            return True

        self._send_json(500, {"error": f"unsupported_mode_{mode}"})
        return True

    def _handle_ingest_block(self) -> bool:
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == "/api/v1/ingest" and self.state.ingest_mode == "down":
            self._send_json(503, {"error": "mock_ingest_down"})
            return True
        return False

    def _proxy_to_core(self) -> None:
        body = self._read_body()
        headers = {}
        for key, value in self.headers.items():
            lower = key.lower()
            if lower in HOP_HEADERS:
                continue
            if lower == "host":
                continue
            headers[key] = value
        headers["Host"] = f"{self.upstream_host}:{self.upstream_port}"

        try:
            conn = http.client.HTTPConnection(self.upstream_host, self.upstream_port, timeout=15)
            conn.request(self.command, self.path, body=body, headers=headers)
            response = conn.getresponse()
            payload = response.read()
            self.send_response(response.status, response.reason)
            for key, value in response.getheaders():
                lower = key.lower()
                if lower in HOP_HEADERS:
                    continue
                if lower == "content-length":
                    continue
                self.send_header(key, value)
            self.send_header("content-length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except Exception as error:  # noqa: BLE001
            self._send_json(502, {"error": "upstream_unreachable", "detail": str(error)})
        finally:
            try:
                conn.close()
            except Exception:  # noqa: BLE001
                pass

    def _handle_request(self) -> None:
        if self._handle_control():
            return
        if self._handle_console():
            return
        if self._handle_ingest_block():
            return
        self._proxy_to_core()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--listen", default="127.0.0.1:39220")
    parser.add_argument("--upstream", default="127.0.0.1:39210")
    args = parser.parse_args()

    listen_host, listen_port = parse_host_port(args.listen)
    upstream_host, upstream_port = parse_host_port(args.upstream)

    server = ThreadingHTTPServer((listen_host, listen_port), Panel0ProxyHandler)
    server.state = ProxyState()  # type: ignore[attr-defined]
    server.upstream_host = upstream_host  # type: ignore[attr-defined]
    server.upstream_port = upstream_port  # type: ignore[attr-defined]

    print(
        f"panel0-mock-proxy listen={listen_host}:{listen_port} upstream={upstream_host}:{upstream_port}",
        flush=True,
    )
    try:
        server.serve_forever(poll_interval=0.2)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
